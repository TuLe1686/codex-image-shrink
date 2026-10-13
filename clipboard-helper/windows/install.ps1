# 把剪贴板缩图助手装成开机自启（Windows，隐藏窗口，无控制台闪烁）
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 [-MaxDim 1920]
param([int]$MaxDim = 1920)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $env:LOCALAPPDATA 'codex-clipshrink'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item (Join-Path $here 'clipshrink.ps1') $dest -Force

# VBS 启动器：完全隐藏窗口地拉起常驻脚本
$vbs = Join-Path $dest 'launch.vbs'
$vbsContent = @"
Set sh = CreateObject("WScript.Shell")
sh.Run "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$dest\clipshrink.ps1"" -MaxDim $MaxDim", 0, False
"@
Set-Content -Path $vbs -Value $vbsContent -Encoding ASCII

# 开机自启：Startup 文件夹快捷方式
$startup = [Environment]::GetFolderPath('Startup')
$lnk = Join-Path $startup 'codex-clipshrink.lnk'
$ws = New-Object -ComObject WScript.Shell
$s = $ws.CreateShortcut($lnk)
$s.TargetPath = 'wscript.exe'
$s.Arguments = '"' + $vbs + '"'
$s.WorkingDirectory = $dest
$s.Description = 'codex-clipshrink: 剪贴板图片自动缩为 ≤' + $MaxDim + 'px 小副本'
$s.Save()

Write-Output "已安装: $dest"
Write-Output "开机自启: $lnk"
Write-Output "立即启动: wscript `"$vbs`""
Write-Output "卸载: 删除上述快捷方式与文件夹，并结束 powershell 进程中的 clipshrink.ps1"
