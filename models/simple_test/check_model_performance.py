# 수정해야 함

import os
from dotenv import load_dotenv
from ultralytics import YOLO

# .env 파일 로드
env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
load_dotenv(dotenv_path=env_path)

# 환경 변수에서 경로 읽기
MODEL_PATH = os.getenv("MODEL_PATH")
DATA_YAML = os.getenv("DATA_YAML_PATH")

# 1. 학습된 모델 불러오기
model = YOLO(MODEL_PATH)

# 2. 테스트 데이터셋으로 성능 평가
# data.yaml에 test 경로가 설정되어 있어야 합니다.
# split='test'로 설정하면 val 데이터가 아닌 test 데이터를 읽습니다.
metrics = model.val(data=DATA_YAML, split='test')

# 3. 주요 지표 출력
print(f"mAP50: {metrics.seg.map50 if hasattr(metrics, 'seg') else metrics.box.map50:.4f}")
print(f"mAP50-95: {metrics.seg.map:.4f}" if hasattr(metrics, 'seg') else f"mAP50-95: {metrics.box.map:.4f}")
print(f"정밀도(Precision): {metrics.box.mp:.4f}")
print(f"재현율(Recall): {metrics.box.mr:.4f}")
