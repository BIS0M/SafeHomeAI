# app/services/ai_service.py

import io
import json
import asyncio
import tempfile
import time  # 🕒 시간 측정을 위해 추가
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

from PIL import Image
from google.cloud import storage
from google import genai

from app.core.config import settings
from app.services.commerce_service import get_safety_product_recommendation



# 모델 저장소 설정
MODEL_BUCKET = "safehome-models"
MODEL_BLOB = "yolo26lb.pt"
MODEL_BLOB = "yolo26lb.pt"

# 경로 설정 (BASE_DIR: app 폴더, DATA_DIR: data 폴더)
BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR.parent / "data"

REPO_MODEL_PATH = BASE_DIR / "models" / MODEL_BLOB
TEMP_MODEL_PATH = Path(tempfile.gettempdir()) / MODEL_BLOB

# RAG 데이터 파일 경로
RISK_MAP_PATH = DATA_DIR / "risk_map.txt"
SAFETY_KNOWLEDGE_PATH = DATA_DIR / "safety_knowledge.txt"

_model = None
_client = None


def _get_active_model_path() -> str:
    """모델 파일 경로를 확인하고 필요시 다운로드합니다."""
    if REPO_MODEL_PATH.exists():
        return str(REPO_MODEL_PATH)
    if TEMP_MODEL_PATH.exists():
        return str(TEMP_MODEL_PATH)

    # 로컬에 없으면 GCS에서 다운로드
    storage_client = storage.Client()
    bucket = storage_client.bucket(MODEL_BUCKET)
    blob = bucket.blob(MODEL_BLOB)
    blob.download_to_filename(str(TEMP_MODEL_PATH))
    return str(TEMP_MODEL_PATH)


def get_model():
    """YOLO 모델을 로드하거나 캐싱된 모델을 반환합니다."""
    global _model
    if _model is None:
        from ultralytics import YOLO
        path = _get_active_model_path()
        _model = YOLO(path)
        print(f"🚀 Model Loaded: {path}")
        print(f"📦 Number of Classes: {len(_model.names)}")
    return _model


def get_gemini_client():
    """Gemini API 클라이언트를 초기화합니다."""
    global _client
    if _client is None:
        _client = genai.Client(api_key=settings.GEMINI_API_KEY)
    return _client


def _norm_name(x: Any) -> str:
    """문자열 정규화 (소문자 변환 및 공백 제거)"""
    return str(x or "").lower().strip()


def _normalize_risk(level: str) -> str:
    """위험 등급 정규화: '위험', '경고' 이외의 값은 '경고'로 처리"""
    level = (level or "").strip()
    if level == "위험":
        return "위험"
    return "경고"


def _read_file_safe(path: Path) -> str:
    """파일을 안전하게 읽어옵니다. 실패 시 빈 문자열 반환."""
    try:
        if path.exists():
            with open(path, "r", encoding="utf-8") as f:
                return f.read()
    except Exception as e:
        print(f"❌ Failed to load {path}: {e}")
    return ""


