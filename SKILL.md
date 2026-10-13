---
name: image-shrink
description: 查看/附加本地大图（截图、照片、PNG/JPEG/WEBP 文件）前，先降采样+重编码成小副本，只把副本放进对话。当需要 view_image、读取图片文件、或把大图带进上下文时使用，尤其文件超过约 500KB 或分辨率超过 2000px 时。Shrink large images before viewing or attaching them.
---

# 大图先缩再读（image-shrink）

背景：模型按 patch 计图片 token——**一张 8MB 的图和一张 300KB 的图，token 几乎一样多**，多出来的字节买不到任何信息，却会把对话请求体滚雪球：几十张图 = 几十 MB 请求体，上传慢、触发网关体量上限、线程报废（这些字节进入历史后无法撤出，压缩历史也删不掉图）。

## 规则

1. **看任何图片文件之前，先跑缩图脚本产出小副本，只读小副本**（原文件保持不动）：
   - Windows（PowerShell，零依赖）：
     ```
     powershell -NoProfile -ExecutionPolicy Bypass -File <skill目录>\scripts\shrink.ps1 -Path "<原图路径>"
     ```
   - macOS / Linux：
     ```
     bash <skill目录>/scripts/shrink.sh "<原图路径>"
     ```
2. 脚本产出 `<原图同目录>/<文件名>.small.jpg`（长边 ≤2000px、JPEG q85；若压不小会自动跳过并提示保留原图）。随后只对 `.small.jpg` 做 view_image / 读取 / 附加。
3. 默认不用全分辨率——除非用户明确要看像素级细节（如单像素缺陷排查）。
4. **会话卫生**：如果当前会话历史里已累积大量图片、且用户反馈发送失败/卡顿/超时，提醒用户**开新会话**继续（历史里的图无法撤出，这是唯一的解脱方式）。
5. 用户把截图**直接粘贴**进对话的路径不经过本技能（那在客户端内部管道）；若用户反馈"贴图后变卡/发不出去"，建议改为"保存成文件再让你看"，或检查是否遇到请求体过大类错误。
6. 若需要统计当前会话/最近会话里到底有多少图片进了上下文（用于诊断），运行：
   ```
   python3 <skill目录>/scripts/scan-sessions.py 3
   ```

## 自检

缩完先确认小副本存在且明显变小（脚本会打印 `原大小 -> 新大小`），再读取。小副本缺失或没变小（SKIP）时，读原图并在回复里说明。
