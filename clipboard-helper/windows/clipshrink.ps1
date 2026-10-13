# clipshrink.ps1 — 剪贴板缩图助手（Windows，零依赖）
# 作用：监视剪贴板；只要有图片（截图、"复制图片"）进来，且长边 > MaxDim，
#       就自动替换成 ≤MaxDim 的 JPEG 小副本——任何程序（包括 Codex）粘贴到的都是小图。
# 用法：
#   powershell -NoProfile -STA -ExecutionPolicy Bypass -File clipshrink.ps1            # 常驻
#   powershell -NoProfile -STA -ExecutionPolicy Bypass -File clipshrink.ps1 -Once      # 处理当前剪贴板一次（测试用）
# 注意：本脚本需要 STA（Windows PowerShell 5.1 控制台默认 STA；用 powershell.exe 运行即可）。
param(
  [int]$MaxDim = 1920,
  [int]$Quality = 85,
  [int]$PollMs = 400,
  [switch]$Once
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -Namespace ClipNative -Name Seq -MemberDefinition '
  [DllImport("user32.dll")] public static extern uint GetClipboardSequenceNumber();
'

function Get-ClipBitmap {
  if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) { return $null }
  return [System.Windows.Forms.Clipboard]::GetImage()
}

function New-SmallBitmap($img) {
  $w = $img.Width; $h = $img.Height
  if ($w -le $MaxDim -and $h -le $MaxDim) { return $null }   # 没超上限，不折腾
  $scale = $MaxDim / [Math]::Max($w, $h)
  $nw = [int][Math]::Max(1, [Math]::Round($w * $scale))
  $nh = [int][Math]::Max(1, [Math]::Round($h * $scale))
  $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  try {
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.Clear([System.Drawing.Color]::White)
    $g.DrawImage($img, 0, 0, $nw, $nh)
  } finally { $g.Dispose() }
  return $bmp
}

function Invoke-ShrinkOnce {
  # 注意：本函数只用 Write-Host 报日志（输出流只留给返回值=剪贴板序号，防止污染序号比较）
  $img = Get-ClipBitmap
  if (-not $img) { Write-Host "剪贴板无图片，跳过"; return $LastSeq }
  try {
    $small = New-SmallBitmap $img
    if (-not $small) {
      Write-Host ("{0}x{1} 未超上限（{2}px），保持原样" -f $img.Width, $img.Height, $MaxDim)
      return $LastSeq
    }
    try {
      [System.Windows.Forms.Clipboard]::SetImage($small)
      Write-Host ("已缩图: {0}x{1} -> {2}x{3}" -f $img.Width, $img.Height, $small.Width, $small.Height)
      return [ClipNative.Seq]::GetClipboardSequenceNumber()
    } finally { $small.Dispose() }
  } finally { $img.Dispose() }
}

$script:LastSeq = [ClipNative.Seq]::GetClipboardSequenceNumber()
if ($Once) { [void](Invoke-ShrinkOnce); exit 0 }

Write-Host ("clipshrink 常驻中（最长边 {0}px，JPEG q{1}，轮询 {2}ms）。Ctrl+C 退出。" -f $MaxDim, $Quality, $PollMs)
while ($true) {
  Start-Sleep -Milliseconds $PollMs
  $seq = [ClipNative.Seq]::GetClipboardSequenceNumber()
  if ($seq -eq $LastSeq) { continue }
  $LastSeq = $seq
  try { $LastSeq = Invoke-ShrinkOnce } catch { Write-Host ("处理失败: " + $_.Exception.Message) }
}
