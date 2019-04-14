local Color = {}



Color.colors = {

    -- Element colors
    wnd_bg = {64, 64, 64, 255},			-- Window BG
    tab_bg = {56, 56, 56, 255},			-- Tabs BG
    elm_bg = {48, 48, 48, 255},			-- Element BG
    elm_frame = {96, 96, 96, 255},		-- Element Frame
    elm_fill = {64, 192, 64, 255},		-- Element Fill
    elm_outline = {32, 32, 32, 255},	-- Element Outline
    txt = {192, 192, 192, 255},			-- Text

    shadow = {0, 0, 0, 48},				-- Element Shadows
    faded = {0, 0, 0, 64},

    -- Standard 16 colors
    black = {0, 0, 0, 255},
    white = {255, 255, 255, 255},
    red = {255, 0, 0, 255},
    lime = {0, 255, 0, 255},
    blue =  {0, 0, 255, 255},
    yellow = {255, 255, 0, 255},
    cyan = {0, 255, 255, 255},
    magenta = {255, 0, 255, 255},
    silver = {192, 192, 192, 255},
    gray = {128, 128, 128, 255},
    maroon = {128, 0, 0, 255},
    olive = {128, 128, 0, 255},
    green = {0, 128, 0, 255},
    purple = {128, 0, 128, 255},
    teal = {0, 128, 128, 255},
    navy = {0, 0, 128, 255},

    none = {0, 0, 0, 0},


}


------------------------------------
-------- Color functions -----------
------------------------------------


--[[	Apply a color preset

    col			Color preset string -> "elm_fill"
                or
                Color table -> {1, 0.5, 0.5[, 1]}
                                R  G    B  [  A]
]]--
Color.set = function (col)

  -- If we're given a table of color values, just pass it right along
  if type(col) == "table" then

    gfx.set(col[1], col[2], col[3], col[4] or 1)
  else
    gfx.set(table.unpack(Color.colors[col]))
  end

end


-- Convert a hex color RRGGBB to 8-bit values R, G, B
Color.hex2rgb = function (num)

  if string.sub(num, 1, 2) == "0x" then
    num = string.sub(num, 3)
  end

  local red = string.sub(num, 1, 2)
  local green = string.sub(num, 3, 4)
  local blue = string.sub(num, 5, 6)


  red = tonumber(red, 16) or 0
  green = tonumber(green, 16) or 0
  blue = tonumber(blue, 16) or 0

  return red, green, blue

end


-- Convert rgb[a] to hsv[a]; useful for gradients
-- Arguments/returns are given as 0-1
Color.rgb2hsv = function (r, g, b, a)

  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local chroma = max - min

  -- Dividing by zero is never a good idea
  if chroma == 0 then
    return 0, 0, max, (a or 1)
  end

  local hue
  if max == r then
    hue = ((g - b) / chroma) % 6
  elseif max == g then
    hue = ((b - r) / chroma) + 2
  elseif max == b then
    hue = ((r - g) / chroma) + 4
  else
    hue = -1
  end

  if hue ~= -1 then hue = hue / 6 end

  local sat = (max ~= 0) 	and	((max - min) / max)
                          or	0

  return hue, sat, max, (a or 1)


end


-- ...and back the other way
Color.hsv2rgb = function (h, s, v, a)

  local chroma = v * s

  local hp = h * 6
  local x = chroma * (1 - math.abs(hp % 2 - 1))

  local r, g, b
  if hp <= 1 then
    r, g, b = chroma, x, 0
  elseif hp <= 2 then
    r, g, b = x, chroma, 0
  elseif hp <= 3 then
    r, g, b = 0, chroma, x
  elseif hp <= 4 then
    r, g, b = 0, x, chroma
  elseif hp <= 5 then
    r, g, b = x, 0, chroma
  elseif hp <= 6 then
    r, g, b = chroma, 0, x
  else
    r, g, b = 0, 0, 0
  end

  local min = v - chroma

  return r + min, g + min, b + min, (a or 1)

end


--[[
    Returns the color for a given position on an HSV gradient
    between two color presets

    col_a		Tables of {R, G, B[, A]}, values from 0-1
    col_b

    pos			Position along the gradient, 0 = col_a, 1 = col_b

    returns		r, g, b, a

]]--
Color.gradient = function (col_a, col_b, pos)

  col_a = {
    Color.rgb2hsv(
      table.unpack(
        type(col_a) == "table"
          and col_a
          or  Color.colors(col_a)
      )
    )
  }

  col_b = {
    Color.rgb2hsv(
      table.unpack(
        type(col_b) == "table"
          and col_b
          or  Color.colors(col_b)
      )
    )
  }

  local h = math.abs(col_a[1] + (pos * (col_b[1] - col_a[1])))
  local s = math.abs(col_a[2] + (pos * (col_b[2] - col_a[2])))
  local v = math.abs(col_a[3] + (pos * (col_b[3] - col_a[3])))

  local a = (#col_a == 4)
      and  (math.abs(col_a[4] + (pos * (col_b[4] - col_a[4]))))
      or  1

  return Color.hsv2rgb(h, s, v, a)

end



return Color
