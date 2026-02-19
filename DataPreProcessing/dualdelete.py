import os
import tkinter as tk
from tkinter import filedialog, messagebox
from PIL import Image, ImageTk

class DualFileCleanerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Image & Label Dual File Cleaner")
        self.root.geometry("1100x750")

        # 변수 초기화
        self.dir_left = ""
        self.dir_right = ""
        self.file_list_left = []
        self.file_list_right = []
        self.current_preview_image = None
        self.active_side = 'left' 
        
        # 바로 삭제 옵션
        self.immediate_delete_var = tk.BooleanVar(value=False)

        # === [1] 상단: 폴더 선택 영역 ===
        top_frame = tk.Frame(root, pady=10)
        top_frame.pack(fill="x")

        self.btn_left = tk.Button(top_frame, text="📁 이미지 폴더 선택", command=self.select_left_dir, bg="#e1f5fe")
        self.btn_left.grid(row=0, column=0, padx=10, sticky="ew")
        self.lbl_left_path = tk.Label(top_frame, text="경로 미지정", fg="gray")
        self.lbl_left_path.grid(row=1, column=0, padx=10)

        self.btn_right = tk.Button(top_frame, text="📁 라벨 폴더 선택", command=self.select_right_dir, bg="#fff3e0")
        self.btn_right.grid(row=0, column=1, padx=10, sticky="ew")
        self.lbl_right_path = tk.Label(top_frame, text="경로 미지정", fg="gray")
        self.lbl_right_path.grid(row=1, column=1, padx=10)

        top_frame.grid_columnconfigure(0, weight=1)
        top_frame.grid_columnconfigure(1, weight=1)

        # === [2] 메인 컨텐츠 영역 ===
        main_paned = tk.PanedWindow(root, orient=tk.HORIZONTAL, sashwidth=5)
        main_paned.pack(fill="both", expand=True, padx=10, pady=5)

        # --- 좌측 리스트 ---
        list_frame = tk.Frame(main_paned)
        main_paned.add(list_frame, minsize=400)

        self.listbox_left = tk.Listbox(list_frame, selectmode=tk.SINGLE, exportselection=False)
        self.listbox_left.pack(side="left", fill="both", expand=True)
        
        scrollbar = tk.Scrollbar(list_frame, command=self.sync_scroll)
        scrollbar.pack(side="left", fill="y")
        
        self.listbox_right = tk.Listbox(list_frame, selectmode=tk.SINGLE, exportselection=False)
        self.listbox_right.pack(side="left", fill="both", expand=True)

        self.listbox_left.config(yscrollcommand=scrollbar.set)
        self.listbox_right.config(yscrollcommand=scrollbar.set)

        # === 이벤트 바인딩 ===
        # 클릭 시 포커스 잡기
        self.listbox_left.bind("<Button-1>", lambda e: self.set_active_side('left'))
        self.listbox_right.bind("<Button-1>", lambda e: self.set_active_side('right'))
        
        # 선택 변경 시 미리보기
        self.listbox_left.bind("<<ListboxSelect>>", self.on_select_left)
        self.listbox_right.bind("<<ListboxSelect>>", self.on_select_right)
        
        # 더블 클릭 삭제
        self.listbox_left.bind("<Double-Button-1>", lambda e: self.delete_current_selection('left'))
        self.listbox_right.bind("<Double-Button-1>", lambda e: self.delete_current_selection('right'))
        
        # 키보드 이벤트 (전체 창 기준)
        self.root.bind("<Up>", lambda e: self.move_selection(-1))
        self.root.bind("<Down>", lambda e: self.move_selection(1))
        self.root.bind("<Delete>", self.on_delete_or_enter_key)
        self.root.bind("<Return>", self.on_delete_or_enter_key)

        # --- 우측: 미리보기 ---
        preview_frame = tk.Frame(main_paned, bg="#f0f0f0", bd=2, relief=tk.GROOVE)
        main_paned.add(preview_frame, minsize=400)

        tk.Label(preview_frame, text="[이미지 미리보기]", bg="#f0f0f0", font=("Arial", 10, "bold")).pack(pady=5)
        self.lbl_image_preview = tk.Label(preview_frame, text="선택된 이미지 없음", bg="#dddddd", width=50, height=20)
        self.lbl_image_preview.pack(fill="both", expand=True, padx=10, pady=5)

        tk.Label(preview_frame, text="[라벨 내용 미리보기]", bg="#f0f0f0", font=("Arial", 10, "bold")).pack(pady=5)
        self.txt_preview = tk.Text(preview_frame, height=10, bg="white", state="disabled")
        self.txt_preview.pack(fill="x", padx=10, pady=5)

        # === [3] 하단 옵션 ===
        bottom_frame = tk.Frame(root, pady=10)
        bottom_frame.pack(fill="x")
        
        # 바로 삭제 체크박스
        chk_immediate = tk.Checkbutton(bottom_frame, text="⚡ 경고창 없이 바로 삭제 (주의!)", 
                                       variable=self.immediate_delete_var, fg="red", font=("Arial", 10, "bold"))
        chk_immediate.pack(side="top", pady=5)

        btn_check = tk.Button(bottom_frame, text="🔍 파일 일치 검사", command=self.check_consistency, height=2, bg="#c8e6c9")
        btn_check.pack(fill="x", padx=20)

        self.status_lbl = tk.Label(root, text="준비 완료", bd=1, relief=tk.SUNKEN, anchor="w")
        self.status_lbl.pack(side="bottom", fill="x")

    def set_active_side(self, side):
        self.active_side = side
        if side == 'left':
            self.listbox_left.focus_set()
        else:
            self.listbox_right.focus_set()

    def move_selection(self, direction):
        target_listbox = self.listbox_left if self.active_side == 'left' else self.listbox_right
        current_sel = target_listbox.curselection()
        
        if not current_sel:
            new_index = 0
        else:
            new_index = current_sel[0] + direction
        
        if 0 <= new_index < target_listbox.size():
            target_listbox.selection_clear(0, tk.END)
            target_listbox.selection_set(new_index)
            target_listbox.activate(new_index)
            target_listbox.see(new_index)
            if self.active_side == 'left': self.on_select_left(None)
            else: self.on_select_right(None)

    def on_delete_or_enter_key(self, event):
        self.delete_current_selection(self.active_side)

    def sync_scroll(self, *args):
        self.listbox_left.yview(*args)
        self.listbox_right.yview(*args)

    def select_left_dir(self):
        path = filedialog.askdirectory()
        if path:
            self.dir_left = path
            self.lbl_left_path.config(text=path)
            self.refresh_lists()

    def select_right_dir(self):
        path = filedialog.askdirectory()
        if path:
            self.dir_right = path
            self.lbl_right_path.config(text=path)
            self.refresh_lists()

    def refresh_lists(self):
        self.listbox_left.delete(0, tk.END)
        self.file_list_left = []
        if self.dir_left:
            try:
                files = sorted(os.listdir(self.dir_left))
                for f in files:
                    if os.path.isfile(os.path.join(self.dir_left, f)):
                        self.listbox_left.insert(tk.END, f)
                        self.file_list_left.append(f)
            except Exception as e:
                messagebox.showerror("에러", f"폴더 읽기 실패: {e}")

        self.listbox_right.delete(0, tk.END)
        self.file_list_right = []
        if self.dir_right:
            try:
                files = sorted(os.listdir(self.dir_right))
                for f in files:
                    if os.path.isfile(os.path.join(self.dir_right, f)):
                        self.listbox_right.insert(tk.END, f)
                        self.file_list_right.append(f)
            except Exception as e:
                messagebox.showerror("에러", f"폴더 읽기 실패: {e}")
        
        self.status_lbl.config(text=f"로드 완료: 좌측 {len(self.file_list_left)}개 / 우측 {len(self.file_list_right)}개")
        self.clear_preview()

    def clear_preview(self):
        self.lbl_image_preview.config(image='', text="선택된 이미지 없음")
        self.current_preview_image = None
        self.txt_preview.config(state="normal")
        self.txt_preview.delete("1.0", tk.END)
        self.txt_preview.config(state="disabled")

    def load_image_preview(self, filepath):
        try:
            img = Image.open(filepath)
            img.thumbnail((400, 400)) 
            photo = ImageTk.PhotoImage(img)
            self.lbl_image_preview.config(image=photo, text="")
            self.current_preview_image = photo 
        except Exception:
            self.lbl_image_preview.config(image='', text="이미지 로드 실패")

    def load_text_preview(self, filepath):
        content = ""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read(1000)
        except UnicodeDecodeError:
            try:
                with open(filepath, 'r', encoding='cp949') as f:
                    content = f.read(1000)
            except:
                content = "[읽기 실패]"
        except FileNotFoundError:
            content = "[파일 없음]"
            
        self.txt_preview.config(state="normal")
        self.txt_preview.delete("1.0", tk.END)
        self.txt_preview.insert("1.0", content)
        self.txt_preview.config(state="disabled")

    def on_select_left(self, event):
        selection = self.listbox_left.curselection()
        if not selection: return
        filename = self.listbox_left.get(selection[0])
        stem = os.path.splitext(filename)[0]
        
        img_path = os.path.join(self.dir_left, filename)
        self.load_image_preview(img_path)
        if self.dir_right:
            txt_path = os.path.join(self.dir_right, stem + ".txt")
            self.load_text_preview(txt_path)

    def on_select_right(self, event):
        selection = self.listbox_right.curselection()
        if not selection: return
        filename = self.listbox_right.get(selection[0])
        stem = os.path.splitext(filename)[0]

        txt_path = os.path.join(self.dir_right, filename)
        self.load_text_preview(txt_path)
        
        found_img = False
        img_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.webp']
        if self.dir_left:
            for ext in img_extensions:
                img_path = os.path.join(self.dir_left, stem + ext)
                if os.path.exists(img_path):
                    self.load_image_preview(img_path)
                    found_img = True
                    break
        if not found_img:
            self.lbl_image_preview.config(image='', text="[짝이 맞는 이미지가 없습니다]")

    def check_consistency(self):
        if not self.dir_left or not self.dir_right:
            messagebox.showwarning("경고", "폴더를 지정해주세요.")
            return
        left_stems = set(os.path.splitext(f)[0] for f in self.file_list_left)
        right_stems = set(os.path.splitext(f)[0] for f in self.file_list_right)
        common = left_stems & right_stems
        only_left = left_stems - right_stems
        only_right = right_stems - left_stems
        msg = f"✅ 매칭됨: {len(common)}개\n⚠️ 이미지만: {len(only_left)}개\n⚠️ 라벨만: {len(only_right)}개"
        messagebox.showinfo("검사 결과", msg)

    def delete_current_selection(self, source_side):
        # [수정 1] 삭제 전에 현재 위치(Index)를 기억합니다.
        target_listbox = self.listbox_left if source_side == 'left' else self.listbox_right
        sel = target_listbox.curselection()
        
        filename = ""
        current_index = 0
        if sel: 
            current_index = sel[0]
            filename = target_listbox.get(current_index)
            
        if filename:
            # 삭제 함수에 '몇 번째 파일이었는지'와 '어느 쪽인지'를 같이 보냅니다.
            self.delete_pair(filename, current_index, source_side)

    def delete_pair(self, filename, old_index, side):
        target_stem = os.path.splitext(filename)[0]
        files_to_delete = []

        if self.dir_left:
            for f in self.file_list_left:
                if os.path.splitext(f)[0] == target_stem:
                    files_to_delete.append(os.path.join(self.dir_left, f))
        if self.dir_right:
            for f in self.file_list_right:
                if os.path.splitext(f)[0] == target_stem:
                    files_to_delete.append(os.path.join(self.dir_right, f))

        if not files_to_delete: return

        skip_confirm = self.immediate_delete_var.get()
        if not skip_confirm:
            confirm_msg = f"삭제하시겠습니까? (Enter 키로 승인)\n\n" + "\n".join([os.path.basename(p) for p in files_to_delete])
            if not messagebox.askyesno("삭제 확인", confirm_msg):
                return 

        for path in files_to_delete:
            try: os.remove(path)
            except: pass
        
        # 1. 리스트 새로고침 (여기서 선택이 풀림)
        self.refresh_lists()
        
        # [수정 2] 삭제 후 선택 복구 로직 (핵심!)
        target_listbox = self.listbox_left if side == 'left' else self.listbox_right
        list_size = target_listbox.size()

        if list_size > 0:
            # 기존 인덱스가 리스트 범위를 벗어나지 않게 조정 (마지막 파일 지운 경우)
            new_index = old_index
            if new_index >= list_size:
                new_index = list_size - 1
            
            # 2. 강제로 다시 선택하고 포커스 주기
            target_listbox.selection_set(new_index)
            target_listbox.activate(new_index)
            target_listbox.see(new_index)
            target_listbox.focus_set()
            
            # 3. 미리보기 화면도 강제 업데이트
            if side == 'left':
                self.on_select_left(None)
            else:
                self.on_select_right(None)
        
        self.status_lbl.config(text=f"🗑️ 삭제 완료: {target_stem}")

if __name__ == "__main__":
    root = tk.Tk()
    app = DualFileCleanerApp(root)
    root.mainloop()