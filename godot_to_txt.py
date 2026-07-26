import os
import shutil
import tkinter as tk
from tkinter import filedialog, messagebox

class GodotToTxtTool:
    def __init__(self, root):
        self.root = root
        self.root.title("Tool Chuyển Đổi Godot (.tscn, .gd) sang .txt")
        self.root.geometry("550x350")
        self.root.configure(padx=20, pady=20)
        
        self.input_files = []
        
        tk.Label(root, text="CÔNG CỤ ĐỔI FILE GODOT SANG TXT", font=("Arial", 12, "bold"), fg="#D32F2F").pack(pady=(0, 15))
        
        # --- KHUNG 1: CHỌN NGUỒN ĐẦU VÀO ---
        frame_input = tk.LabelFrame(root, text=" 1. Chọn Nguồn Đầu Vào ", font=("Arial", 10, "bold"), fg="blue", padx=10, pady=10)
        frame_input.pack(fill=tk.X, pady=5)
        
        btn_frame = tk.Frame(frame_input)
        btn_frame.pack(fill=tk.X)
        
        # Cho phép chọn nhiều file hoặc cả 1 thư mục
        btn_files = tk.Button(btn_frame, text="📄 Chọn nhiều File lẻ", font=("Arial", 10), command=self.select_files, bg="#2196F3", fg="white")
        btn_files.pack(side=tk.LEFT, padx=(0, 10))
        
        btn_folder = tk.Button(btn_frame, text="📁 Quét cả Thư mục", font=("Arial", 10), command=self.select_folder, bg="#009688", fg="white")
        btn_folder.pack(side=tk.LEFT)
        
        self.lbl_input = tk.Label(frame_input, text="Chưa chọn file nào...", fg="gray", font=("Arial", 10, "italic"))
        self.lbl_input.pack(anchor="w", pady=(10, 0))
        
        # --- KHUNG 2: CHẠY & XUẤT ---
        frame_run = tk.Frame(root)
        frame_run.pack(fill=tk.BOTH, expand=True, pady=15)
        
        self.btn_convert = tk.Button(frame_run, text="🚀 CHỌN NƠI LƯU & XUẤT FILE", font=("Arial", 12, "bold"), bg="#4CAF50", fg="white", command=self.convert_files, state=tk.DISABLED, pady=10)
        self.btn_convert.pack(fill=tk.X)
        
        self.lbl_status = tk.Label(frame_run, text="Sẵn sàng...", font=("Arial", 10, "bold"), fg="green")
        self.lbl_status.pack(pady=10)

    def select_files(self):
        files = filedialog.askopenfilenames(
            title="Chọn file Godot cần chuyển",
            filetypes=[("Godot Files", "*.tscn *.gd"), ("All files", "*.*")]
        )
        if files:
            self.input_files = list(files)
            self.lbl_input.config(text=f"Đã chọn {len(self.input_files)} file riêng lẻ.", fg="black")
            self.btn_convert.config(state=tk.NORMAL)

    def select_folder(self):
        folder = filedialog.askdirectory(title="Chọn thư mục chứa dự án Godot")
        if folder:
            self.input_files = []
            # Quét đệ quy (quét luôn cả các thư mục con bên trong)
            for root_dir, _, files in os.walk(folder):
                for f in files:
                    if f.endswith('.tscn') or f.endswith('.gd'):
                        self.input_files.append(os.path.join(root_dir, f))
            
            if self.input_files:
                self.lbl_input.config(text=f"Đã quét thấy {len(self.input_files)} file (.tscn, .gd).", fg="black")
                self.btn_convert.config(state=tk.NORMAL)
            else:
                self.lbl_input.config(text="Thư mục này không có file .tscn hoặc .gd nào!", fg="red")
                self.btn_convert.config(state=tk.DISABLED)

    def convert_files(self):
        if not self.input_files:
            messagebox.showerror("Lỗi", "Vui lòng chọn file hoặc thư mục trước!")
            return
            
        # Hộp thoại hỏi thư mục mới để lưu file
        out_path = filedialog.askdirectory(title="Chọn thư mục MỚI để lưu các file .txt")
        if not out_path:
            return 
            
        self.lbl_status.config(text="Đang xử lý...", fg="blue")
        self.root.update()
        
        success_count = 0
        for path in self.input_files:
            try:
                base_name = os.path.basename(path)
                name_without_ext, ext = os.path.splitext(base_name)
                
                # Đổi tên để tránh trùng lặp: (Player.gd -> Player_gd.txt)
                ext_clean = ext.replace('.', '')
                new_filename = f"{name_without_ext}_{ext_clean}.txt"
                
                new_filepath = os.path.join(out_path, new_filename)
                
                # Dùng shutil copy file để giữ nguyên bảng mã UTF-8 gốc cực kỳ an toàn
                shutil.copyfile(path, new_filepath)
                success_count += 1
            except Exception as e:
                print(f"Lỗi khi xử lý file {path}: {e}")
                
        self.lbl_status.config(text=f"Hoàn tất! Đã chuyển {success_count} file sang .txt", fg="green")
        messagebox.showinfo("Thành công", f"Đã chuyển đổi {success_count} file thành công!\n\nToàn bộ file .txt được lưu tại:\n{out_path}")

if __name__ == "__main__":
    root = tk.Tk()
    app = GodotToTxtTool(root)
    root.mainloop()