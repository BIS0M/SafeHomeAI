from datetime import datetime, timezone, timedelta
from typing import Optional, List

import httpx
import uuid
import os
import json

from fastapi import (
    APIRouter,
    Depends,
    UploadFile,
    File,
    Form,
    HTTPException,
    status,
    Query as FastAPIQuery,  # ✅ FastAPI Query 별칭
)
from fastapi.responses import StreamingResponse
from fastapi.security import OAuth2PasswordBearer

from pydantic import BaseModel

from google.cloud.firestore_v1 import Query as FirestoreQuery  # ✅ Firestore Query 별칭
from google.cloud import storage  # (현재 파일에서 직접 쓰지 않아도, 기존 구성 유지)

from app.services import ai_service, storage_service
from app.db import firestore
from app.core.config import settings
from app.core import security

router = APIRouter()

# =========================================================
# 🔐 OAuth2 / 현재 로그인 유저 확인
# =========================================================
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")


async def get_current_user_email(token: str = Depends(oauth2_scheme)):
    """토큰을 검증하고 현재 유저의 이메일(sub)을 반환"""
    payload = security.decode_access_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="인증에 실패했습니다.",
        )
    return payload.get("sub")


# =========================================================
# 🖼️ 이미지 프록시 (Flutter Web CORS 우회)
# =========================================================
@router.get("/image_proxy")
async def image_proxy(url: str = FastAPIQuery(...)):
    """
    Flutter Web의 CORS 문제 해결용 이미지 프록시
    - 서버가 GCS URL을 대신 가져와서 클라이언트에 스트리밍
    """

    async def stream_image():
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(url, follow_redirects=True)
                if response.status_code == 200:
                    yield response.content
                else:
                    print(f"이미지 프록시 실패: {response.status_code} URL: {url}")
            except Exception as e:
                print(f"이미지 프록시 중 에러 발생: {e}")

    return StreamingResponse(stream_image(), media_type="image/jpeg")


# =========================================================
# 📌 분석 API
# =========================================================
@router.post("/analyze", status_code=status.HTTP_200_OK)
async def analyze_safety(
    user_id: str = Form(...),
    space_type: str = Form(...),
    child_id: Optional[str] = Form(None),  # ✅ 아이 프로필 연동용
    growth_stage: str = Form("walking"),
    file: UploadFile = File(...),
    current_user: str = Depends(get_current_user_email),
):
    # ✅ 본인 계정 확인
    if user_id != current_user:
        raise HTTPException(status_code=403, detail="권한이 없습니다.")

    # ------------------------------------------------------------------
    # ✅ DB 연동 및 범용(universal) 처리 로직 (기존 기능 유지)
    # ------------------------------------------------------------------
    actual_growth_stage = "universal"

    if child_id:
        child_data = firestore.get_child_profile(child_id)
        if child_data:
            db_stage = child_data.get("growth_stage")
            if db_stage:
                actual_growth_stage = db_stage
            else:
                print("DEBUG: 아이 프로필은 있으나 성장 단계 정보 없음.")
        else:
            print(f"DEBUG: ID({child_id}) 프로필 찾을 수 없음. 범용 전환.")
    else:
        actual_growth_stage = "universal"

    try:
        image_bytes = await file.read()

        final_hazards, _ = await ai_service.run_full_safety_analysis(
            image_bytes, growth_stage, space_type
        )

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        origin_name = f"uploads/{user_id}/{timestamp}_origin.jpg"

        blob_path = storage_service.upload_to_gcs(
            image_bytes, settings.GCS_BUCKET_NAME, origin_name
        )

        public_image_url = (
            f"https://storage.googleapis.com/{settings.GCS_BUCKET_NAME}/{blob_path}"
        )

        report_id = firestore.save_report(
            user_id=user_id,
            image_url=blob_path,
            hazards=final_hazards,
            space_type=space_type,
            growth_stage=actual_growth_stage,
            child_id=child_id,
        )

        return {
            "status": "success",
            "report_id": report_id,
            "image_url": public_image_url,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "hazards_count": len(final_hazards),
            "detected_hazards": final_hazards,
            "applied_growth_stage": actual_growth_stage,  # 프론트 확인용
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# =========================================================
# 📌 히스토리 조회
# =========================================================
@router.get("/history/{user_id}", status_code=status.HTTP_200_OK)
async def get_history(
    user_id: str,
    current_user: str = Depends(get_current_user_email),
):
    # ✅ 타인의 기록 접근 차단
    if user_id != current_user:
        raise HTTPException(status_code=403, detail="타인의 기록에 접근할 수 없습니다.")

    try:
        docs = (
            firestore.db.collection("reports")
            .where("user_id", "==", user_id)
            .order_by("created_at", direction=FirestoreQuery.DESCENDING)
            .stream()
        )

        history_list = []
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id

            if "created_at" in data and data["created_at"]:
                data["created_at"] = data["created_at"].isoformat()

            blob_path = data.get("image_url")
            data["image_url"] = (
                f"https://storage.googleapis.com/{settings.GCS_BUCKET_NAME}/{blob_path}"
                if blob_path
                else f"https://storage.googleapis.com/{settings.GCS_BUCKET_NAME}/error.jpg"
            )

            history_list.append(data)

        return {"status": "success", "count": len(history_list), "data": history_list}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"히스토리 조회 오류: {str(e)}")


