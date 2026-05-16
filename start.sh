#!/usr/bin/env bash
# One-command VPS setup. From repo root: chmod +x start.sh && ./start.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}>>>${NC} $*"; }
warn() { echo -e "${YELLOW}>>>${NC} $*"; }
die() { echo -e "${RED}>>>${NC} $*" >&2; exit 1; }

_sudo() {
  if [[ "${EUID:-0}" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "Need root or sudo to install Docker."
  fi
}

ensure_docker() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    return
  fi
  warn "Docker not found — installing (Ubuntu/Debian via get.docker.com)..."
  _sudo apt-get update -qq
  _sudo apt-get install -y ca-certificates curl
  curl -fsSL https://get.docker.com | _sudo sh
  _sudo systemctl enable --now docker 2>/dev/null || true
  if ! docker compose version >/dev/null 2>&1; then
    die "Docker installed but 'docker compose' missing. Re-login or: sudo usermod -aG docker \$USER"
  fi
  info "Docker installed."
}

read_env_value() {
  local key="$1"
  local line
  line="$(grep -E "^${key}=" .env 2>/dev/null | head -1 || true)"
  [[ -n "$line" ]] || return 1
  line="${line#*=}"
  line="${line%\"}"
  line="${line#\"}"
  line="${line%\'}"
  line="${line#\'}"
  printf '%s' "$line"
}

ensure_env_file() {
  if [[ -f .env ]]; then
    return
  fi
  if [[ ! -f .env.docker.example ]]; then
    die "Missing .env.docker.example"
  fi
  cp .env.docker.example .env
  warn "Created .env from template."
  warn "Open .env and set DEEPSEEK_API_KEY=sk-... then run: ./start.sh"
  exit 0
}

ensure_auth_token() {
  local token
  token="$(read_env_value ANTHROPIC_AUTH_TOKEN || true)"
  if [[ -z "$token" || "$token" == "change-me" || "$token" == "freecc" ]]; then
    if command -v openssl >/dev/null 2>&1; then
      token="$(openssl rand -hex 24)"
    else
      token="fcc-$(date +%s)-$RANDOM"
    fi
    if grep -q '^ANTHROPIC_AUTH_TOKEN=' .env; then
      sed -i.bak "s/^ANTHROPIC_AUTH_TOKEN=.*/ANTHROPIC_AUTH_TOKEN=${token}/" .env
      rm -f .env.bak
    else
      echo "ANTHROPIC_AUTH_TOKEN=${token}" >>.env
    fi
    info "Generated ANTHROPIC_AUTH_TOKEN (save for Claude Code on your PC):"
    echo "    ${token}"
  fi
}

validate_env() {
  local key
  key="$(read_env_value DEEPSEEK_API_KEY || true)"
  if [[ -z "$key" || "$key" == "sk-your-key-here" ]]; then
    die "Set DEEPSEEK_API_KEY in .env (get key from https://platform.deepseek.com/) then run ./start.sh again"
  fi
}

public_ip() {
  curl -fsS --max-time 3 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null \
    || curl -fsS --max-time 3 ifconfig.me 2>/dev/null \
    || true
}

main() {
  info "Free Claude Code — VPS start"
  ensure_docker
  ensure_env_file
  validate_env
  ensure_auth_token

  info "Building and starting container (first time may take a few minutes)..."
  if docker info >/dev/null 2>&1; then
    docker compose up -d --build
  else
    warn "Using sudo for Docker (log out/in later to skip sudo)."
    _sudo docker compose up -d --build
  fi

  local ip port token
  ip="$(public_ip)"
  port="$(read_env_value PORT || echo 8082)"
  token="$(read_env_value ANTHROPIC_AUTH_TOKEN || true)"

  echo ""
  info "Proxy is running."
  if [[ -n "$ip" ]]; then
    echo "    Health:  http://${ip}:${port}/health"
    echo "    Admin:   http://${ip}:${port}/admin"
    echo "    API:     http://${ip}:${port}/v1/messages"
  else
    echo "    Health:  http://<VPS-IP>:${port}/health"
    echo "    Admin:   http://<VPS-IP>:${port}/admin"
  fi
  echo ""
  echo "On your PC (PowerShell), before Claude Code:"
  if [[ -n "$ip" ]]; then
    echo "    \$env:ANTHROPIC_BASE_URL = \"http://${ip}:${port}\""
  else
    echo "    \$env:ANTHROPIC_BASE_URL = \"http://<VPS-IP>:${port}\""
  fi
  echo "    \$env:ANTHROPIC_AUTH_TOKEN = \"${token}\""
  echo ""
  echo "Logs:  docker compose logs -f"
  echo "Stop:  docker compose down"
}

main "$@"
