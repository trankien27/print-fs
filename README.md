# 🖨️ PhotoBooth Print Tool

Công cụ nhỏ viết bằng **PowerShell + WinForms** để:
- Xem danh sách transaction trong SQLite database.
- Tìm kiếm theo TransactionId.
- Lọc theo LayoutId.
- Gửi lệnh in qua API local (`http://localhost:8088/api/print/printimage`).

---

## 🚀 Cách chạy nhanh

Mở **PowerShell** (phiên bản 5.1 trở lên, chạy ở chế độ Administrator nếu cần) và chạy:

```powershell
iex (iwr -useb "https://raw.githubusercontent.com/trankien27/print-fs/main/print.ps1")
