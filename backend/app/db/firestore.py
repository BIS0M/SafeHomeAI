from google.cloud import firestore
from datetime import datetime, timedelta, timezone
from app.core.config import settings

# 중앙 설정(config.py)에 정의된 경로로 Firestore 클라이언트 초기화
# db = firestore.Client.from_service_account_json(settings.GCP_KEY_PATH)
db = firestore.Client()

# -------------------------------------------------
# 🔥 REPORT 저장
# -------------------------------------------------
def save_report(user_id, image_url, hazards, space_type, growth_stage=None, child_id=None):
    doc_ref = db.collection("reports").document()
    report_id = f"report_{datetime.now().strftime('%Y%m%d')}_{doc_ref.id[:4]}"

    report_data = {
        "report_id": report_id,
        "user_id": user_id,
        "image_url": image_url,
        "space_type": space_type,
        "growth_stage": growth_stage,
        "child_id": child_id,
        "solved_hazard_keys": [],

        # 분석 원본 (절대 변경 X)
        "detected_hazards": hazards,
        "hazards_count": len(hazards),

        # 사용자 체크 상태 저장
        "resolved_hazards_ids": [],

        "created_at": firestore.SERVER_TIMESTAMP
    }

    doc_ref.set(report_data)
    return report_id


def get_user_reports(user_id: str):
    """
    특정 사용자의 리포트 목록을 최신순으로 가져옵니다.
    *주의: where와 order_by를 같이 쓰려면 Firestore 콘솔에서 색인(Index) 생성이 필요할 수 있습니다.
    """
    try:
        reports_ref = db.collection("reports")
        query = reports_ref.where("user_id", "==", user_id).order_by(
            "created_at", direction=firestore.Query.DESCENDING
        )
        return query.stream()
    except Exception as e:
        print(f"Firestore 조회 오류: {e}")
        return []


# ---------------------------------------------------------------------
# ⭐ 해결 체크 상태 업데이트
# ---------------------------------------------------------------------
def update_solved_hazards(report_id: str, solved_keys: list):
    """
    특정 report의 solved_hazard_keys 업데이트
    """
    try:
        docs = db.collection("reports").where("report_id", "==", report_id).stream()

        updated = False
        for doc in docs:
            doc.reference.update({
                "solved_hazard_keys": solved_keys
            })
            updated = True

        return updated
    except Exception as e:
        print(f"DEBUG: solved_hazard_keys 업데이트 실패: {e}")
        return False


# -------------------------------------------------
# 리포트 단건 조회
# -------------------------------------------------
def get_report_by_id(report_id: str):
    docs = db.collection("reports").where("report_id", "==", report_id).limit(1).stream()
    for doc in docs:
        return doc.to_dict()
    return None


# -----------------------------------------------------------------------------
# 아이프로필 관련
# -----------------------------------------------------------------------------
def create_child_profile(user_id: str, child_name: str, birthday: str, growth_stage: str):
    """
    아이의 프로필 정보를 저장합니다.
    birthday는 '2026-01-23' 같은 문자열 형태로 받습니다.
    """
    doc_ref = db.collection("childs").document()

    profile_data = {
        "profile_id": doc_ref.id,
        "user_id": user_id,
        "child_name": child_name,
        "birthday": birthday,  # ✅ 생일 필드 추가
        "growth_stage": growth_stage,
        "created_at": firestore.SERVER_TIMESTAMP
    }

    try:
        doc_ref.set(profile_data)
        print(f"DEBUG: 아이 프로필 저장 성공! ID: {doc_ref.id}")
        return doc_ref.id
    except Exception as e:
        print(f"DEBUG: 프로필 저장 중 에러 발생: {e}")
        raise e


def get_child_profiles(user_id: str):
    """특정 유저의 모든 아이 프로필을 'childs' 컬렉션에서 가져옵니다."""
    try:
        docs = db.collection("childs").where("user_id", "==", user_id).stream()

        results = []
        for doc in docs:
            data = doc.to_dict()
            if "id" not in data:
                data["id"] = doc.id
            results.append(data)
        return results
    except Exception as e:
        print(f"DEBUG: 프로필 조회 오류: {e}")
        return []


