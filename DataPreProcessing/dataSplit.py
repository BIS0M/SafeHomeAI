import os
import shutil
import random

# ================= 사용자 설정 구간 (여기만 수정하세요) =================
# 1. 원본 데이터 경로 (이미지와 라벨이 모여있는 폴더)
SOURCE_IMG_DIR = r'C:\Users\bsmrc\Downloads\Bed.v11i.yolov8\train\images'  # 이미지가 모여있는 폴더 경로
SOURCE_TXT_DIR = r'C:\Users\bsmrc\Downloads\Bed.v11i.yolov8\train\labels'  # 라벨 txt가 모여있는 폴더 경로

# 2. 결과물이 저장될 경로 (자동으로 생성됩니다)
DEST_DIR = r'C:\Users\bsmrc\Downloads\Bed.v11i.yolov8\train\split/'
# 3. 분할 비율 설정 (합이 1.0이 되어야 함)
RATIO_TRAIN = 0.7  # 학습용
RATIO_VAL = 0.2    # 검증용
RATIO_TEST = 0.1   # 테스트용

# 4. 랜덤 시드 (결과를 고정하고 싶으면 숫자를 넣으세요, 아니면 None)
RANDOM_SEED = 42
# ====================================================================

def split_dataset():
    # 1. 경로 확인 및 생성
    if not os.path.exists(SOURCE_IMG_DIR):
        print(f"에러: 원본 이미지 폴더를 찾을 수 없습니다: {SOURCE_IMG_DIR}")
        return

    # 결과 폴더 구조 생성 (images/train, labels/train 등)
    for split in ['train', 'val', 'test']:
        os.makedirs(os.path.join(DEST_DIR, 'images', split), exist_ok=True)
        os.makedirs(os.path.join(DEST_DIR, 'labels', split), exist_ok=True)

    # 2. 이미지 파일 리스트 가져오기
    # (jpg, png, jpeg 등 이미지 확장자만 필터링)
    image_extensions = {'.jpg', '.jpeg', '.png', '.bmp'}
    images = [f for f in os.listdir(SOURCE_IMG_DIR) 
              if os.path.splitext(f)[1].lower() in image_extensions]

    # 데이터가 비었는지 확인
    if not images:
        print("에러: 이미지 폴더가 비어있습니다.")
        return

    # 3. 셔플 (랜덤 섞기)
    if RANDOM_SEED is not None:
        random.seed(RANDOM_SEED)
    random.shuffle(images)

    # 4. 개수 계산
    total_count = len(images)
    train_count = int(total_count * RATIO_TRAIN)
    val_count = int(total_count * RATIO_VAL)
    test_count = total_count - train_count - val_count # 남은 거 다 test로

    print(f"전체 이미지: {total_count}장")
    print(f"분할 계획 -> Train: {train_count}, Val: {val_count}, Test: {test_count}")

    # 5. 파일 복사 실행
    count = 0
    for i, image_file in enumerate(images):
        # 어디로 보낼지 결정
        if i < train_count:
            split_type = 'train'
        elif i < train_count + val_count:
            split_type = 'val'
        else:
            split_type = 'test'

        # 파일 이름 (확장자 제외) 추출 -> 라벨 파일 찾기용
        file_name, _ = os.path.splitext(image_file)
        label_file = file_name + ".txt"

        # 소스/목적지 경로 설정
        src_img_path = os.path.join(SOURCE_IMG_DIR, image_file)
        src_label_path = os.path.join(SOURCE_TXT_DIR, label_file)

        dst_img_path = os.path.join(DEST_DIR, 'images', split_type, image_file)
        dst_label_path = os.path.join(DEST_DIR, 'labels', split_type, label_file)

        # 이미지 복사
        shutil.copy2(src_img_path, dst_img_path)

        # 라벨 파일이 있으면 복사 (라벨 없는 배경 이미지가 있을 수 있으므로 체크)
        if os.path.exists(src_label_path):
            shutil.copy2(src_label_path, dst_label_path)
        
        count += 1
        if count % 100 == 0:
            print(f"{count}장 처리 완료...")

    print(f"\n작업 완료! '{DEST_DIR}' 폴더를 확인하세요.")

if __name__ == "__main__":
    split_dataset()