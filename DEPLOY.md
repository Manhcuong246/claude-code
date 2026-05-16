# Chạy trên VPS (một lệnh)

```bash
git clone https://github.com/Manhcuong246/claude-code.git
cd claude-code
chmod +x start.sh
./start.sh
```

Lần đầu script tạo `.env` — mở file, dán **một** dòng `DEEPSEEK_API_KEY=sk-...`, chạy lại `./start.sh`.

Script tự: cài Docker (nếu thiếu), build image, chạy container, tạo `ANTHROPIC_AUTH_TOKEN` ngẫu nhiên và in ra màn hình.

Mở Security Group AWS: TCP **8082** (chỉ IP nhà bạn nếu có thể).
