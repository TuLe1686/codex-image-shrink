-- clipshrink for macOS（Hammerspoon 方案）
-- 效果：凡是拷进剪贴板的图片（截图、"拷贝图像"等），长边 >1920px 的自动替换成 ≤1920px 的小副本——
--       任何程序（包括 Codex）粘贴到的都是小图。
--
-- 安装：
--   1) 安装 Hammerspoon（免费）：brew install --cask hammerspoon  或官网 https://www.hammerspoon.org
--   2) 打开 Hammerspoon（菜单栏图标）；把本文件拷到 ~/.hammerspoon/clipshrink.lua，
--      并在 ~/.hammerspoon/init.lua 里加一行：require("clipshrink")
--   3) 菜单栏 → Reload Config。
--
-- ⚠️ 权限（macOS 15.4+/26/27 的剪贴板隐私机制，必须做一次）：
--   本脚本在后台"程序化读取"剪贴板，系统会拦截/弹提示。请到
--   系统设置 → 隐私与安全性 → "从其他 App 粘贴"（Paste from Other Apps）→ 把 Hammerspoon 设为"允许"。
--   说明：轮询只调 changeCount（只读计数器、不读内容，不触发该机制）；只有剪贴板变化时才 readImage。
--
-- 依赖：系统自带 sips（做缩放与 JPEG 转码）。

local MAXDIM = 1920
local QUALITY = 85 -- sips formatOptions 0-100

local last = hs.pasteboard.changeCount()
local warned = false

local function cleanup(...)
  for _, f in ipairs({ ... }) do pcall(os.remove, f) end
end

local function shrinkPasteboardImage()
  local img = hs.pasteboard.readImage()
  if not img then
    -- 剪贴板不是图片，或被系统剪贴板隐私拦截（readImage 返回 nil）
    if not warned then
      warned = true
      hs.alert.show("clipshrink: 剪贴板无图（或被系统隐私拦截——请到 系统设置→隐私与安全性→从其他 App 粘贴 允许 Hammerspoon）", 3)
    end
    return
  end
  local sz = img:size()
  local w, h = sz.w, sz.h
  if w <= MAXDIM and h <= MAXDIM then return end -- 没超上限，不折腾

  local tmpIn = os.tmpname() .. ".png"
  local tmpOut = os.tmpname() .. ".jpg"
  -- scale=true：按像素尺寸落盘（Retina 屏上点/像素 2:1，默认按"点"存会意外减半）
  if not img:saveToFile(tmpIn, true, "PNG") then cleanup(tmpIn, tmpOut); return end
  os.execute(string.format(
    "/usr/bin/sips -Z %d -s format jpeg -s formatOptions %d '%s' --out '%s' >/dev/null 2>&1",
    MAXDIM, QUALITY, tmpIn, tmpOut))
  local small = hs.fs.attributes(tmpOut) and hs.image.imageFromPath(tmpOut) or nil
  if small then
    if hs.pasteboard.writeObjects(small) then
      -- 关键：吃掉自己这次写入引起的变化，避免下一轮再读一次（既省事也少触发隐私机制）
      last = hs.pasteboard.changeCount()
      hs.alert.show(string.format("clipshrink: %dx%d -> %dx%d", w, h, small:size().w, small:size().h), 1)
    end
  end
  cleanup(tmpIn, tmpOut)
end

local watcher = hs.timer.new(0.6, function()
  local cc = hs.pasteboard.changeCount()
  if cc ~= last then
    last = cc
    -- 稍等一拍，让复制方把剪贴板写完
    hs.timer.doAfter(0.15, function() pcall(shrinkPasteboardImage) end)
  end
end)
watcher:start()
hs.alert.show("clipshrink 已启动", 1)
