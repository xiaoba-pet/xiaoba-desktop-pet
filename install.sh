#!/usr/bin/env zsh
set -euo pipefail

DEFAULT_REPO_URL="https://github.com/xiaoba-pet/xiaoba-desktop-pet.git"
REPO_URL="${XIAOBA_REPO_URL:-$DEFAULT_REPO_URL}"
REF="${XIAOBA_REF:-main}"
INSTALL_DIR="${XIAOBA_INSTALL_DIR:-$HOME/.local/share/xiaoba-desktop-pet}"
BIN_DIR="${XIAOBA_BIN_DIR:-$HOME/.local/bin}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "小八桌面宠物目前只支持 macOS。" >&2
  exit 2
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/xiaoba-desktop-pet.XXXXXX")"
cleanup() {
  if [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}
trap cleanup EXIT

echo "正在把小八带到你的电脑……"
git -c init.templateDir= init -q "$TEMP_DIR"
git -C "$TEMP_DIR" remote add origin "$REPO_URL"
git -C "$TEMP_DIR" fetch --depth 1 origin "$REF"
git -C "$TEMP_DIR" checkout -q --detach FETCH_HEAD

mkdir -p "${INSTALL_DIR:h}"
if [[ -d "$INSTALL_DIR" ]]; then
  if [[ -x "$INSTALL_DIR/scripts/xiaoba" ]]; then
    "$INSTALL_DIR/scripts/xiaoba" stop >/dev/null 2>&1 || true
  fi
  BACKUP_DIR="$INSTALL_DIR.backup.$(date +%Y%m%d%H%M%S)"
  mv "$INSTALL_DIR" "$BACKUP_DIR"
  echo "旧版本已备份到：$BACKUP_DIR"
fi

mv "$TEMP_DIR" "$INSTALL_DIR"
TEMP_DIR=""
"$INSTALL_DIR/scripts/install_cli.sh" "$BIN_DIR"

echo
echo "小八安装完成。启动命令："
echo "  \"$BIN_DIR/xiaoba\" start"
