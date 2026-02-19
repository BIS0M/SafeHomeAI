import argparse
import os
from ultralytics import YOLO, RTDETR

def train_model(args):
    # 1. 모델 선택 (RT-DETR 또는 YOLOv11)
    if 'rtdetr' in args.model_type.lower():
        model = RTDETR(args.model_type) # 예: rtdetr-x.pt
    else:
        model = YOLO(args.model_type)   # 예: yolo11x.pt

    # 2. 고성능 학습 설정
    model.train(
        data=args.data_yaml_path,
        epochs=args.epochs,
        imgsz=args.imgsz,          # 1024 권장 (고해상도)
        batch=args.batch_size,     # 8개 GPU 사용 시 대폭 늘릴 수 있음 (예: 128)
        project=args.output_dir,
        name=args.name,
        device=args.device,        # 분산 학습 시 '0,1,2,3,4,5,6,7'
        
        # --- 고급 하이퍼파라미터 ---
        optimizer='AdamW',         # 대규모 데이터셋에 안정적
        lr0=0.001,                 # 초기 학습률
        cos_lr=True,               # 코사인 스케줄러 적용
        overlap_mask=True,         # 객체 중첩 학습 강화
        
        # --- 증강(Augmentation) 극대화 ---
        mosaic=1.0, 
        mixup=0.3,                 # 중첩 객체를 위해 기존보다 상향
        copy_paste=0.3,            # 소형 객체(가위, 전선) 학습에 필수
        degrees=15.0,
        scale=0.5,
        shear=2.0,
        perspective=0.0001,
        
        # --- 속도 및 인프라 최적화 ---
        workers=16,                # CPU 코어 수에 맞춰 조절
        exist_ok=True,
        cache=True                 # RAM 여유가 있다면 GCS 통신 줄이기 위해 캐싱 사용
    )

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--model_type', type=str, default='rtdetr-x.pt') 
    parser.add_argument('--data_yaml_path', type=str, required=True)
    parser.add_argument('--epochs', type=int, default=100)
    parser.add_argument('--imgsz', type=int, default=1024)
    parser.add_argument('--batch_size', type=int, default=-1) # 자동 설정
    parser.add_argument('--device', type=str, default='0,1,2,3,4,5,6,7') 
    parser.add_argument('--output_dir', type=str, default='/gcs/safety-furniture-project-v1/rtdetr/outputs')
    parser.add_argument('--name', type=str, default='safehome_rtdetr')

    args = parser.parse_args()
    train_model(args)