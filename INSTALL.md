# 安装指南（可整包交给 AI 代理执行）

本文件写给"拿到仓库后负责安装的 AI 代理（Codex/Cursor 等）"或工程师。
**把仓库链接发给 AI，让它阅读并执行本文件即可**；装完必须跑最后的「验证」小节并汇报结果。

两个组件，互不强依赖，建议都装：

| 组件 | 治什么 | 适用 |
|---|---|---|
| **A. Codex 技能 `image-shrink`** | agent 要"看"图片文件（view_image / 读文件）时，先缩成小副本再读 | Windows / macOS 都可 |
| **B. 剪贴板助手 `clipshrink`** | 用户**直接粘贴**截图进对话的路径——图片一进剪贴板就换成小副本 | Windows / macOS 都可 |

先判断操作系统，再走对应小节。

---

## Windows 机器

### A. 装技能（含"读图先缩"常驻强制指令）

前提：仓库已克隆/下载到本地（例如 `%USERPROFILE%\codex-image-shrink`）。

```powershell
cd <仓库目录>
powershell -NoProfile -ExecutionPolicy Bypass -File install\install.ps1
```

- 预期输出包含：`技能已安装: C:\Users\<用户>\.codex\skills\image-shrink` 和 `常驻指令已写入: C:\Users\<用户>\.codex\AGENTS.md`；
- 幂等，可重复运行；会自动备份 `AGENTS.md` 后再写入标记块。

验证（AI 可自动执行）：

```powershell
Test-Path "$HOME\.codex\skills\image-shrink\SKILL.md"                     # True
Select-String 'image-shrink:begin' "$HOME\.codex\AGENTS.md" | Measure-Object | % Count  # 1
```

### B. 装剪贴板助手（开机自启）

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File clipboard-helper\windows\install.ps1
wscript "$env:LOCALAPPDATA\codex-clipshrink\launch.vbs"   # 立即启动（以后开机自动）
```

验证（AI 可自动执行，端到端）：

```powershell
# 1) 造一张 2400x1500 的测试图并放上剪贴板
powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms;Add-Type -AssemblyName System.Drawing;$b=New-Object System.Drawing.Bitmap(2400,1500);[System.Windows.Forms.Clipboard]::SetImage($b);$b.Dispose()"
# 2) 单次处理
powershell -NoProfile -STA -ExecutionPolicy Bypass -File clipboard-helper\windows\clipshrink.ps1 -Once
# 3) 读回尺寸，应为 2000x1250
powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms;$c=[System.Windows.Forms.Clipboard]::GetImage();'{0}x{1}' -f $c.Width,$c.Height;$c.Dispose()"
```

### 最后

重启 Codex（技能列表刷新）。可选验证：让 Codex "看一下 <某张 >2MB 的图片>"，观察它是否先运行缩图脚本、只读小副本。

---

## macOS 机器

### A. 装技能（同 Windows 逻辑）

```bash
cd <仓库目录>
bash install/install.sh
```

验证：`~/.codex/skills/image-shrink/SKILL.md` 存在；`~/.codex/AGENTS.md` 中 `image-shrink:begin` 标记出现 1 次。

### B. 装剪贴板助手（Hammerspoon 方案）

```bash
brew install --cask hammerspoon          # 无 Homebrew 则官网下载 dmg 拖入 Applications
mkdir -p ~/.hammerspoon
cp clipboard-helper/macos/hammerspoon-clipshrink.lua ~/.hammerspoon/clipshrink.lua
grep -q 'require("clipshrink")' ~/.hammerspoon/init.lua 2>/dev/null || echo 'require("clipshrink")' >> ~/.hammerspoon/init.lua
open -a Hammerspoon                      # 首次打开；菜单栏出现锤子图标
```

**权限步骤（必须，只能由用户手动点一次——AI 无法代点）**：
在 Hammerspoon 菜单栏图标 → `Reload Config` 之后，打开下面任一入口，把 **Hammerspoon 设为"允许"**：

```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Pasteboard" \
  || open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Pasteboard"
