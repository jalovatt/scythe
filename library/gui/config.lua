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
Config.shadowSize = 2


-- Delay time when hovering over an element before displaying a tooltip
Config.tooltipTime = 0.7

-- Developer mode settings
Config.dev = {

  -- gridMajor must be a multiple of gridMinor
  gridMajor = 128,
  gridMinor = 16

}


return Config
