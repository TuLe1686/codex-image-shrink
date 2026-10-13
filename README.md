# codex-image-shrink

Codex 技能：**大图先缩再读** —— 凡是要把本地图片带进对话（view_image / 读取图片文件 / 附加），
先降采样 + 重编码成小副本（长边 ≤2000px、JPEG q85），**只把小副本喂给模型**。

> Shrink large local images before they enter the conversation: downscale and re-encode
> to a small JPEG copy (≤2000px, q85), then view only that copy.

## 为什么需要它

- 模型按 patch 计图片 token：**一张 8MB 的图和一张 300KB 的图，token 几乎一样多** —— 多出来的字节买不到任何信息；
- 但字节会滚雪球：几十张大图 = 几十 MB 请求体 → 上传慢、触发网关体量上限、会话线程报废
  （图片进入历史后无法撤出，压缩历史也删不掉图）；
- Codex 对「普通粘贴的超大截图」有客户端降采样，但 **agent 用 view_image / MCP / 插件产生的图片不降采样**
  （upstream 有实测：4.2MB/张原样进历史，token 只记 230）。

## 安装

**方式一（Codex 内置 skill-installer，推荐）**：

```
Install the skill from github.com/TuLe1686/codex-image-shrink
```

**方式二（手动）**：把本仓库拷到 `~/.codex/skills/image-shrink/`，重启 Codex。

- 建议放 `~/.codex/skills/`（桌面端对 `~/.agents/skills` 的个人技能索引有已知 bug）；
- 验证：对话里输入 `$` 能看到 `image-shrink`；或直接说「看一下 D:\xxx.png」观察它是否先跑缩图脚本。

## 覆盖范围

| 图片入口 | 是否处理 |
|---|---|
| agent 用 view_image / 读文件方式看图 | ✅ 先缩再读，立竿见影 |
| 用户直接**粘贴**截图进对话 | ❌ 粘贴在客户端内部管道，技能够不到 |

## 组件

- `SKILL.md` —— 技能规则（模型读取）；
- `scripts/shrink.ps1` —— Windows 缩图（系统自带 .NET，**零依赖**）；
- `scripts/shrink.sh` —— macOS / Linux 缩图（macOS 用系统自带 `sips`；Linux 用 `magick` / `ffmpeg`）；
- `scripts/scan-sessions.py` —— 诊断脚本：统计本机 Codex 会话里图片的张数 / 大小 / 格式。

## 实测

Windows 零依赖路径：**2400×1500 / 837KB PNG → 2000×1250 / 39KB JPEG**。

## License

MIT