def _build_prompt(
    growth_stage: str,
    space_type: str,
    risk_rules: str,        # risk_map.txt 내용
    safety_context: str,    # safety_knowledge.txt 내용
    detected_items: str,
) -> str:
    """
    Gemini에게 보낼 프롬프트를 한국어로 생성합니다.
    """
    return f"""
[역할]
당신은 소아 안전 전문가 'SafeHomeAI'입니다.
당신의 목표는 중복 없이 간결하고 명확하며 전문적인 안전 통찰력을 제공하는 것입니다.

[상황 정보]
- 아이 발달 단계: {growth_stage}
- 선택된 공간: {space_type}
- 탐지된 객체들: {detected_items}

[RAG 지식 베이스]
1. **위험 분류 규칙 (핵심 로직):**
{risk_rules}

2. **일반 안전 가이드라인 (추론 근거):**
{safety_context}

[엄격한 제약 사항]
1. **위험 평가 로직 (RAG 우선):**
   - **우선 확인:** '위험 분류 규칙'에서 현재 [아이 발달 단계]에 해당하는 섹션을 찾으십시오.
   - **예외 상황 (단계 미선택):** 만약 발달 단계가 '전체 연령'이거나 명확하지 않다면, **'3. 공통 적용 절대 규칙(Universal Absolute Rules)'**을 기준으로 판단하고, 상식적으로 0~5세 아동에게 위험한 요소를 보수적으로 평가하십시오.
   - **등급 적용:** 규칙에 매칭되는 객체는 정의된 'risk_level'을 **엄격히** 따르십시오.

2. **톤앤매너 (어조 및 스타일):**
   - **전문적이고 정중하게:** 한국어 존댓말(~요 체)을 사용하십시오. (예: "위험해요", "주의가 필요해요")
   - **객관적 서술:** "우리 아이는~"과 같은 표현이나 과도하게 감정적인 언어는 피하십시오.
   - **간결함:** 요약(Summary), 문단 1, 문단 2 내용 간에 중복이 없어야 합니다.

3. **내용 구조 (반복 엄금):**
   - **'hazard_name':** 5~10자의 명확한 한글 위험 상황 제목.
   - **'summary':** 핵심 위험을 요약하는 주어가 생략된 간결한 한글 문장. (예: "삼킴 시 질식 위험이 있습니다.")
   - **'reason_why':** 반드시 '\\n\\n'으로 구분된 두 개의 문단이어야 합니다.
     - **문단 1 (발달적 맥락):** 이 발달 단계의 아이에게 **왜** 이 물건이 위험한지 설명하십시오 (신체 능력, 호기심 등 [상황 정보] 인용).
     - **문단 2 (사고 시나리오):** **어떻게** 사고가 발생하는지 구체적인 순서를 묘사하십시오.
     - *주의: 문단 1과 문단 2에 같은 문장을 반복하지 마십시오.*
   - **'action_plan':** 구체적이고 실천 가능한 3가지 행동 수칙.
   - **'purchase_keyword':** 커머스 검색을 위한 10자 이내의 핵심 한글 키워드.

[출력 형식]
반드시 유효한 JSON 형식으로만 출력하십시오:
{{
  "hazards": [
    {{
      "item_name": "YOLO가 탐지한 원본 영문명",
      "hazard_name": "5~10자 이내 한글 제목",
      "risk_level": "위험 | 경고",
      "summary": "주어 없는 한 문장 요약 (한글)",
      "reason_why": "(발달 단계 특성 설명)\\n\\n(구체적인 사고 시나리오)",
      "action_plan": ["행동 수칙 1", "행동 수칙 2", "행동 수칙 3"],
      "purchase_keyword": "핵심 상품 키워드(10자 이내)"
    }}
  ]
}}
""".strip()


async def _get_products_async(keyword: str):
    """비동기로 상품 추천 정보를 가져옵니다."""
    return await asyncio.to_thread(get_safety_product_recommendation, keyword)


async def analyze_single_hazard(
    f_item: Dict[str, Any],
    raw_hazards: List[Dict[str, Any]],
    used_indices: Set[int],
) -> Optional[Dict[str, Any]]:
    """개별 위험 요소에 대해 YOLO 결과와 매핑하고 상품 정보를 추가합니다."""
    f_name = _norm_name(f_item.get("item_name"))
    if not f_name:
        return None

    # Gemini가 찾은 위험 요소(f_item)와 YOLO가 찾은 객체(raw_hazards)를 매칭
    for idx, r_item in enumerate(raw_hazards):
        if idx in used_indices:
            continue
        if _norm_name(r_item.get("item_name")) != f_name:
            continue

        keyword = (
            f_item.get("purchase_keyword")
            or f_item.get("item_name")
            or r_item.get("item_name")
            or ""
        )

        # 상품 정보 조회 (병렬 처리를 위해 여기서 await)
        products = await _get_products_async(str(keyword))

        # 데이터 업데이트
        risk_level = _normalize_risk(f_item.get("risk_level"))
        summary = f_item.get("summary", "")
        reason_why = f_item.get("reason_why", "")
        action_plan = f_item.get("action_plan", [])
        hazard_name = f_item.get("hazard_name", "위험 요소")

        r_item.update(
            {
                "hazard_name": hazard_name,
                "risk_level": risk_level,
                "summary": summary,
                "reason_why": reason_why,
                "action_plan": action_plan,
                "recommended_products": products,
            }
        )

        used_indices.add(idx)

        # 🖨️ [DEBUG] 처리된 위험 요소 정보 출력
        print("\n" + "="*50)
        print(f"🔍 [Detected] Item: {f_name}")
        print(f"🏷️  Hazard Name: {hazard_name}")
        print(f"🚨 Risk Level : {risk_level}")
        print(f"📝 Summary    : {summary}")
        print(f"💡 Reason Why : \n{reason_why}")
        print(f"📋 Action Plan: {action_plan}")
        print("="*50 + "\n")

        return r_item

    return None

