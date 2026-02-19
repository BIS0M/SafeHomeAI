import argparse
from ultralytics import YOLO
from google.cloud import storage

def train_model(args):
    # 1. 모델 로드 (YOLOv8 n/s/m/l 중 선택)
    model = YOLO(args.model_type)

    # 2. 학습 실행
    # Vertex AI는 GCS를 /gcs/버킷명/ 경로로 마운트합니다.
    model.train(
        data=args.data_yaml_path, 
        epochs=args.epochs,
        imgsz=args.imgsz,
        batch=args.batch_size,
        project=args.output_dir, # 결과가 저장될 GCS 경로
        name=args.name,
        device=0,
        
        # --- 데이터 증강 파라미터 추가 ---
        mosaic=1.0,           # 4장의 이미지를 합쳐 학습 (작은 객체 탐지에 매우 효과적)
        mixup=0.1,            # 두 이미지를 겹쳐서 학습 (일반화 성능 향상)
        degrees=10.0,         # 이미지 회전 (-10 ~ +10도)
        perspective=0.0001,   # 원근감 변형
        flipud=0.0,           # 상하 반전 (가구의 경우 보통 0.0 권장)
        fliplr=0.5,           # 좌우 반전 (0.5 = 50% 확률)
        hsv_h=0.015,          # 색상(Hue) 변화
        hsv_s=0.7,            # 채도(Saturation) 변화
        hsv_v=0.4,            # 명도(Value) 변화
        # ----------------------------
    )

    print("학습 완료 및 GCS 저장 완료")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    
    # GCP 환경에 맞게 인자를 받을 수 있도록 설정
    parser.add_argument('--model_type', type=str, default='yolov8n.pt')
    parser.add_argument('--data_yaml_path', type=str, default='/gcs/safety-furniture-project-v1/datav1/data.yaml', help='GCS 내 data.yaml 경로')
    parser.add_argument('--epochs', type=int, default=30)
    parser.add_argument('--imgsz', type=int, default=640)
    parser.add_argument('--batch_size', type=int, default=32)
    parser.add_argument('--output_dir', type=str, default='/gcs/safety-furniture-project-v1/datav1/outputs', help='GCS 내 출력 디렉토리 경로')
    parser.add_argument('--name', type=str, default='safehome_yolo_v8', help='학습 결과 저장 폴더 이름')

    args = parser.parse_args()
    train_model(args)