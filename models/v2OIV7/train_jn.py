import os
import yaml
import sys
from ultralytics import YOLO

# ======================================================
# [설정] 클래스 목록 (88개)
# ======================================================
TARGET_CLASSES = [
    'Adhesive tape', 'Barrel', 'Bathtub', 'Bed', 'Blender', 'Book', 'Bowl', 'Box',
    'Cabinetry', 'Calculator', 'Candle', 'Chair', 'Chopsticks', 'Clock', 'Coffee table',
    'Coffeemaker', 'Computer keyboard', 'Computer monitor', 'Computer mouse', 'Cosmetics',
    'Couch', 'Cutting board', 'Desk', 'Dishwasher', 'Drill (Tool)', 'Eraser', 'Flower',
    'Fork', 'Gas stove', 'Hair dryer', 'Hammer', 'Handbag', 'Headphones', 'Heater',
    'Houseplant', 'Jug', 'Kettle', 'Kitchen & dining room table', 'Knife', 'Ladder',
    'Lamp', 'Laptop', 'Lipstick', 'Mechanical fan', 'Microwave oven', 'Mirror',
    'Mobile phone', 'Nightstand', 'Oven', 'Pen', 'Pencil case', 'Person', 'Personal care',
    'Piano', 'Picture frame', 'Pillow', 'Plate', 'Power plugs and sockets', 'Refrigerator',
    'Remote control', 'Ruler', 'Scale', 'Scissors', 'Screwdriver', 'Shelf', 'Shower',
    'Sink', 'Spoon', 'Stapler', 'Stool', 'Tablet computer', 'Tap', 'Teapot', 'Teddy bear',
    'Telephone', 'Television', 'Toaster', 'Toilet', 'Toilet paper', 'Toothbrush', 'Towel',
    'Toy', 'Treadmill', 'Vase', 'Washing machine', 'Waste container', 'Whiteboard', 'Wine glass'
]

def main():
    # ======================================================
    # 1단계: 데이터셋 경로 자동 감지 및 설정 파일 생성
    # ======================================================
    if os.path.exists("./oiv7_dataset/images"):
        dataset_root = "./oiv7_dataset"
        print(f"✅ 데이터셋 경로 감지됨: {dataset_root}")
    elif os.path.exists("./images"):
        dataset_root = "."
        print(f"✅ 데이터셋 경로 감지됨: {dataset_root}")
    else:
        print("❌ [오류] 'images' 폴더를 찾을 수 없습니다. 압축 해제 위치를 확인하세요.")
        sys.exit(1)

    # data.yaml 생성
    data_config = {
        'path': os.path.abspath(dataset_root),
        'train': 'images/train',
        'val': 'images/validation',
        'names': {i: name for i, name in enumerate(TARGET_CLASSES)}
    }

    yaml_path = 'data.yaml'
    with open(yaml_path, 'w') as f:
        yaml.dump(data_config, f, sort_keys=False)
    
    print(f"✅ 설정 파일 준비 완료: {os.path.abspath(yaml_path)}")

    # ======================================================
    # 2단계: 스마트 학습 실행 (A100 x 2 최적화 + 이어하기)
    # ======================================================
    project_name = 'safe_home_project'
    run_name = 'train_result'
    ckpt_path = f"{project_name}/{run_name}/weights/last.pt"

    # 백업 파일 확인
    if os.path.exists(ckpt_path):
        print("\n" + "="*40)
        print(f"🔄 백업 파일 발견! ({ckpt_path})")
        print("🚀 멈췄던 곳부터 학습을 이어서 진행합니다 (Resume)...")
        print("="*40 + "\n")
        
        model = YOLO(ckpt_path)
        model.train(resume=True) # 이어하기는 설정값 자동 로드됨
        
    else:
        print("\n" + "="*40)
        print("🆕 처음부터 학습을 시작합니다! (A100 듀얼 모드)")
        print("="*40 + "\n")
        
        model = YOLO('yolo26n.pt')
        
        model.train(
            data=yaml_path,
            epochs=50,
            imgsz=640,
            
            # 🚀 [A100 2장 전용 최적화 설정]
            device=[0, 1],   # GPU 0번, 1번 동시 사용 (DDP)
            batch=256,       # 2장 합쳐서 512 (메모리 부족 시 256으로 줄일 것)
            workers=16,      # 데이터 로더 속도 향상
            
            project=project_name,
            name=run_name,
            exist_ok=True,
            amp=True         # 속도 향상 (Mixed Precision)
        )

    print("✅ 모든 학습 과정이 완료되었습니다!")

# ⚠️ 멀티 GPU 사용 시 이 구문이 없으면 에러 발생 (무한 프로세스 생성 방지)
if __name__ == '__main__':
    main()