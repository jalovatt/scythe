local Config = {}


--[[
    How fast the caret in textboxes should blink, measured in GUI update loops.

    '16' looks like a fairly typical textbox caret.

    Because each On and Off redraws the textbox's layer, this can cause CPU
    issues in scripts with lots of drawing to do. In that case, raising it to
    24 or 32 will still look alright but require less redrawing.
]]--
Config.txt_blink_rate = 16


-- Delay time when hovering over an element before displaying a tooltip
Config.tooltip_time = 0.8

-- Developer mode settings
Config.dev = {

  -- grid_a must be a multiple of grid_b, or it will
  -- probably never be drawn
  grid_a = 128,
  grid_b = 16

}


return Config
