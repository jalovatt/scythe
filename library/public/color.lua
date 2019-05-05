-- NoIndex: true

local Color = {}



Color.colors = {

    -- Element colors
    windowBg = {64, 64, 64, 255},			-- Window BG
    tabBg = {56, 56, 56, 255},			-- Tabs BG
    elmBg = {48, 48, 48, 255},			-- Element BG
    elmFrame = {96, 96, 96, 255},		-- Element Frame
    elmFill = {64, 192, 64, 255},		-- Element Fill
    elmOutline = {32, 32, 32, 255},	-- Element Outline
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

    col			Color preset string -> "elmFill"
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


-- Convert a hex string RRGGBB to 8-bit values R, G, B
Color.hexToRgb = function (hexStr)

  -- Trim any "0x" or "#" prefixes
  hexStr = hexStr:sub(-6)

  local red = string.sub(hexStr, 1, 2)
  local green = string.sub(hexStr, 3, 4)
  local blue = string.sub(hexStr, 5, 6)

  red = tonumber(red, 16) or 0
  green = tonumber(green, 16) or 0
  blue = tonumber(blue, 16) or 0

  return red, green, blue

end


-- Convert rgb[a] to hsv[a]; useful for gradients
-- Arguments/returns are given as 0-1
Color.rgbToHsv = function (r, g, b, a)

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
Color.hsvToRgb = function (h, s, v, a)

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

    colorA		Tables of {R, G, B[, A]}, values from 0-1,
    colorB    or color preset strings

    pos			Position along the gradient, 0 = colorA, 1 = colorB

    returns		r, g, b, a

]]--
Color.gradient = function (colorA, colorB, pos)

  colorA = {
    Color.rgbToHsv(
      table.unpack(
        type(colorA) == "table"
          and colorA
          or  Color.colors(colorA)
      )
    )
  }

  colorB = {
    Color.rgbToHsv(
      table.unpack(
        type(colorB) == "table"
          and colorB
          or  Color.colors(colorB)
      )
    )
  }

  local h = math.abs(colorA[1] + (pos * (colorB[1] - colorA[1])))
  local s = math.abs(colorA[2] + (pos * (colorB[2] - colorA[2])))
  local v = math.abs(colorA[3] + (pos * (colorB[3] - colorA[3])))

  local a = (#colorA == 4)
      and  (math.abs(colorA[4] + (pos * (colorB[4] - colorA[4]))))
      or  1

  return Color.hsvToRgb(h, s, v, a)

end



return Color