def delete_child_profile(profile_id: str):
    """아이 프로필 및 모든 연관 리포트(reports) 완전 삭제"""
    try:
        batch = db.batch()
        batch.delete(db.collection("childs").document(profile_id))

        reports = db.collection("reports").where("child_id", "==", profile_id).stream()
        for report in reports:
            batch.delete(report.reference)

        batch.commit()
        return True
    except Exception as e:
        print(f"삭제 실패: {e}")
        return False


def get_child_profile(profile_id: str):
    """
    특정 아이 프로필(ID)의 상세 정보를 조회합니다.
    분석 시 성장 단계를 DB에서 직접 가져오기 위해 사용합니다.
    """
    try:
        doc_ref = db.collection("childs").document(profile_id)
        doc = doc_ref.get()
        if doc.exists:
            return doc.to_dict()
        return None
    except Exception as e:
        print(f"DEBUG: 아이 프로필 단건 조회 실패: {e}")
        return None


# -----------------------------------------------------------------------------
# 리포트 삭제 / 전체 삭제
# -----------------------------------------------------------------------------
def delete_report(report_id: str):
    """
    Firestore의 'reports' 컬렉션에서 특정 report_id를 가진 문서를 삭제합니다.
    """
    try:
        docs = db.collection("reports").where("report_id", "==", report_id).stream()

        deleted = False
        for doc in docs:
            doc.reference.delete()
            print(f"DEBUG: Firestore 문서 삭제 성공! (ID: {doc.id}, report_id: {report_id})")
            deleted = True

        if not deleted:
            print(f"DEBUG: 삭제할 문서를 찾지 못했습니다. (report_id: {report_id})")

        return deleted

    except Exception as e:
        print(f"DEBUG: Firestore 삭제 중 에러 발생: {e}")
        return False


def update_report_solved_hazard_keys(report_id: str, user_id: str, solved_keys: list) -> bool:
    try:
        docs = (
            db.collection("reports")
            .where("report_id", "==", report_id)
            .where("user_id", "==", user_id)
            .limit(1)
            .stream()
        )

        for doc in docs:
            doc.reference.update({"solved_hazard_keys": solved_keys})
            return True

        return False
    except Exception as e:
        print(f"DEBUG: solved_hazard_keys 업데이트 실패: {e}")
        return False


def delete_all_user_reports(user_id: str):
    try:
        docs = db.collection("reports").where("user_id", "==", user_id).stream()

        deleted_count = 0
        for doc in docs:
            doc.reference.delete()
            deleted_count += 1

        print(f"DEBUG: {user_id}의 모든 기록({deleted_count}개) 삭제 성공")
        return True
    except Exception as e:
        print(f"DEBUG: 전체 삭제 중 에러: {e}")
        return False


# -----------------------------------------------------------------------------
# ✅ [추가 반영] 시현님이 준 “간단 버전” 동작을 그대로 제공하는 래퍼(호환용)
# - 기존 함수 기능은 유지(삭제/변경 없음)
# - 필요한 곳에서 “리스트 형태의 결과”가 필요할 때 이 래퍼를 사용하면 됨
# -----------------------------------------------------------------------------

# =========================================================
# 📌 사용자 히스토리 조회 (리스트 반환 래퍼)
# =========================================================
def get_user_reports_list(user_id: str):
    """
    get_user_reports()가 stream(반복자)을 반환하는 기존 동작을 유지하면서,
    '간단 버전'처럼 list[dict] 형태가 필요할 때 사용할 수 있는 추가 함수입니다.
    """
    docs = get_user_reports(user_id)

    results = []
    try:
        for doc in docs:
            # stream일 때
            if hasattr(doc, "to_dict"):
                data = doc.to_dict()
                data["id"] = doc.id
                results.append(data)
            else:
                # 이미 dict 리스트로 들어오는 경우를 대비(방어)
                results.append(doc)
    except Exception as e:
        print(f"DEBUG: get_user_reports_list 변환 실패: {e}")
        return []

    return results


# =========================================================
# 📌 삭제 (단순 True 반환 형태 래퍼)
# =========================================================
def delete_report_always_true(report_id: str):
    """
    '간단 버전'처럼 항상 True를 반환하는 동작이 필요할 때 쓰는 래퍼입니다.
    (기존 delete_report는 성공/실패를 bool로 반환하는 동작 유지)
    """
    delete_report(report_id)
    return True


