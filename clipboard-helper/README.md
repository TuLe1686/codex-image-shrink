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

用 Hammerspoon（免费开源）+ 系统自带 sips：

1. `brew install --cask hammerspoon`（或官网下载），打开并授予辅助功能权限；
2. 把 `macos/hammerspoon-clipshrink.lua` 放到 `~/.hammerspoon/clipshrink.lua`，在 `init.lua` 里加 `require("clipshrink")`；
3. 菜单栏 Reload Config。装完复制一张大截图试试，右下角会弹 `clipshrink: WxH -> WxH`。
4. 卸载：删掉那行 require 与文件，Reload。

> ⚠️ Hammerspoon 版逻辑已在代码层审过，但**尚未在真机（yhb 的 Mac）验证**——装机时按上面第 3 步冒烟一次。

## 边界与取舍

- 只处理"剪贴板里的图片数据"（截图、"复制图像"）；"复制文件"（CF_HDROP）不动；
- 它会替换剪贴板里的原图 —— 如果你把图片复制出去是要往 Photoshop 里贴原图的场景，这个助手会按 ≤2000px 给你。
  对"贴进对话给模型看"这个主场景无损（模型本来也不吃那么多像素）；在意原图的机器建议不装；
- 图片本来就 ≤2000px 的，原样保留不重编码。

## 开发注意

- 所有 `.ps1` 文件必须带 **UTF-8 BOM**（`EF BB BF`）——Windows PowerShell 5.1 对无 BOM 文件按本地代码页解析，
  中文注释会变成乱码甚至语法错误（实测踩坑：无 BOM 时直接报 ParserError）。用编辑器保存时保留 BOM。
