# 安装 image-shrink 技能到本机（Windows 客户机）
#   1) 技能本体      -> ~/.codex/skills/image-shrink（含 scripts/ 与 agents/）
#   2) 常驻强制指令  -> ~/.codex/AGENTS.md 的标记块（幂等；改前自动备份）
# 用法（在仓库根目录运行）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File install\install.ps1
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
if (-not (Test-Path (Join-Path $root 'SKILL.md'))) { throw "请在仓库根目录运行（未找到 SKILL.md）：$root" }

# ── 1. 技能本体 ──
$dest = Join-Path $HOME '.codex\skills\image-shrink'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
foreach ($item in 'SKILL.md', 'scripts', 'agents') {
  Copy-Item -Recurse -Force (Join-Path $root $item) $dest
}
Write-Output "技能已安装: $dest"

# ── 2. 常驻指令（~/.codex/AGENTS.md，标记块幂等替换） ──
$agentsFile = Join-Path $HOME '.codex\AGENTS.md'
New-Item -ItemType Directory -Force -Path (Split-Path $agentsFile) | Out-Null
if (Test-Path $agentsFile) {
  Copy-Item $agentsFile ('{0}.bak-{1}' -f $agentsFile, (Get-Date -Format yyyyMMdd-HHmmss)) -Force
} else {
  Set-Content -Path $agentsFile -Value "# AGENTS.md`n" -Encoding UTF8
}
$block = @'
<!-- image-shrink:begin（由 codex-image-shrink 安装器写入，勿删） -->
## 图片读取规范（强制）
任何情况下要查看/读取图片文件（view_image、读取 PNG/JPEG/WEBP/截图等），**必须先运行缩图脚本，只读取产出的小副本** `<原名>.small.jpg`；除非用户明确要求全分辨率：
- Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\skills\image-shrink\scripts\shrink.ps1" -Path "<原图>"`
- macOS/Linux: `bash "$HOME/.codex/skills/image-shrink/scripts/shrink.sh" "<原图>"`
<!-- image-shrink:end -->
'@
$txt = Get-Content -Raw -Encoding UTF8 $agentsFile
if ($txt -match '(?s)<!-- image-shrink:begin.*?<!-- image-shrink:end -->') {
  $replacement = $block.TrimEnd()
  $txt = [regex]::Replace($txt, '(?s)<!-- image-shrink:begin.*?<!-- image-shrink:end -->', { param($m) $replacement })
} else {
  $txt = $txt.TrimEnd() + "`n`n" + $block.TrimEnd() + "`n"
}
Set-Content -Path $agentsFile -Value $txt -Encoding UTF8 -NoNewline
Write-Output "常驻指令已写入: $agentsFile"

Write-Output ''
Write-Output '完成。重启 Codex 生效；验证：对话里输入 $ 应能看到 image-shrink。'
