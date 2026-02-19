import os
import glob

def replace_specific_class(folder_path, old_id, new_id):
    """
    폴더 내의 txt 파일을 순회하며 특정 클래스 ID(old_id)를 찾아
    새로운 클래스 ID(new_id)로 변경합니다.
    """
    txt_files = glob.glob(os.path.join(folder_path, "*.txt"))
    
    if not txt_files:
        print("[알림] 해당 폴더에 .txt 파일이 없습니다.")
        return

    print(f"[라이트] 총 {len(txt_files)}개의 파일을 검사합니다...")
    changed_count = 0

    for file_path in txt_files:
        is_modified = False
        modified_lines = []
        
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        for line in lines:
            parts = line.strip().split()
            
            if len(parts) < 5:
                modified_lines.append(line)
                continue
            
            current_class = parts[0]
            
            if current_class == str(old_id):
                parts[0] = str(new_id)
                new_line = " ".join(parts) + "\n"
                modified_lines.append(new_line)
                is_modified = True
            else:
                modified_lines.append(line)
        
        if is_modified:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(modified_lines)
            changed_count += 1
            
    print("-" * 30)
    print(f"작업 완료: 총 {changed_count}개의 파일이 수정되었습니다.")
    print(f"변경 내용: 클래스 {old_id} -> {new_id}")
    print("-" * 30)

# --- 실행 부분 ---
if __name__ == "__main__":
    print("=== 클래스 ID 변경 라이트 도구 ===")
    print("(종료하시려면 경로 입력 단계에서 'exit'를 입력하세요)")
    
    while True:
        # 1. 폴더 경로 입력
        target_folder = input("\n라벨 폴더 경로를 입력하세요 (종료: exit): ").strip()
        
        # 종료 조건 체크
        if target_folder.lower() == 'exit':
            print("프로그램을 종료합니다.")
            break

        # 따옴표 제거
        target_folder = target_folder.replace('"', '').replace("'", "")

        if os.path.exists(target_folder):
            try:
                # 2. 변경할 대상 번호 (From)
                old_input = input("찾을 기존 클래스 번호: ").strip()
                if old_input.lower() == 'exit': break
                target_old = int(old_input)
                
                # 3. 새로운 번호 (To)
                new_input = input("바꿀 새로운 클래스 번호: ").strip()
                if new_input.lower() == 'exit': break
                target_new = int(new_input)
                
                print(f"\n[작업 시작] '{target_folder}'에서 {target_old} -> {target_new} 변경 중...")
                replace_specific_class(target_folder, target_old, target_new)
                
            except ValueError:
                print("오류: 클래스 번호는 정수(숫자)만 입력해야 합니다.")
        else:
            print(f"오류: 폴더를 찾을 수 없습니다 -> {target_folder}")