#!/usr/bin/env bash
# 安装 image-shrink 技能到本机（macOS/Linux 客户机）
#   1) 技能本体      -> ~/.codex/skills/image-shrink（含 scripts/ 与 agents/）
#   2) 常驻强制指令  -> ~/.codex/AGENTS.md 的标记块（幂等；改前自动备份）
# 用法（在仓库根目录运行）：bash install/install.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"
[ -f "$root/SKILL.md" ] || { echo "请在仓库根目录运行（未找到 SKILL.md）：$root" >&2; exit 2; }

# ── 1. 技能本体 ──
dest="$HOME/.codex/skills/image-shrink"
mkdir -p "$dest"
cp -R "$root/SKILL.md" "$root/scripts" "$root/agents" "$dest/"
echo "技能已安装: $dest"

# ── 2. 常驻指令 ──
agents="$HOME/.codex/AGENTS.md"
mkdir -p "$(dirname "$agents")"
if [ -f "$agents" ]; then
  cp "$agents" "$agents.bak-$(date +%Y%m%d-%H%M%S)"
else
  printf '# AGENTS.md\n' > "$agents"
fi
block='<!-- image-shrink:begin（由 codex-image-shrink 安装器写入，勿删） -->
## 图片读取规范（强制）
任何情况下要查看/读取图片文件（view_image、读取 PNG/JPEG/WEBP/截图等），**必须先运行缩图脚本，只读取产出的小副本** `<原名>.small.jpg`；除非用户明确要求全分辨率：
- Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\image-shrink\scripts\shrink.ps1" -Path "<原图>"`
- macOS/Linux: `bash "$HOME/.codex/skills/image-shrink/scripts/shrink.sh" "<原图>"`
<!-- image-shrink:end -->'
if grep -q 'image-shrink:begin' "$agents" 2>/dev/null; then
  BLOCK="$block" perl -0777 -i -pe 's/<!-- image-shrink:begin.*?<!-- image-shrink:end -->/$ENV{BLOCK}/s' "$agents"
else
  printf '\n%s\n' "$block" >> "$agents"
fi
echo "常驻指令已写入: $agents"

echo
echo "完成。重启 Codex 生效。"
