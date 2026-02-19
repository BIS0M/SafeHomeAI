import os
from ultralytics import YOLO

def train():
    # ==============================================================================
    # [1] 설정 및 경로 지정
    # ==============================================================================
    # 사용자 데이터셋 경로
    DATA_PATH = "/home/jupyter/objects365_600k/data.yaml"
    
    # 결과를 저장할 프로젝트 경로
    PROJECT_PATH = "/home/jupyter/yolo_outputs"
    RUN_NAME = "safety_yolo26l_600k_20260203"
    
    # 모델 설정: YOLO26 Large 모델 사용
    # YOLO26은 COCO 80 클래스로 프리트레인되어 있으며, data.yaml의 128 클래스에 맞춰 헤드가 자동 교체됩니다.
    BASE_MODEL = "yolo26l.pt" 

    # 마지막 체크포인트 경로 (학습 중단 시 이어하기 위함)
    last_ckpt_path = os.path.join(PROJECT_PATH, RUN_NAME, "weights/last.pt")

    # ==============================================================================
    # [2] 모델 로드 (Resume 로직)
    # ==============================================================================
    resume_flag = False
    
    if os.path.exists(last_ckpt_path):
        print(f"\n[INFO] 기존 학습 기록 발견: {last_ckpt_path}")
        print("--- 중단된 시점부터 학습을 재개합니다. ---\n")
        model = YOLO(last_ckpt_path)
        resume_flag = True
    else:
        print(f"\n[INFO] 새로운 학습 시작: {BASE_MODEL}")
        print("--- 처음부터 학습을 시작합니다. ---\n")
        model = YOLO(BASE_MODEL)
        resume_flag = False

    # ==============================================================================
    # [3] 학습 시작 (GCP A100 x 2 최적화)
    # ==============================================================================
    # YOLO26은 MuSGD 옵티마이저를 기본으로 사용하여 수렴 속도와 안정성이 개선되었습니다.
    
    model.train(
        data=DATA_PATH,
        
        # 기본 하이퍼파라미터
        epochs=50,
        imgsz=640,
        
        # 하드웨어 설정 (A100 40GB x 2)
        device="0,1,2,3",           # Multi-GPU (DDP)
        batch=128,               # [최적화] A100 2장이면 메모리가 넉넉하므로 64~128 권장
                                # RT-DETR보다 메모리 효율이 좋아 더 큰 배치 가능
        workers=32,             # 데이터 로딩 병목 방지
        
        # 저장 경로 설정
        project=PROJECT_PATH,
        name=RUN_NAME,
        exist_ok=True,          # 폴더 덮어쓰기 허용 (Resume 시 필수)
        resume=resume_flag,     # 이어하기 여부
        
        # YOLO26 전용 최적화 옵션
        optimizer="auto",       # [중요] YOLO26은 'MuSGD'를 자동으로 선택하거나 최적의 옵티마이저를 사용합니다.
                                # RT-DETR처럼 AdamW를 강제하기보다 auto로 두는 것이 성능상 유리합니다.
        lr0=0.01,               # YOLO 기본 학습률 (SGD/MuSGD 기준)
        warmup_epochs=3,        # 웜업
        cos_lr=True,            # Cosine Decay Scheduler
        
        # 정밀도 및 기타 설정
        amp=True,               # [중요] A100의 Tensor Core 활용을 위해 True 권장.
                                # YOLO26은 RT-DETR보다 수치적으로 안정적이므로 켜는 것이 좋습니다.
        cache=True,             # RAM 여유 시 이미지 캐싱으로 속도 향상
        save_period=1,          # 매 에포크마다 저장 (안전장치)
        val=True,               # 학습 중 검증 수행
        plots=True              # 학습 그래프 저장
    )

if __name__ == "__main__":
    train()