# =========================================================
# 📌 공유된 리포트 상세 조회
# =========================================================
@router.get("/history/shared/{report_id}", status_code=status.HTTP_200_OK)
async def get_shared_report(
    report_id: str,
    current_user: str = Depends(get_current_user_email),
):
    report = firestore.get_report_by_id(report_id)

    if not report:
        raise HTTPException(status_code=404, detail="기록을 찾을 수 없습니다.")

    if "created_at" in report and report["created_at"]:
        report["created_at"] = report["created_at"].isoformat()

    blob_path = report.get("image_url")
    if blob_path:
        report["image_url"] = (
            f"https://storage.googleapis.com/{settings.GCS_BUCKET_NAME}/{blob_path}"
        )

    return {"data": report}


# =========================================================
# ⭐ 해결 체크 업데이트 (solved_hazard_keys)
# =========================================================
class SolvedKeysRequest(BaseModel):
    solved_hazard_keys: list[str]


@router.patch("/history/{report_id}/solved-keys", status_code=status.HTTP_200_OK)
async def update_solved_keys(
    report_id: str,
    req: SolvedKeysRequest,
    current_user: str = Depends(get_current_user_email),
):
    ok = firestore.update_report_solved_hazard_keys(
        report_id=report_id,
        user_id=current_user,
        solved_keys=req.solved_hazard_keys,
    )
    if not ok:
        raise HTTPException(status_code=404, detail="기록을 찾을 수 없거나 권한이 없습니다.")
    return {"status": "success"}


# =========================================================
# 🗑️ 히스토리 삭제
# =========================================================
@router.delete("/history/{report_id}")
async def delete_history(
    report_id: str,
    current_user: str = Depends(get_current_user_email),
):
    success = firestore.delete_report(report_id)
    if not success:
        raise HTTPException(status_code=404, detail="기록을 찾을 수 없습니다.")
    return {"status": "success", "message": "삭제되었습니다."}


@router.delete("/history/all/{user_id}")
async def clear_all_history(
    user_id: str,
    current_user: str = Depends(get_current_user_email),
):
    if user_id != current_user:
        raise HTTPException(status_code=403, detail="권한이 없습니다.")

    success = firestore.delete_all_user_reports(user_id)
    return {"status": "success", "message": "모든 기록이 삭제되었습니다."}


# =========================================================
# 👶 아이 프로필 관리
# =========================================================
class ChildProfileRequest(BaseModel):
    child_name: str
    birthday: str
    growth_stage: str


@router.post("/childs", status_code=status.HTTP_201_CREATED)
async def add_child_profile(
    req: ChildProfileRequest,
    current_user: str = Depends(get_current_user_email),
):
    try:
        profile_id = firestore.create_child_profile(
            user_id=current_user,
            child_name=req.child_name,
            birthday=req.birthday,
            growth_stage=req.growth_stage,
        )

        return {
            "status": "success",
            "message": "아이 프로필이 저장되었습니다.",
            "profile_id": profile_id,
            "user_id": current_user,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"저장 실패: {str(e)}")


@router.get("/childs", status_code=status.HTTP_200_OK)
async def get_child_profiles(current_user: str = Depends(get_current_user_email)):
    profiles = firestore.get_child_profiles(current_user)
    return {"status": "success", "count": len(profiles), "data": profiles}


@router.delete("/childs/{profile_id}")
async def delete_child_profile(
    profile_id: str,
    current_user: str = Depends(get_current_user_email),
):
    success = firestore.delete_child_profile(profile_id)

    if not success:
        raise HTTPException(status_code=404, detail="프로필을 삭제하지 못했습니다.")

    return {"status": "success", "message": "삭제되었습니다."}


