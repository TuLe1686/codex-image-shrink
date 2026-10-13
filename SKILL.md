---
name: image-shrink
description: 查看/附加本地大图（截图、照片、PNG/JPEG/WEBP 文件）前，先降采样+重编码成小副本，只把副本放进对话。**任何时候要 view_image、读取图片文件、或把图片带进上下文，都必须先跑本技能**——哪怕用户没提"缩图"。Shrink large images before viewing or attaching them; mandatory before any image file read.
---

# 大图先缩再读（image-shrink）——强制流程

> 本流程是**默认强制**的：只要你要"看"任何图片文件（PNG/JPEG/WEBP/GIF/截图），
> 无论用户有没有提缩图，都先跑缩图脚本，只读小副本。
> 只有用户明确要求全分辨率时才直接读原图。

背景：模型按 patch 计图片 token —— **一张 8MB 的图和一张 300KB 的图，token 几乎一样多**；
多出来的字节会把请求体滚雪球（几十张图 = 几十 MB 请求体）：上传慢、触发网关体量限制、会话报废，
而且图片进入历史后撤不回来、压缩历史也删不掉图。

## 强制步骤（每次读图都要走）

1. 运行缩图脚本：
   - Windows（零依赖）：
     ```
     powershell -NoProfile -ExecutionPolicy Bypass -File <skill目录>\scripts\shrink.ps1 -Path "<原图路径>"
     ```
   - macOS / Linux：
     ```
     bash <skill目录>/scripts/shrink.sh "<原图路径>"
     ```
2. 产物是 `<原图同目录>/<文件名>.small.jpg`（长边 ≤2000px、JPEG q85；若压不小会打印 SKIP 并保留原图——这种情形才读原图）。
3. **只对 `.small.jpg` 做 view_image / 读取 / 附加**。
4. 如果你正准备直接读原图却还没跑过脚本：**停下，先跑脚本**。这是默认不允许的捷径（除非用户点名要全分辨率）。
5. 会话里已积累大量图片、且出现发送失败/卡顿/超时：建议用户**开新会话**（历史里的图无法撤出）。

## 例外

- 用户明确要求全分辨率 / 像素级检查；
- 图片本来就是小图（<500KB 且 ≤2000px）：可以直读——拿不准就先跑脚本（几秒，会自行判断）。

## 诊断（可选）

统计最近会话里有多少图片、多大：
```
python3 <skill目录>/scripts/scan-sessions.py 3
```
