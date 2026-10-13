-- clipshrink for macOS（Hammerspoon 方案）
-- 效果：凡是拷进剪贴板的图片（截图、"拷贝图像"等），长边 >2000px 的自动替换成 ≤2000px JPEG 小副本——
--       任何程序（包括 Codex）粘贴到的都是小图。
-- 安装：
--   1) 安装 Hammerspoon（免费）：brew install --cask hammerspoon  或官网 https://www.hammerspoon.org
--   2) 打开 Hammerspoon，授予"辅助功能"权限；
--   3) 把本文件拷到 ~/.hammerspoon/clipshrink.lua，并在 ~/.hammerspoon/init.lua 里加一行：
--        require("clipshrink")
--   4) 菜单栏 Hammerspoon → Reload Config。
-- 依赖：系统自带 sips（做实际缩放与 JPEG 转码）。

local MAXDIM = 2000
local QUALITY = 85 -- sips formatOptions 0-100

local last = hs.pasteboard.changeCount()

local function shrinkPasteboardImage()
  local img = hs.pasteboard.readImage()
  if not img then return end
  local sz = img:size()
  local w, h = sz.w, sz.h
  if w <= MAXDIM and h <= MAXDIM then return end -- 没超上限，不折腾

  local tmpIn = os.tmpname() .. ".png"
  local tmpOut = os.tmpname() .. ".jpg"
  if not img:saveToFile(tmpIn) then return end
  local cmd = string.format(
    "/usr/bin/sips -Z %d -s format jpeg -s formatOptions %d '%s' --out '%s' >/dev/null 2>&1",
    MAXDIM, QUALITY, tmpIn, tmpOut)
  local ok = os.execute(cmd)
  local small = ok and hs.image.imageFromPath(tmpOut) or nil
  if small then
    hs.pasteboard.writeObjects(small)
    hs.alert.show(string.format("clipshrink: %dx%d -> %dx%d", w, h, small:size().w, small:size().h), 1)
  end
  os.remove(tmpIn)
  os.remove(tmpOut)
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