# =========================================================
# 🧑‍🤝‍🧑 커뮤니티 API (게시글/좋아요/삭제)
# =========================================================
@router.get("/community/posts", status_code=status.HTTP_200_OK)
async def get_posts(current_user: str = Depends(get_current_user_email)):
    posts = firestore.get_community_posts()

    for post in posts:
        if "created_at" in post and post["created_at"]:
            post["created_at"] = post["created_at"].isoformat()

        raw_paths = post.get("image_urls", [])
        valid_urls = []
        for blob_path in raw_paths:
            full_url = f"https://storage.googleapis.com/{settings.GCS_BUCKET_NAME}/{blob_path}"
            valid_urls.append(full_url)
        post["image_urls"] = valid_urls

        if "comment_count" not in post:
            post["comment_count"] = 0

    return {"status": "success", "data": posts}


@router.post("/community/posts", status_code=status.HTTP_201_CREATED)
async def create_post(
    title: str = Form(...),
    content: str = Form(...),
    files: List[UploadFile] = File(None),
    linked_analysis_id: Optional[str] = Form(None),
    linked_analysis_title: Optional[str] = Form(None),
    linked_analysis_image: Optional[str] = Form(None),
    analysis_snapshot: Optional[str] = Form(None),
    current_user: str = Depends(get_current_user_email),
):
    user_info = firestore.get_user_by_email(current_user)
    user_name = "익명"
    if user_info and "user_name" in user_info:
        user_name = user_info["user_name"]
    elif user_info:
        user_name = current_user.split("@")[0]

    uploaded_image_paths = []
    if files:
        for file in files:
            file_bytes = await file.read()
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"community/{current_user}/{timestamp}_{file.filename}"

            blob_path = storage_service.upload_to_gcs(
                file_bytes, settings.GCS_BUCKET_NAME, filename
            )
            uploaded_image_paths.append(blob_path)

    snapshot_data = None
    if analysis_snapshot:
        snapshot_data = json.loads(analysis_snapshot)

    linked_data = None
    if linked_analysis_id:
        linked_data = {
            "id": linked_analysis_id,
            "title": linked_analysis_title,
            "image": linked_analysis_image,
        }

    post_id = firestore.create_community_post(
        user_id=current_user,
        user_name=user_name,
        title=title,
        content=content,
        image_urls=uploaded_image_paths,
        linked_analysis=linked_data,
        analysis_snapshot=snapshot_data,
    )

    return {"status": "success", "post_id": post_id}


@router.post("/community/posts/{post_id}/like")
async def like_post(
    post_id: str,
    current_user: str = Depends(get_current_user_email),
):
    result = firestore.toggle_post_like(post_id, current_user)
    return {"status": "success", "liked": result}


@router.delete("/community/posts/{post_id}")
async def delete_post(
    post_id: str,
    current_user_email: str = Depends(get_current_user_email),
):
    success = firestore.delete_community_post(post_id, current_user_email)

    if not success:
        raise HTTPException(
            status_code=400,
            detail="게시글을 삭제할 수 없습니다. (존재하지 않거나 권한이 없습니다.)",
        )

    return {"status": "success", "message": "게시글이 삭제되었습니다."}



# 커뮤니티 섹션 - 오늘의 인기글
@router.get("/community/daily-best", status_code=status.HTTP_200_OK)
async def get_daily_best(
    current_user: str = Depends(get_current_user_email)
):
    # 1. firestore 함수 호출
    posts = firestore.get_daily_best_posts(limit=5)

    # 2. 데이터 가공 (날짜, 이미지 URL 변환)
    for post in posts:
        # 날짜 변환
        if "created_at" in post and post["created_at"]:
            post["created_at"] = post["created_at"].isoformat()
        
        # 이미지 URL 프록시 처리
        raw_paths = post.get("image_urls", [])
        valid_urls = []
        for blob_path in raw_paths:
            full_url = f"https://storage.googleapis.com/{settings.GCS_BUCKET_NAME}/{blob_path}"
            valid_urls.append(full_url)
        post["image_urls"] = valid_urls

        # 댓글 수 처리
        if "comment_count" not in post:
            post["comment_count"] = 0

    return {"status": "success", "data": posts}



# =========================================================
# 💬 댓글 API
# =========================================================
@router.get("/community/posts/{post_id}/comments")
async def get_post_comments(
    post_id: str,
    current_user: str = Depends(get_current_user_email),
):
    comments = firestore.get_comments(post_id)

    for c in comments:
        if "created_at" in c and c["created_at"]:
            c["created_at"] = c["created_at"].isoformat()

        if "user_name" in c and "author_name" not in c:
            c["author_name"] = c["user_name"]

    return {"status": "success", "data": comments}


