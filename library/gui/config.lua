-- NoIndex: true

local Config = {}

Config.doubleclickTime = 0.30

--[[
    How fast the caret in textboxes should blink, measured in GUI update loops.

    '16' looks like a fairly typical textbox caret.

    Because each On and Off redraws the textbox's layer, this can cause CPU
    issues in scripts with lots of drawing to do. In that case, raising it to
    24 or 32 will still look alright but require less redrawing.
]]--
Config.caretBlinkRate = 16

-- Global shadow size, in pixels
Config.shadowSize = 1

-- Delay time when hovering over an element before displaying a tooltip
Config.tooltipTime = 0.7

-- Developer mode settings
Config.dev = {

  -- gridMajor must be a multiple of gridMinor
  gridMajor = 128,
  gridMinor = 16

}

Config.colors = {
  background = {64, 64, 64, 255},           -- windowBg
  backgroundDark = {56, 56, 56, 255},       -- tabBg
  backgroundDarkest = {48, 48, 48, 255},    -- elmBg
  elementBody = {96, 96, 96, 255},          -- elmFrame
  highlight = {64, 192, 64, 255},           -- elmFill
  elementOutline = {32, 32, 32, 255},       -- elmOutline
  text = {192, 192, 192, 255},              -- txt
  shadow = {0, 0, 0, 48},
  faded = {0, 0, 0, 64},
}



local ext = reaper.GetExtState("Scythe v3", "userConfig")

require("public.string")
local function parseQueryString(str)
  return str:split("&"):reduce(function(acc, param)
    local k, v = param:match("([^=]+)=([^=]+)")
    acc[k] = v

    return acc
  end, {})
end

local userConfig = parseQueryString(ext)

for k, v in pairs(userConfig) do
  if Config[k] ~= nil then Config[k] = v end
end

return Config