```

（路径：系统设置 → 隐私与安全性 → "从其他 App 粘贴"。不设的话，后台读取会被系统静默拒绝、表现为"没效果"。）

> ⚠️ 因为这一步无法自动化，**AI 在最终汇报时必须把它单列为「需要您手动完成」一项**（汇报格式见文末模板）。

验证：`Cmd+Ctrl+Shift+4` 截一张整屏（或复制任意 >2000px 大图）→ 右下角应弹
`clipshrink: 3024x1964 -> 2000x1299` 之类的提示 → 粘进任意图片 App 核对尺寸 ≤2000px。
**若没有弹出提示**：九成是权限没开——先带用户走上面的权限步骤，再让他重新复制一次大图复测；
复测仍无提示则报告原始现象（含执行的命令与输出）。

> 备选工具：开源项目 `Taewoong1378/shotsmash`（一键 curl 安装、文件+剪贴板双模式）。注意现状：
> 14★、单日项目、代码数月未更新、剪贴板为低频轮询（截图后立刻粘贴可能仍是原图）。给客户装机前先自行审代码。

### 最后

重启 Codex。可选验证同 Windows。

---

## 装完汇报模板（AI 必须按此格式向用户汇报）

```
image-shrink 安装与验证结果
- 系统：Windows 10 / macOS 27.x
- 技能：✅/❌（~/.codex/skills/image-shrink 存在；AGENTS.md 常驻指令标记 = 1 处）
- 剪贴板助手：✅/❌（已装并自启）
- 端到端验证：
  - 剪贴板缩图：复制/造一张 2400×1500 大图 → 处理后应为 2000×1250（实测：____）
  - 技能读图：让 Codex 看一眼大图 → 是否先出小副本（实测：____）

【macOS 必列】⚠️ 需要您手动完成 1 项（AI 无法代点）：
  打开「系统设置 → 隐私与安全性 → 从其他 App 粘贴」，把 Hammerspoon 设为「允许」。
  一键直达（复制到终端回车即可把我带过去）：
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Pasteboard"
  不开这一步：剪贴板助手读不到图片，等于没装。

- 重启 Codex 后即可生效。
```

要点：
- **macOS 的「需要您手动完成」区块必须出现在汇报里**（即使已验证通过，也提醒一次以防后续系统更新重置）；
- Windows 无手动项，如实报告即可；
- 任何一步失败：先按「故障排查」表自查一轮，仍失败则汇报原始命令与输出，不要略过。

## 卸载

- 技能：删除 `~/.codex/skills/image-shrink/`，并删掉 `~/.codex/AGENTS.md` 里 `image-shrink:begin` 到
  `image-shrink:end` 之间的标记块（有 `.bak-*` 备份可还原）；
- Windows 剪贴板助手：删 `%LOCALAPPDATA%\codex-clipshrink` 和开始菜单启动文件夹里的 `codex-clipshrink.lnk`，结束对应 powershell 进程；
- macOS 剪贴板助手：删 `~/.hammerspoon/clipshrink.lua` 与 `init.lua` 里的 `require("clipshrink")` 行，Reload。

## 故障排查

| 症状 | 处理 |
|---|---|
| 技能不触发 | 确认 `~/.codex/skills/image-shrink/SKILL.md` 存在且 `AGENTS.md` 标记块在；重启 Codex |
| Windows 剪贴板无反应 | 确认常驻进程在跑：`wscript "%LOCALAPPDATA%\codex-clipshrink\launch.vbs"` 重新拉起 |
| macOS 剪贴板无反应 | 99% 是"从其他 App 粘贴"未允许 Hammerspoon（见上面权限步骤） |
| macOS 提示 `clipshrink: 剪贴板无图` | 同上（被隐私机制拦截）或剪贴板确实不是图片 |