def delete_all_user_reports_always_true(user_id: str):
    """
    '간단 버전'처럼 항상 True를 반환하는 동작이 필요할 때 쓰는 래퍼입니다.
    (기존 delete_all_user_reports는 성공/실패를 bool로 반환하는 동작 유지)
    """
    delete_all_user_reports(user_id)
    return True


# -----------------------------------------------------------------------------
# ✅ 인증: users 컬렉션
# -----------------------------------------------------------------------------
def _normalize_email(email: str) -> str:
    """Firestore 문서 ID로 쓰기 위한 이메일 정규화(소문자/공백 제거)."""
    return (email or "").strip().lower()


def get_user_by_email(email: str):
    """이메일로 users 컬렉션에서 계정 정보를 조회합니다."""
    normalized = _normalize_email(email)
    if not normalized:
        return None

    doc_ref = db.collection("users").document(normalized)
    doc = doc_ref.get()
    if not doc.exists:
        return None
    return doc.to_dict()


def create_user(email: str, password_hash: str, user_name: str = "사용자"):
    """
    users 컬렉션에 새 계정을 생성합니다.
    user_name 매개변수를 추가하여 이름도 함께 저장합니다.
    """
    normalized = _normalize_email(email)
    if not normalized:
        raise ValueError("email is empty")

    doc_ref = db.collection("users").document(normalized)

    if doc_ref.get().exists:
        return None

    user_data = {
        "user_name": user_name,
        "email": normalized,
        "password_hash": password_hash,
        "created_at": firestore.SERVER_TIMESTAMP,
    }

    doc_ref.set(user_data)
    return normalized


# -----------------------------------------------------------------------------
# ✅ 게스트 로그인 및 자동 삭제 기능
# -----------------------------------------------------------------------------
def create_guest_user(email: str, password_hash: str):
    normalized = _normalize_email(email)
    doc_ref = db.collection("users").document(normalized)

    user_data = {
        "user_name": "체험 유저",
        "email": normalized,
        "password_hash": password_hash,
        "created_at": firestore.SERVER_TIMESTAMP,
        "is_guest": True
    }

    doc_ref.set(user_data)
    return user_data


def cleanup_expired_guests():
    try:
        expiration_time = datetime.now(timezone.utc) - timedelta(hours=24)
        docs = db.collection("users").where("is_guest", "==", True).stream()

        deleted_count = 0
        for doc in docs:
            user_data = doc.to_dict()
            created_at = user_data.get("created_at")

            if created_at and created_at < expiration_time:
                email = doc.id
                print(f"DEBUG: 만료된 게스트 발견 ({email}), 삭제 시작...")
                _delete_user_cascade(email)
                deleted_count += 1

        print(f"DEBUG: 총 {deleted_count}명의 만료된 게스트 계정을 청소했습니다.")
        return deleted_count

    except Exception as e:
        print(f"DEBUG: 게스트 청소 중 오류 발생: {e}")
        return 0


def _delete_user_cascade(email: str):
    try:
        batch = db.batch()

        user_ref = db.collection("users").document(email)
        batch.delete(user_ref)

        childs = db.collection("childs").where("user_id", "==", email).stream()
        for child in childs:
            batch.delete(child.reference)

        reports = db.collection("reports").where("user_id", "==", email).stream()
        for report in reports:
            batch.delete(report.reference)

        batch.commit()
        print(f"DEBUG: 유저 {email} 및 관련 데이터 완전 삭제 완료.")

    except Exception as e:
        print(f"DEBUG: Cascade 삭제 중 오류 발생 ({email}): {e}")


# -----------------------------------------------------------------------------
# 커뮤니티 / 댓글
# -----------------------------------------------------------------------------
def create_community_post(
    user_id: str,
    user_name: str,
    title: str,
    content: str,
    image_urls: list,
    linked_analysis: dict = None,
    analysis_snapshot: dict = None
):
    doc_ref = db.collection("posts").document()

    post_data = {
        "id": doc_ref.id,
        "author_id": user_id,
        "author_name": user_name,
        "title": title,
        "content": content,
        "image_urls": image_urls,
        "created_at": firestore.SERVER_TIMESTAMP,
        "like_count": 0,
        "liked_user_ids": [],
        "comment_count": 0,
        "linked_analysis": linked_analysis,
        "analysis_snapshot": analysis_snapshot
    }

    doc_ref.set(post_data)


