# codex-image-shrink

**大图先缩再读** —— Codex 技能 + 剪贴板助手，让图片以"小副本"进入对话：

- 技能（`image-shrink`）：agent 看任何图片文件前，先降采样+重编码成小副本（长边 ≤2000px、JPEG q85），只读小副本；
- 剪贴板助手（`clipshrink`）：图片一进剪贴板就换成小副本 —— **直接粘贴**进对话的路径也覆盖，客户工作流零改动。

> Shrink large local images before they enter the conversation — via a Codex skill (file/view_image path)
> and a clipboard helper (paste path). Downscale + re-encode to a small JPEG copy (≤2000px, q85).

## 为什么需要它

- 模型按 patch 计图片 token：**一张 8MB 的图和一张 300KB 的图，token 几乎一样多** —— 多出来的字节买不到任何信息；
- 但字节会滚雪球：几十张大图 = 几十 MB 请求体 → 上传慢、触发网关体量上限、会话线程报废
  （图片进入历史后无法撤出，压缩历史也删不掉图）；
- Codex 对「普通粘贴的超大截图」有客户端降采样，但 **agent 用 view_image / MCP / 插件产生的图片不降采样**
  （upstream 有实测：4.2MB/张原样进历史，token 只记 230）。

## 安装（一行命令，装技能 + 常驻强制指令）

在仓库目录里运行：
- **Windows**：
  ```
  powershell -NoProfile -ExecutionPolicy Bypass -File install\install.ps1
  ```
- **macOS / Linux**：
  ```
  bash install/install.sh
  ```

安装器做两件事（幂等，改前自动备份）：
1. 技能本体 → `~/.codex/skills/image-shrink/`；
2. **常驻强制指令** → `~/.codex/AGENTS.md` 的标记块。

第 2 步是关键：技能列表是"按描述隐式匹配"（模型可能不用）；而 `~/.codex/AGENTS.md` 是**始终在上下文里**的全局指令——
把"读图必须先缩"写死在这里，agent 每次要读图都会执行，**不依赖用户提及技能、也不依赖隐式匹配**。
装完重启 Codex 生效。

> 也支持 Codex 内置安装：`Install the skill from github.com/TuLe1686/codex-image-shrink`（只装技能，不含常驻指令）。

## 剪贴板助手（粘贴路径）

技能管不到"直接把截图粘进对话"的路径；剪贴板助手从源头下手：**图片一进剪贴板就换成 ≤2000px 小副本**，
之后粘进任何程序（Codex/微信/…）拿到的都是小图。见 [`clipboard-helper/`](clipboard-helper/)：
- Windows：`clipboard-helper/windows/`（PowerShell 零依赖，一条命令装成开机自启）；
- macOS：`clipboard-helper/macos/hammerspoon-clipshrink.lua`（Hammerspoon + 系统 sips）。

## 覆盖范围

| 图片入口 | 处理方式 |
|---|---|
| agent 用 view_image / 读文件方式看图 | ✅ 技能（+ AGENTS.md 常驻指令保执行） |
| 用户直接**粘贴**截图进对话 | ✅ 剪贴板助手 |

## 组件

```
SKILL.md                        技能本体（强制流程）
scripts/shrink.ps1              Windows 缩图（系统自带 .NET，零依赖）
scripts/shrink.sh               macOS/Linux 缩图（macOS 用系统自带 sips）
scripts/scan-sessions.py        会话图片入口诊断（统计张数/大小）
agents/openai.yaml              技能 UI 元数据
install/install.ps1|install.sh  一键安装（技能 + AGENTS.md 常驻指令）
clipboard-helper/               剪贴板缩图助手（Windows / macOS）
```

## 实测

- 技能缩图（Windows 零依赖）：**2400×1500 / 837KB PNG → 2000×1250 / 39KB JPEG**；
- 剪贴板助手（Windows）：2400×1500 截图进入剪贴板 → 自动替换为 2000×1250（≤2000px 的原图不动）。

## License

MIT
