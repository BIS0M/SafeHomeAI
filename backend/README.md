key.json 파일 대체 방법:
```bash
# 1. 일반 로그인 (선택사항이지만 권장)
gcloud auth login

# 2. 로컬 개발용 인증 라이브러리 활성화 (필수)
gcloud auth application-default login
```

백엔드 도커 컨테이너 빌드 방법:
```bash
gcloud builds submit --tag asia-northeast3-docker.pkg.dev/knu-team-02/safehome-repo/backend:v1 .
```

> 백엔드 도커 빌드 시 주의사항: requirements.txt에 해당 백엔드가 필요로 하는 라이브러리 & 패키지가 다 포함되어있어야 함. (GCP는 리눅스 기반이므로 conda와 같은 호환되지 않는 내용 잘 파악해야 함.)

배포 방법:
```bash
gcloud run deploy safehome-backend \
    --image=asia-northeast3-docker.pkg.dev/knu-team-02/safehome-repo/backend:v1 \
    --region=asia-northeast3 \
    --memory=16Gi \
    --cpu=4 \
    --cpu-boost \
    --concurrency=50 \
    --timeout=300 \
    --set-env-vars="GEMINI_API_KEY=AIzaSyCaUdE9-luXP7lz1JTdhaIQaADzEBxofeo,\
NAVER_CLIENT_ID=AKN_uYZWiDP4agnwLOuw,\
NAVER_CLIENT_SECRET=mjem6Fj4Ih,\
JWT_SECRET_KEY=change-me-super-secret,\
JWT_ALGORITHM=HS256,\
JWT_EXPIRE_MINUTES=60" \
    --allow-unauthenticated
```

# 🛡️ SafeHomeAI - Backend Engine (V2.0)

아이의 안전을 지키는 AI 백엔드 서버입니다. YOLOv8을 이용한 객체 탐지와 Gemini 2.0 Flash 기반의 RAG(Retrieval-Augmented Generation) 시스템을 결합하여 고도로 전문화된 안전 가이드를 제공합니다.

## 🌟 핵심 기능 및 기술 스택
- **AI 분석**: `RT-DETR` (객체 탐지) + `Gemini 1.5 Pro` (RAG 기반 조언 생성)
- **RAG 지식 베이스**: `safety_knowledge.txt`에 저장된 국가 안전 가이드라인을 기반으로 AI가 답변을 생성하여 신뢰성을 확보함
- **클라우드 인프라**: Google Cloud Storage (이미지 보관), Firestore (분석 리포트 저장)
- **프레임워크**: FastAPI (Asynchronous API)

## 📂 폴더 구조 설명
- `app/api/`: API 엔드포인트 및 요청/응답 처리
- `app/services/`: 비즈니스 로직의 핵심 (AI 분석, GCS 업로드, 쇼핑 링크 생성)
- `app/db/`: 데이터베이스(Firestore) 연결 및 쿼리 관리
- `app/core/`: 앱 설정 및 환경 변수 관리
- `app/data/`: RAG에 사용되는 안전 지식 텍스트 파일

## 🚀 실행 방법
1. `.env` 파일에 `GEMINI_API_KEY` 설정
2. `key.json` 파일을 루트 디렉토리에 위치
3. 패키지 설치: `pip install -r requirements.txt`
4. 서버 실행: `python -m app.main` or `uvicorn app.main:app --reload`


## 🔎 GEMINI-2.5-flash 프롬프트 (01/21)
"""
[역할 정의]
당신은 'SafeHomeAI'라는 이름의 영유아 안전 전문가입니다.
당신의 목표는 내용의 반복 없이 간결하고 차별화된 안전 통찰력을 제공하는 것입니다.

[컨텍스트/배경 정보]
- 아이의 발달 단계: {growth_stage}
- 선택된 공간: {space_type}
- 안전 지식 베이스(RAG): {knowledge_base}
- 탐지된 물건 목록(YOLO): {detected_items}

[지시 사항]
1. (필터링) '{growth_stage}' 단계의 아이에게 '실질적인' 위험이 되는 물건만 선택하세요.
2. (엄격한 중복 방지) 문단 1과 문단 2는 반드시 서로 다른 정보를 다뤄야 합니다:
   - 문단 1 (특성): 왜 이 아이의 발달 단계가 해당 물건을 위험하게 만드는지에만 집중하세요 (예: 신체 능력, 호기심 등).
   - 문단 2 (시나리오): 구체적이고 독특한 사고 발생 과정에만 집중하세요 (어떻게 사고가 일어나는가).
   - 두 문단에서 동일한 위험 설명을 반복해서는 절대 안 됩니다.
3. (환각 방지 - Zero Hallucination)
   - 반드시 [지식 베이스]에 제공된 사실만 사용하세요.
   - 만약 지식 베이스에 특정 물건에 대한 구체적 위험이 언급되어 있지 않다면, 일반적인 안전 상식에 기반해 경고하되 가짜 통계나 가짜 발달 이정표를 지어내지 마세요.
4. (말투) 전문적이고 예의 바른 한국어(~요 스타일)를 사용하세요. "우리 아이는~"과 같은 감성적인 표현은 피하세요.

[출력 형식]
Flutter 앱에서 직접 파싱할 수 있도록 반드시 아래의 JSON 형식을 엄격히 지켜 출력하세요:
{
  "hazards": [
    {
      "item_name": "YOLO 탐지 원문 이름",
      "hazard_name": "한국어 제목",
      "reason_why": "(해당 단계만의 고유한 특성 설명)\\n\\n(구체적인 사고 발생 과정)",
      "action_plan": ["조치 사항 1", "조치 사항 2", "조치 사항 3"]
    }
  ]
}
"""


-------------------------------------------------------------

## 구성 요소,역할 (음식점 비유),실제 기능
- `main.py`, 음식점 입구 (안내소),"서버를 켜고, 어떤 서비스들이 있는지 연결만 해주는 사령탑"
- `api/v1/`, 주문받는 웨이터,"사용자의 요청(이미지 등)을 받고, 결과물을 다시 사용자에게 전달"
- `services/`, 주방장 (핵심 로직),"YOLO로 사물을 찾고, Gemini로 조언을 만드는 실제 요리 과정"
- `db/`, 냉장고/창고,완성된 데이터나 사용자 정보를 저장하고 꺼내오는 곳
- `core/`, 운영 매뉴얼,"API 키, DB 주소 등 가게 운영에 필요한 핵심 설정값"

-------------------------------------------------------------

## 요약: 이제 어떤 일이 일어나나요?

1. **main.py**는 서버를 켜고 "내 모든 주소(Route) 정보는 endpoints.py에 있어!"라고 선언합니다.

2. 사용자가 /analyze로 사진을 보내면 **endpoints.py**가 받습니다.

3. **endpoints.py**는 직접 분석하지 않고, **ai_service.py**에게 "이 사진 분석해줘"라고 시킵니다.

4. 분석이 끝나면 **storage_service.py**에게 "GCS에 저장해줘"라고 시킵니다.

5. 모든 준비가 끝나면 **firestore.py**에게 "DB에 기록 남겨줘"라고 말한 뒤 사용자에게 "완료!"라고 응답합니다.