@router.post("/community/posts/{post_id}/comments")
async def create_comment(
    post_id: str,
    content: str = Form(...),
    current_user: str = Depends(get_current_user_email),
):
    user_info = firestore.get_user_by_email(current_user)
    user_name = user_info.get("user_name", "익명") if user_info else "익명"

    comment_id = firestore.add_comment(post_id, current_user, user_name, content)

    if not comment_id:
        raise HTTPException(status_code=500, detail="댓글 저장 실패")

    return {"status": "success", "comment_id": comment_id}


# =========================================================
# 🔐 인증 API (회원가입/로그인/게스트)
# =========================================================
class RegisterRequest(BaseModel):
    email: str
    password: str
    user_name: str


class LoginRequest(BaseModel):
    email: str
    password: str


@router.post("/auth/register", status_code=status.HTTP_201_CREATED)
async def register(req: RegisterRequest):
    print(f"🚀 [SERVER] 가입 요청 수신: {req.dict()}")
    email = req.email.strip().lower()

    if "@" not in email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"status": "error", "message": "이메일 형식을 확인해주세요."},
        )

    if len(req.password) < 4:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"status": "error", "message": "비밀번호는 4자리 이상이어야 합니다."},
        )

    password_hash = security.hash_password(req.password)

    created = firestore.create_user(
        email=email,
        password_hash=password_hash,
        user_name=req.user_name,
    )

    if created is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"status": "error", "message": "이미 가입된 이메일입니다."},
        )

    token = security.create_access_token(subject=email)

    return {
        "status": "success",
        "email": created,
        "user_name": req.user_name,
        "access_token": token,
        "token_type": "bearer",
    }


@router.post("/auth/login", status_code=status.HTTP_200_OK)
async def login(req: LoginRequest):
    email = req.email.strip().lower()

    if "@" not in email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"status": "error", "message": "이메일 형식을 확인해주세요."},
        )

    user = firestore.get_user_by_email(email)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"status": "error", "message": "이메일 또는 비밀번호가 올바르지 않습니다."},
        )

    if not security.verify_password(req.password, user.get("password_hash", "")):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"status": "error", "message": "이메일 또는 비밀번호가 올바르지 않습니다."},
        )

    token = security.create_access_token(subject=email)

    return {
        "status": "success",
        "email": email,
        "user_name": user.get("user_name"),
        "access_token": token,
        "token_type": "bearer",
    }


@router.post("/auth/guest-login")
async def guest_login():
    """
    중복 없는 게스트 계정 생성 및 토큰 발급
    """
    try:
        guest_uuid = str(uuid.uuid4())[:8]
        guest_email = f"guest_{guest_uuid}@safehome.ai"

        random_pw = str(uuid.uuid4())
        hashed_pw = security.hash_password(random_pw)

        firestore.create_guest_user(guest_email, hashed_pw)

        token = security.create_access_token(subject=guest_email)

        return {
            "status": "success",
            "access_token": token,
            "token_type": "bearer",
            "email": guest_email,
            "is_guest": True,
            "user_name": "체험 유저",
            "message": "게스트 로그인 성공",
        }
    except Exception as e:
        print(f"DEBUG: 게스트 로그인 실패: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Guest login failed",
        )


@router.post("/admin/cleanup-guests")
async def cleanup_guests():
    """
    24시간 지난 게스트 계정과 데이터를 삭제 (관리자/스케줄러 호출용)
    """
    try:
        count = firestore.cleanup_expired_guests()
        return {"status": "success", "deleted_count": count}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Cleanup failed: {str(e)}",
        )


# =========================================================
# ✅ (기존 구현 유지) resolved_ids 업데이트 API
# =========================================================
class ResolveHazardsRequest(BaseModel):
    report_id: str
    resolved_ids: List[str]


@router.post("/reports/resolve")
async def update_resolved_hazards(
    req: ResolveHazardsRequest,
    current_user: str = Depends(get_current_user_email),
):
    success = firestore.update_resolved_hazards(
        report_id=req.report_id,
        resolved_ids=req.resolved_ids,
    )

    if not success:
        raise HTTPException(status_code=404, detail="리포트 업데이트 실패")

    return {"status": "success"}


# =========================================================
# ⚠️ (기존 구현 유지) solved 업데이트 API (현재 구조 그대로)
# =========================================================
@router.patch("/reports/{report_id}/solved")
def update_solved(report_id: str, data: dict):
    """
    solved_hazard_keys 업데이트 endpoint
    """
    solved_keys = data.get("solved_keys", [])

    success = firestore.update_solved_hazards(report_id, solved_keys)

    if not success:
        raise HTTPException(status_code=404, detail="Report not found")

    return {"success": True}