def delete_community_post(post_id: str, user_email: str) -> bool:
    try:
        post_ref = db.collection("posts").document(post_id)
        doc = post_ref.get()

        if not doc.exists:
            print(f"DEBUG: 삭제할 문서를 찾지 못했습니다. (ID: {post_id})")
            return False

        post_data = doc.to_dict()

        db_author = post_data.get('author_id')
        print(f"DEBUG: 삭제 검증 - DB작성자: {db_author} vs 요청자: {user_email}")

        if db_author != user_email:
            print("DEBUG: 권한이 없습니다.")
            return False

        post_ref.delete()
        print(f"DEBUG: Firestore 게시글 삭제 성공! (ID: {post_id})")
        return True

    except Exception as e:
        print(f"DEBUG: 삭제 중 서버 에러 발생: {e}")
        return False


def get_community_posts():
    """모든 게시글 조회 (created_at 기준)"""
    try:
        docs = db.collection("posts").order_by(
            "created_at", direction=firestore.Query.DESCENDING
        ).stream()

        results = []
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            results.append(data)

        return results
    except Exception as e:
        print(f"DEBUG: 게시글 조회 실패: {e}")
        return []


def toggle_post_like(post_id: str, user_id: str):
    """좋아요 토글"""
    try:
        doc_ref = db.collection("posts").document(post_id)
        doc = doc_ref.get()
        if not doc.exists:
            return False

        data = doc.to_dict()
        liked_users = data.get("liked_user_ids", [])
        current_count = data.get("like_count", 0)

        if user_id in liked_users:
            liked_users.remove(user_id)
            current_count = max(0, current_count - 1)
        else:
            liked_users.append(user_id)
            current_count += 1

        doc_ref.update({
            "like_count": current_count,
            "liked_user_ids": liked_users
        })
        return True
    except Exception as e:
        return False


def get_daily_best_posts(limit: int = 5):
    try:
        # 1. 현재 시간 (UTC) 구하기
        now = datetime.now(timezone.utc)
        
        # 2. '24시간 전' 시간 구하기
        # (한국 시간 00시 기준보다, 최근 24시간으로 잡는 게 인기글 로직에 더 적합합니다)
        one_day_ago = now - timedelta(hours=24)

        # 3. 최근 24시간 내에 작성된 글만 쿼리
        docs = db.collection("posts")\
            .where("created_at", ">=", one_day_ago)\
            .stream()

        # 4. 리스트로 변환
        posts = []
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            
            # 좋아요 수가 없는 경우 0으로 처리
            if "like_count" not in data:
                data["like_count"] = 0
            
            posts.append(data)

        # 5. 파이썬에서 좋아요(like_count) 내림차순 정렬 
        # (DB 인덱스 없이도 정확하게 정렬됨)
        posts.sort(key=lambda x: x.get("like_count", 0), reverse=True)

        # 6. 상위 N개만 자르기
        # 만약 글이 하나도 없으면 빈 리스트 반환
        return posts[:limit]

    except Exception as e:
        print(f"DEBUG: 인기글 조회 실패: {e}")
        return []
    
    

# -----------------------------------------------------------------------------
# ✅ 댓글 (Comment) 관련 함수
# -----------------------------------------------------------------------------
def add_comment(post_id: str, user_id: str, user_name: str, content: str):
    """게시글에 댓글을 추가하고, 게시글의 comment_count를 1 증가시킵니다."""
    try:
        comment_ref = db.collection("posts").document(post_id).collection("comments").document()

        comment_data = {
            "id": comment_ref.id,
            "post_id": post_id,
            "author_id": user_id,
            "author_name": user_name,
            "content": content,
            "created_at": firestore.SERVER_TIMESTAMP
        }
        comment_ref.set(comment_data)

        post_ref = db.collection("posts").document(post_id)
        post_ref.update({"comment_count": firestore.Increment(1)})

        return comment_ref.id
    except Exception as e:
        print(f"DEBUG: 댓글 작성 실패: {e}")
        return None


def get_comments(post_id: str):
    """특정 게시글의 댓글 목록 조회"""
    try:
        docs = db.collection("posts").document(post_id).collection("comments") \
            .order_by("created_at", direction=firestore.Query.ASCENDING).stream()

        results = []
        for doc in docs:
            data = doc.to_dict()
            results.append(data)
        return results
    except Exception as e:
        return []
