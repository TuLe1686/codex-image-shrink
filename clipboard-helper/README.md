# 剪贴板助手（clipshrink）——治"直接粘贴"那条路

技能管不到"用户把截图直接粘贴进对话"的路径（那在客户端内部管道）。
剪贴板助手从更靠前的地方下手：**图片一进剪贴板就换成小副本**，
之后无论是粘贴进 Codex、微信还是别的程序，拿到的都是小图——客户工作流零改动。

```
系统截图（Win+Shift+S / Cmd+Shift+4）
   → 剪贴板（clipshrink 在此把 >2000px 的图换成 ≤2000px JPEG 小副本）
      → 粘贴进 Codex：从头到尾都是小图
```

## Windows（fangkai 这类）

```powershell
# 试用（前台跑，看效果；Ctrl+C 退出）
powershell -NoProfile -STA -ExecutionPolicy Bypass -File windows\clipshrink.ps1

# 处理当前剪贴板一次（快速验证）
powershell -NoProfile -STA -ExecutionPolicy Bypass -File windows\clipshrink.ps1 -Once

# 安装为开机自启（隐藏窗口）
powershell -NoProfile -ExecutionPolicy Bypass -File windows\install.ps1
```

- 零依赖（系统自带 .NET / PowerShell）；常驻内存 <40MB，轮询开销可忽略（剪贴板序号比对，无变化不处理）；
- 卸载：删除 `%LOCALAPPDATA%\codex-clipshrink` 与 Startup 里的 `codex-clipshrink.lnk`。

## macOS（yhb 这类）

> ⚠️ **新版 macOS 的剪贴板隐私机制（15.4 引入、26/27 落地）：** 任何在后台"程序化读取剪贴板"的工具
> （包括下面的两个方案）都会被系统拦截/弹提示，需要到 **系统设置 → 隐私与安全性 → "从其他 App 粘贴"
> （Paste from Other Apps）** 里把对应 App 设为"允许"——**一次性步骤**，不做的话读取会被静默拒绝。
> （依据：Apple 开发者公告 + 15.4 预览 + 27.2 起旧开发者预览开关废弃。）

**方案 A（省事，值得先评估）：现成的开源工具 `shotsmash`**
（github.com/Taewoong1378/shotsmash）——专为这个场景做的 macOS 工具：
文件模式（盯 `~/Pictures/Screenshots/`）+ **剪贴板模式**（>1400px 自动缩），描述里点名 Codex/Claude Code 场景。
装前审一遍源码（给客户装机建议先自己在测试机过一遍）。装好后同样要在"从其他 App 粘贴"里允许它。

**方案 B（自研兜底，零第三方依赖）：Hammerspoon + 系统自带 sips**

1. `brew install --cask hammerspoon`（或官网下载），打开菜单栏图标；
2. 把 `macos/hammerspoon-clipshrink.lua` 放到 `~/.hammerspoon/clipshrink.lua`，`init.lua` 里加 `require("clipshrink")`；
3. 菜单栏 Reload Config；
4. **权限（必须）**：系统设置 → 隐私与安全性 → "从其他 App 粘贴" → Hammerspoon 设为"允许"
   （未授权时首次复制大图会弹一次引导提示）；
5. 冒烟：复制一张 >2000px 的截图，应弹 `clipshrink: WxH -> WxH`；粘到预览里核对尺寸 ≤2000px；
6. 卸载：删 `require` 行与文件，Reload。

设计要点（为何这样写）：轮询只读 **changeCount**（计数器，不读内容、不触发隐私机制）；仅计数器变化才 `readImage`；
自己写入后立刻刷新计数器基准，避免二次读取；`saveToFile(..., true, "PNG")` 按像素落盘
（Retina 屏点/像素 2:1，默认按"点"存会意外缩半——这是逐条对 Hammerspoon 官方文档核出来的）；写入为 NSImage
（系统以 TIFF 表示，主流 App 均可接收）。

> 方案 B 已把用到的 API 逐条对 Hammerspoon 官方文档核过（`changeCount` / `readImage` / `writeObjects` /
> `imageFromPath` / `:size()` / `saveToFile` 均确认存在与签名一致），但仍需在真机（yhb 的 Mac）
> 冒烟——重点验证：权限步骤、Codex 里粘贴的实际效果。

## 边界与取舍

- 只处理"剪贴板里的图片数据"（截图、"复制图像"）；"复制文件"（CF_HDROP）不动；
- 它会替换剪贴板里的原图 —— 如果你把图片复制出去是要往 Photoshop 里贴原图的场景，这个助手会按 ≤2000px 给你。
  对"贴进对话给模型看"这个主场景无损（模型本来也不吃那么多像素）；在意原图的机器建议不装；
- 图片本来就 ≤2000px 的，原样保留不重编码。

## 开发注意

- 所有 `.ps1` 文件必须带 **UTF-8 BOM**（`EF BB BF`）——Windows PowerShell 5.1 对无 BOM 文件按本地代码页解析，
  中文注释会变成乱码甚至语法错误（实测踩坑：无 BOM 时直接报 ParserError）。用编辑器保存时保留 BOM。
