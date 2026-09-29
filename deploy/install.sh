#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPOSITORY="sundev126/go-http-ping"
readonly SERVICE_NAME="go-http-ping"
readonly SERVICE_USER="go-http-ping"
readonly BINARY_NAME="go-http-ping-linux-amd64"
readonly INSTALL_DIRECTORY="/opt/go-http-ping"
readonly INSTALL_PATH="${INSTALL_DIRECTORY}/go-http-ping"
readonly LEGACY_INSTALL_PATH="/usr/local/bin/go-http-ping"
readonly SERVICE_PATH="/etc/systemd/system/go-http-ping.service"
readonly VERSION="${VERSION:-latest}"

log() {
  printf '[go-http-ping] %s\n' "$*"
}

fail() {
  printf '[go-http-ping] 错误: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "缺少必要命令: $1"
}

if [[ "$(uname -s)" != "Linux" ]]; then
  fail "该安装脚本仅支持 Linux"
fi

case "$(uname -m)" in
  x86_64 | amd64) ;;
  *) fail "仅支持 64 位 x86 架构 (amd64)" ;;
esac

if [[ "${EUID}" -ne 0 ]]; then
  fail "请使用 root 权限运行，例如: curl -fsSL https://raw.githubusercontent.com/${REPOSITORY}/main/deploy/install.sh | sudo bash"
fi

require_command curl
require_command install
require_command systemctl
require_command useradd

if [[ "${VERSION}" == "latest" ]]; then
  download_url="https://github.com/${REPOSITORY}/releases/latest/download/${BINARY_NAME}"
else
  download_url="https://github.com/${REPOSITORY}/releases/download/${VERSION}/${BINARY_NAME}"
fi

temporary_directory="$(mktemp -d)"
trap 'rm -rf -- "${temporary_directory}"' EXIT
download_path="${temporary_directory}/${BINARY_NAME}"

log "下载 ${VERSION} 版本"
curl --fail --location --show-error --silent \
  --output "${download_path}" \
  "${download_url}"

if ! id -u "${SERVICE_USER}" >/dev/null 2>&1; then
  nologin_shell="$(command -v nologin || true)"
  if [[ -z "${nologin_shell}" ]]; then
    nologin_shell="/usr/sbin/nologin"
  fi

  log "创建系统用户 ${SERVICE_USER}"
  useradd --system --user-group --no-create-home --shell "${nologin_shell}" "${SERVICE_USER}"
fi

if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
  log "停止现有服务"
  systemctl stop "${SERVICE_NAME}.service"
fi

log "安装程序到 ${INSTALL_PATH}"
install -d -m 0755 "${INSTALL_DIRECTORY}"
install -m 0755 "${download_path}" "${INSTALL_PATH}"

if [[ -f "${LEGACY_INSTALL_PATH}" ]]; then
  log "删除旧版本程序 ${LEGACY_INSTALL_PATH}"
  rm -f -- "${LEGACY_INSTALL_PATH}"
fi

log "安装 systemd 服务"
install -m 0644 /dev/stdin "${SERVICE_PATH}" <<'EOF'
[Unit]
Description=Go HTTP Ping Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=go-http-ping
Group=go-http-ping
ExecStart=/opt/go-http-ping/go-http-ping -ip 0.0.0.0 -port 47986
Restart=on-failure
RestartSec=3s
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}.service"

log "安装完成"
systemctl --no-pager --full status "${SERVICE_NAME}.service" || true
log "访问地址: http://127.0.0.1:47986/ping"
