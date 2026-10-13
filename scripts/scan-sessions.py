#!/usr/bin/env python3
"""入口诊断：统计 Codex 会话日志里进过对话的图片（张数/格式/大小），判断"图从哪条路进来"。

在要检查的机器上运行（本机或客户机均可）：
    python3 scan-sessions.py [最近N个会话，默认3]

输出每个会话：图片张数、格式分布、总字节、单张最大。用于核对：
- 粘贴路径的图：Codex 客户端一般会先降采样（若这里看到单张仍 >2MB，说明该路径没吃到降采样）；
- 工具路径（view_image / MCP / 插件输出）的图：按 upstream issue 实测不降采样，会原样进来。
"""
import glob
import os
import re
import sys

n = int(sys.argv[1]) if len(sys.argv) > 1 else 3
pat = os.path.expanduser("~/.codex/sessions/**/*.jsonl")
files = sorted(glob.glob(pat, recursive=True), key=os.path.getmtime)[-n:]
if not files:
    print("未找到会话日志（~/.codex/sessions/**/*.jsonl）")
    sys.exit(1)

RE = re.compile(r"data:image/(png|jpeg|jpg|webp|svg\+xml);base64,([A-Za-z0-9+/=]{40,})")
for f in files:
    counts = {}
    total = 0
    mx = 0
    for line in open(f, encoding="utf-8", errors="replace"):
        for m in RE.finditer(line):
            b = len(m.group(2)) * 3 // 4
            counts[m.group(1)] = counts.get(m.group(1), 0) + 1
            total += b
            mx = max(mx, b)
    name = os.path.basename(f)
    print(f"{name[:64]}  图片 {sum(counts.values())} 张 {counts}  共 {total / 1e6:.1f}MB  最大 {mx // 1024}KB")
