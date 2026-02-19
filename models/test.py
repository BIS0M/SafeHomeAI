import os
import sys

# [체크포인트 1] 시작 확인
print("1. 프로그램 시작됨...")

try:
    from ultralytics import YOLO
    import cv2
    print("2. 라이브러리 로드 완료")
except ImportError as e:
    print(f"❌ 라이브러리가 없습니다: {e}")
    print("터미널에 'pip install ultralytics opencv-python'를 입력하세요.")
    sys.exit()

# 3. 경로 설정 (현재 폴더 기준)
# 학습한 모델 파일 이름을 여기에 정확히 적으세요.
MODEL_NAME = "yolo26lb.pt" 
IMAGE_NAME = "test.png"     # 테스트용 이미지 파일명

def run_test():
    # [체크포인트 2] 파일 존재 확인
    if not os.path.exists(MODEL_NAME):
        print(f"❌ 모델 파일을 찾을 수 없습니다: {os.path.abspath(MODEL_NAME)}")
        return

    if not os.path.exists(IMAGE_NAME):
        print(f"❌ 이미지 파일을 찾을 수 없습니다: {os.path.abspath(IMAGE_NAME)}")
        print("테스트할 이미지를 'test.jpg'로 저장해서 같은 폴더에 넣으세요.")
        return

    print(f"3. 모델 로딩 중: {MODEL_NAME}...")
    model = YOLO(MODEL_NAME)
    
    print("4. 추론 시작 (conf=0.1)...")
    results = model.predict(source=IMAGE_NAME, conf=0.1, save=True)

    # [체크포인트 3] 결과 확인
    box_count = len(results[0].boxes)
    print(f"5. 탐지 완료! 찾은 물체 개수: {box_count}")
    
    if box_count > 0:
        print(f"✅ 결과가 'runs/detect/predict' 폴더에 저장되었습니다.")
    else:
        print("❓ 탐지된 물체가 없습니다. conf를 더 낮춰보세요.")

if __name__ == "__main__":
    run_test()
    print("6. 프로그램 종료")