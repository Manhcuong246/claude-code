# Triển khai cá nhân (Docker / AWS)

Thư mục này không phải bản phân phối chính thức; dùng để tự host proxy trên VPS.

## Chuẩn bị trên AWS (EC2)

1. **AMI**: Ubuntu 22.04/24.04 (hoặc Amazon Linux 2023).
2. **Security group**: mở TCP **8082** (hoặc cổng bạn map ở `PUBLIC_PORT`) — chỉ nên whitelist IP nhà bạn.
3. **Cài Docker** (ví dụ Ubuntu):

   ```bash
   sudo apt update && sudo apt install -y docker.io docker-compose-v2
   sudo usermod -aG docker "$USER"
   ```

   Đăng xuất/đăng nhập lại để dùng `docker` không cần `sudo`.

## Đưa code lên VPS

- `git clone` repo lên máy, hoặc `scp` / zip toàn bộ project (có `pyproject.toml`, `uv.lock`, `api/`, …).

## Chạy container

Trên máy có full source:

```bash
cd /path/to/free-claude-code
cp deploy/aws.env.example deploy/aws.env
nano deploy/aws.env   # điền API key, ANTHROPIC_AUTH_TOKEN, MODEL, v.v.
docker compose -f deploy/docker-compose.yml up -d
docker compose -f deploy/docker-compose.yml logs -f
```

Kiểm tra: `curl -sS http://127.0.0.1:8082/health` trên VPS (hoặc `http://<IP công cộng>:8082/health`).

## Máy local dùng proxy

Trỏ Claude Code tới VPS (thay `YOUR_VPS_IP`):

```bash
export ANTHROPIC_BASE_URL=http://YOUR_VPS_IP:8082
export ANTHROPIC_AUTH_TOKEN=<giống giá trị trong deploy/aws.env>
```

Giữ `ANTHROPIC_AUTH_TOKEN` trùng với server: đây là khóa bảo vệ endpoint `/v1/...`.

## Admin web

- Với `FCC_ADMIN_ALLOW_REMOTE=true`, mở `http://YOUR_VPS_IP:8082/admin`.
- **Rủi ro**: ai đến được cổng này có thể đổi cấu hình. Hãy hạn chế SG/VPN và đặt mật khẩu token mạnh.
- Cấu hình lưu trong volume Docker (`fcc-data` → `/data/.config/free-claude-code/.env`).

## HTTPS (khuyến nghị)

Đặt **Caddy** hoặc **Nginx** reverse proxy phía trước (Let's Encrypt), rồi dùng `https://proxy.example.com` làm `ANTHROPIC_BASE_URL`.

## Ghi chú

- Image build cần **Python 3.14** (base image `ghcr.io/astral-sh/uv:python3.14-bookworm-slim`).
- Đổi cổng host: `PUBLIC_PORT=8443 docker compose -f deploy/docker-compose.yml up -d` (trong container vẫn nên `PORT=8082` trừ khi bạn sửa `ports` và healthcheck).
