import argparse
import os
import yaml
import shutil
import subprocess
import sys
from ultralytics import YOLO

# 88개 클래스 목록 유지
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

def create_data_yaml(local_data_dir):
    data_config = {
        'path': local_data_dir,
        'train': 'images/train',
        'val': 'images/validation',
        'names': {i: name for i, name in enumerate(TARGET_CLASSES)}
    }
    yaml_path = '/app/data.yaml'
    with open(yaml_path, 'w') as f:
        yaml.dump(data_config, f, sort_keys=False)
    return yaml_path

def train(args):
    local_data_dir = "/app/dataset"
    PROJECT_ID = "knu-team-02" # [확인됨] 사용자님의 프로젝트 ID
    
    print(f"🚀 [고속 복사] GCS({args.data_dir}) -> 로컬 SSD 복사 시도...")
    
    if os.path.exists(local_data_dir):
        shutil.rmtree(local_data_dir)
    os.makedirs(local_data_dir, exist_ok=True)
    
    gcs_uri = args.data_dir.replace('/gcs/', 'gs://')
    
    # [핵심 수정] gcloud가 프로젝트와 인증 정보를 인식하도록 설정 추가
    try:
        # 1. 프로젝트 ID 설정
        subprocess.run(["gcloud", "config", "set", "project", PROJECT_ID], check=True)
        
        # 2. 고속 복사 실행 (상세 에러 로그 캡처 포함)
        # gcloud storage cp 명령어에 프로젝트 ID를 명시적으로 한 번 더 넣습니다.
        command = ["gcloud", "storage", "cp", "-r", "--project", PROJECT_ID, gcs_uri, local_data_dir]
        print(f"실행 명령어: {' '.join(command)}")
        
        result = subprocess.run(command, capture_output=True, text=True)
        
        if result.returncode != 0:
            print("\n❌ [복사 실패 에러 메시지 확인]")
            print(result.stderr)
            sys.exit(1)
            
        print("✅ 데이터 고속 복사 완료!")

    except subprocess.CalledProcessError as e:
        print(f"❌ 설정 오류: {e}")
        sys.exit(1)

    # [Step 2] 설정 파일 생성 및 학습 시작
    yaml_path = create_data_yaml(local_data_dir)
    model = YOLO(args.model_variant)
    model.train(
        data=yaml_path,
        epochs=args.epochs,
        imgsz=args.imgsz,
        batch=args.batch_size,
        project=args.output_dir,
        name='safe_home_yolo',
        device=0,
        exist_ok=True,
        mosaic=1.0,
        mixup=0.1
    )

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--epochs', type=int, default=50)
    parser.add_argument('--batch_size', type=int, default=16)
    parser.add_argument('--imgsz', type=int, default=640)
    parser.add_argument('--model_variant', type=str, default='yolo26n.pt')
    parser.add_argument('--data_dir', type=str, required=True)
    parser.add_argument('--output_dir', type=str, required=True)
    args = parser.parse_args()
    train(args)