# 🚫 [Block List] 오탐이 많거나, 굳이 Gemini가 분석할 필요 없는 "잡동사니"
# 여기에 포함되면 탐지되어도 무조건 무시합니다.
BLOCKED_CLASSES = [
    "Pen/Pencil", "Cell Phone","Faucet","Candle","Handbag/Satchel"
]

# ⭐ [Priority List] 안전 진단에 필수적인 "핵심 가구 및 위험 요소"
# 여기에 포함되면 신뢰도가 조금 낮아도 챙기고, Gemini에게 "가장 먼저" 알려줍니다.
PRIORITY_CLASSES = [
    # 가구류 (넘어짐, 부딪힘)
    "Chair", "Dining Table", "Desk", "Bed", "Cabinet/shelf", 
]
async def run_full_safety_analysis(
    image_bytes: bytes,
    growth_stage: str,
    space_type: str = "거실",
) -> Tuple[List[Dict[str, Any]], bytes]:
    """
    전체 안전 분석 프로세스를 실행합니다.
    """
    # 🕒 전체 프로세스 시작 시간 기록
    start_time = time.time()
    print(f"🚀 [Start] Safety Analysis for Stage: '{growth_stage}'")

    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    # 발달 단계가 선택되지 않았을 경우 '전체 연령'으로 기본값 설정
    if not growth_stage or growth_stage.strip() == "":
        growth_stage = "혼자 걷기 시작하는 시기 (1~3세)"  # 👈 여기가 변경됨
        print(f"⚠️ Growth stage not specified. Defaulting to '{growth_stage}'.")
    # 1. YOLO 예측
    yolo_start = time.time()
    model = get_model()
    results = model.predict(source=image, conf=0.03)
    print(f"⏱️  [YOLO] Detection took: {time.time() - yolo_start:.2f}s")

    raw_hazards: List[Dict[str, Any]] = []
    # 👇 [수정됨] 필터링 로직이 추가된 반복문
    for r in results:
        for box in r.boxes:
            item_name = r.names[int(box.cls[0])]
            conf = float(box.conf[0])
            
            # 🚫 1. 차단(Block) 로직: 쓸모없는 물건은 즉시 폐기
            if item_name in BLOCKED_CLASSES:
                continue

            # ⭐ 2. 우선순위(Priority) 로직: 중요한 물건인지 태깅
            is_priority = item_name in PRIORITY_CLASSES
            
            raw_hazards.append(
                {
                    "item_name": item_name,
                    "confidence": round(conf, 2),
                    "bbox_coords": [int(x) for x in box.xyxy[0].tolist()],
                    "is_priority": is_priority, # 정렬용 태그
                }
            )

    if not raw_hazards:
        print("✅ No objects detected.")
        return [], image_bytes

    detected_items = ", ".join(dict.fromkeys(h["item_name"] for h in raw_hazards))
    print(f"📦 Detected Items: {detected_items}")

    # 2. RAG 데이터 로드
    risk_rules = _read_file_safe(RISK_MAP_PATH)
    safety_context = _read_file_safe(SAFETY_KNOWLEDGE_PATH)

    

    # 3. Gemini 프롬프트 생성 및 요청
    prompt = _build_prompt(
        growth_stage=growth_stage,
        space_type=space_type,
        risk_rules=risk_rules,
        safety_context=safety_context,
        detected_items=detected_items,
    )

    gemini_start = time.time()
    client = get_gemini_client()
    response = client.models.generate_content(
        model="gemini-2.5-flash", 
        contents=prompt,
        config={"response_mime_type": "application/json"},
    )
    print(f"⏱️  [Gemini] Inference took: {time.time() - gemini_start:.2f}s")

    try:
        data = json.loads(response.text)
        hazards = data.get("hazards", [])
    except json.JSONDecodeError:
        print("❌ JSON 파싱 실패:", response.text)
        hazards = []

    # 4. 결과 매핑 및 상품 추천 (비동기 병렬 처리)
    mapping_start = time.time()
    used_indices: Set[int] = set()
    mapped = await asyncio.gather(
        *[
            analyze_single_hazard(h, raw_hazards, used_indices)
            for h in hazards
            if isinstance(h, dict)
        ]
    )
    print(f"⏱️  [Mapping & Commerce] took: {time.time() - mapping_start:.2f}s")

    final_hazards = [h for h in mapped if h is not None]
    
    # 🕒 전체 종료 시간 기록 및 출력
    total_duration = time.time() - start_time
    print(f"🏁 [Done] Total Execution Time: {total_duration:.2f}s")
    print(f"📊 Final Hazard Count: {len(final_hazards)}")

    return final_hazards, image_bytes