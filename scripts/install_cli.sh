#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="${1:-${XIAOBA_BIN_DIR:-$HOME/.local/bin}}"

mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
TARGET="$TARGET_DIR/xiaoba"
QUOTED_ROOT="${(q)ROOT}"

cat >"$TARGET" <<WRAPPER
#!/usr/bin/env zsh
set -euo pipefail
ROOT=$QUOTED_ROOT
exec "\$ROOT/scripts/xiaoba" "\$@"
WRAPPER

chmod +x "$TARGET"
echo "已安装命令：$TARGET"

if [[ ":$PATH:" != *":$TARGET_DIR:"* ]]; then
  echo "如需直接输入 xiaoba，请把下面一行加入 ~/.zshrc："
  echo "  export PATH=\"$TARGET_DIR:\$PATH\""
fi
