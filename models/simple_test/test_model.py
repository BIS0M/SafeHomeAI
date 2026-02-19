import os
from dotenv import load_dotenv
from ultralytics import YOLO
import cv2
import sys

# .env 로드 및 확인
env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
load_dotenv(dotenv_path=env_path)

MODEL_PATH = os.getenv("MODEL_PATH")
IMAGE_PATH = os.getenv("IMAGE_PATH")

# 경로가 제대로 로드되었는지 확인 (디버깅용)
if not MODEL_PATH or not IMAGE_PATH:
    print("에러: .env 파일에서 MODEL_PATH 또는 IMAGE_PATH를 찾을 수 없습니다.")
    sys.exit()

# 1. 모델 로드
try:
    model = YOLO(MODEL_PATH)
except Exception as e:
    print(f"모델 로드 중 에러 발생: {e}")
    sys.exit()

# 2. 이미지 추론
# project와 name을 지정하면 관리하기 훨씬 편해집니다.
results = model.predict(
    source=IMAGE_PATH, 
    imgsz=640, 
    conf=0.5, 
    save=True,
    project="outputs", # 결과물이 저장될 상위 폴더
    name="test_results", # 세부 폴더 이름
    exist_ok=True # 폴더가 이미 있어도 새로 만들지 않고 덮어씀
)

# 3. 결과 확인 (생략 가능하지만 로그용으로 좋습니다)
for r in results:
    print(f"탐지 완료! 물체 개수: {len(r.boxes)}")

# 4. 결과 시각화
try:
    res_plotted = results[0].plot()
    cv2.imshow("SafeHome Detection Test", res_plotted)
    cv2.waitKey(0)
    cv2.destroyAllWindows()
except Exception as e:
    print(f"시각화 중 에러 발생 (DLL 이슈 가능성): {e}")
    print("결과 이미지는 'outputs/test_results' 폴더에서 직접 확인해 주세요.")