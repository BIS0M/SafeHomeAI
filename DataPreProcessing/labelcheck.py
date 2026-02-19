import os
import glob

def check_class_existence(folder_path):
    # 1. 경로 유효성 검사
    if not os.path.isdir(folder_path):
        print("❌ 오류: 유효하지 않은 폴더 경로입니다.")
        return

    # 2. 모든 txt 파일 찾기
    file_pattern = os.path.join(folder_path, "*.txt")
    files = glob.glob(file_pattern)
    
    if not files:
        print(f"📂 '{folder_path}' 안에 .txt 파일이 없습니다.")
        return

    print(f"🔍 {len(files)}개의 파일을 스캔하여 0~14번 클래스를 확인합니다...\n")

    # 3. 존재하는 클래스 번호 수집 (중복 제거를 위해 set 사용)
    found_classes = set()

    for file_path in files:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                parts = line.strip().split()
                if parts:
                    try:
                        # 맨 앞의 클래스 ID를 숫자로 변환하여 저장
                        class_id = int(parts[0])
                        found_classes.add(class_id)
                    except ValueError:
                        continue # 숫자가 아닌 경우 건너뜀

    # 4. 0~14번 확인 및 출력
    print("📊 [0~14번 클래스 존재 여부]")
    print("-" * 30)
    
    # 존재하는 것만 보고 싶으면 아래 주석을 참고하세요
    for i in range(15):
        status = "O (있음)" if i in found_classes else "X (없음)"
        print(f"{i}번: {status}")
        
    print("-" * 30)

    # (선택 사항) 0~14 범위를 벗어난 이상치 클래스가 있는지 확인
    extras = found_classes - set(range(15))
    if extras:
        print(f"⚠️ 참고: 범위(0~14) 밖의 클래스도 발견되었습니다: {sorted(list(extras))}")

# --- 실행부 ---
if __name__ == "__main__":
    target_path = input("📂 라벨 폴더 경로 입력: ").strip().replace('"', '').replace("'", "")
    check_class_existence(target_path)