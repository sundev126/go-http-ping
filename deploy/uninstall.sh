#!/usr/bin/env bash

set -Eeuo pipefail

readonly SERVICE_NAME="go-http-ping"
readonly SERVICE_USER="go-http-ping"
readonly SERVICE_GROUP="go-http-ping"
readonly INSTALL_PATH="/usr/local/bin/go-http-ping"
readonly SERVICE_PATH="/etc/systemd/system/go-http-ping.service"

log() {
  printf '[go-http-ping] %s\n' "$*"
}

fail() {
  printf '[go-http-ping] 错误: %s\n' "$*" >&2
  exit 1
}

if [[ "$(uname -s)" != "Linux" ]]; then
  fail "该卸载脚本仅支持 Linux"
fi

if [[ "${EUID}" -ne 0 ]]; then
  fail "请使用 root 权限运行，例如: curl -fsSL https://raw.githubusercontent.com/sundev126/go-http-ping/main/deploy/uninstall.sh | sudo bash"
fi

if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet "${SERVICE_NAME}.service"; then
    log "停止服务"
    systemctl stop "${SERVICE_NAME}.service"
  fi

  if systemctl is-enabled --quiet "${SERVICE_NAME}.service" 2>/dev/null; then
    log "禁用服务"
    systemctl disable "${SERVICE_NAME}.service"
  fi
fi

if [[ -f "${SERVICE_PATH}" ]]; then
  log "删除 systemd 服务"
  rm -f -- "${SERVICE_PATH}"
fi

if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload
  systemctl reset-failed "${SERVICE_NAME}.service" 2>/dev/null || true
fi

if [[ -f "${INSTALL_PATH}" ]]; then
  log "删除程序 ${INSTALL_PATH}"
  rm -f -- "${INSTALL_PATH}"
fi

if id -u "${SERVICE_USER}" >/dev/null 2>&1; then
  log "删除系统用户 ${SERVICE_USER}"
  userdel "${SERVICE_USER}"
fi

if getent group "${SERVICE_GROUP}" >/dev/null 2>&1; then
  log "删除系统用户组 ${SERVICE_GROUP}"
  groupdel "${SERVICE_GROUP}"
fi

log "卸载完成"
