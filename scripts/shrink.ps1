# image-shrink: 大图 → ≤2000px JPEG 小副本（Windows，零依赖：System.Drawing）
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File shrink.ps1 -Path "D:\shot.png" [-MaxDim 2000] [-Quality 85] [-Out 指定输出]
param(
  [Parameter(Mandatory=$true)][string]$Path,
  [int]$MaxDim = 2000,
  [int]$Quality = 85,
  [string]$Out = ''
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$src = (Resolve-Path -LiteralPath $Path).Path
if (-not $Out) {
  $Out = [IO.Path]::Combine([IO.Path]::GetDirectoryName($src),
                            [IO.Path]::GetFileNameWithoutExtension($src) + '.small.jpg')
}

$img = [System.Drawing.Image]::FromFile($src)
try {
  $w = $img.Width; $h = $img.Height
  $scale = [Math]::Min(1.0, $MaxDim / [Math]::Max($w, $h))
  $nw = [int][Math]::Max(1, [Math]::Round($w * $scale))
  $nh = [int][Math]::Max(1, [Math]::Round($h * $scale))
  $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  try {
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.Clear([System.Drawing.Color]::White)   # JPEG 无透明通道：先铺白底再画
    $g.DrawImage($img, 0, 0, $nw, $nh)
  } finally { $g.Dispose() }
  $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
           Where-Object { $_.MimeType -eq 'image/jpeg' }
  $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
  try { $bmp.Save($Out, $codec, $ep) } finally { $ep.Dispose() }
  $bmp.Dispose()
} finally { $img.Dispose() }

$origLen = (Get-Item -LiteralPath $src).Length
$newLen  = (Get-Item -LiteralPath $Out).Length
if ($newLen -ge $origLen) {
  Remove-Item -LiteralPath $Out -Force
  Write-Output ("SKIP 压不小，保留原图: {0} ({1:N0} bytes)" -f $src, $origLen)
  exit 0
}
Write-Output ("OK {0}" -f $Out)
Write-Output ("   {0}x{1} {2:N0}KB -> {3}x{4} {5:N0}KB" -f $w, $h, ($origLen / 1KB), $nw, $nh, ($newLen / 1KB))
