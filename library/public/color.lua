-- NoIndex: true
local Math = require("public.math")
local Table = require("public.table")

local Color = {}

--[[	Apply a color preset

    col			Color preset string -> "highlight"
                or
                Color table -> {1, 0.5, 0.5[, 1]}
                                R  G    B  [  A]
]]--
Color.set = function (col)
  local r, g, b, a

  -- If we're given a table of color values, just pass it right along
  if type(col) == "table" then
    r, g, b, a = table.unpack(col)
    a = a or 1
  else

    -- Recurse through the presets; allows presets to be set as other presets
    -- Should probably have a limit to avoid infinite loops if red = "blue" = "red"...
    local val = Color.colors[col]
    while type(val) == "string" do
      val = Color.colors[val]
    end

    if not val then
      error("Couldn't find color preset: '" .. col .. "'")
    end

    r, g, b, a = table.unpack(val)
  end

  gfx.set(r, g, b, a)
  return {gfx.r, gfx.g, gfx.b, gfx.a}
end




-- Converts a color from 0-255 RGBA to 0-1
-- Returns a table of {R, G, B, A}
Color.fromRgba = function(r, g, b, a)
  if type(r) == "table" then r, g, b, a = table.unpack(r) end

  return {r / 255, g / 255, b / 255, (a and (a / 255) or 1)}
end

-- Converts a color from 0-1 RGBA to 0-255
Color.toRgba = function(r, g, b, a)
  if type(r) == "table" then r, g, b, a = table.unpack(r) end

  return {r * 255, g * 255, b * 255, (a and (a * 255) or 1)}
end

-- Convert a hex string RRGGBBAA to 0-1 RGBA
Color.fromHex = function (hexStr)

  -- Trim any "0x" or "#" prefixes
  local hex = hexStr:match("[0-9A-F]+$")

  local red, green, blue = hex:match("([0-9A-F][0-9A-F])([0-9A-F][0-9A-F])([0-9A-F][0-9A-F])")
  local alpha = (hex:len() == 8) and hex:match("([0-9A-F][0-9A-F])$")

  red = tonumber(red, 16) or 0
  green = tonumber(green, 16) or 0
  blue = tonumber(blue, 16) or 0
  alpha = alpha and tonumber(alpha, 16) or 255

  return {red / 255, green / 255, blue / 255, alpha / 255}
end

-- Converts a color from 0-1 RGBA to hex
Color.toHex = function(r, g, b, a)
  return string.format("%02X%02X%02X", Math.round(r * 255), Math.round(g * 255), Math.round(b * 255))
      .. (a and string.format("%02X", Math.round(a * 255)) or "")
end

-- Convert rgb[a] to hsv[a]; useful for gradients
-- Arguments are given as 0-1, returns are h = 0-360, s,v,a = 0-1
Color.toHsv = function (r, g, b, a)

  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local chroma = max - min

  -- Dividing by zero is never a good idea
  if chroma == 0 then
    return {0, 0, max, (a or 1)}
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

  return {hue * 360, sat, max, (a or 1)}

end


-- ...and back the other way
Color.fromHsv = function (hAngle, s, v, a)

  -- % will be wrong for hAngle < 0
  local h = (hAngle % 360) / 360

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

  return {r + min, g + min, b + min, (a or 1)}

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

  colorA = Color.toHsv(
    table.unpack(
      type(colorA) == "table"
        and colorA
        or  Color.colors[colorA]
    )
  )

  colorB = Color.toHsv(
    table.unpack(
      type(colorB) == "table"
        and colorB
        or  Color.colors[colorB]
    )
  )

  local h = math.abs(colorA[1] + (pos * (colorB[1] - colorA[1])))
  local s = math.abs(colorA[2] + (pos * (colorB[2] - colorA[2])))
  local v = math.abs(colorA[3] + (pos * (colorB[3] - colorA[3])))

  local a = (#colorA == 4)
      and  (math.abs(colorA[4] + (pos * (colorB[4] - colorA[4]))))
      or  1

  return Color.fromHsv(h, s, v, a)

end

Color.addColorsFromRgba = function (colors)
  for k, v in pairs(colors) do
    Color.colors[k] = Color.fromRgba(table.unpack(v))
  end
end

-- TODO: Tests
Color.toNative = function (color)
  local colorTable = type(color) == "table" and color or Color.colors[color]
  local rgb = Table.map(colorTable, function(v) return v * 255 end)
  return reaper.ColorToNative(rgb:unpack())
end

-- TODO: Tests
Color.fromNative = function(color)
  local r, g, b = reaper.ColorFromNative(color)
  return {r / 255, g / 255, b / 255}
end

Color.colors = {
  -- Standard 16 colors
  black = Color.fromRgba(0, 0, 0, 255),
  white = Color.fromRgba(255, 255, 255, 255),
  red = Color.fromRgba(255, 0, 0, 255),
  lime = Color.fromRgba(0, 255, 0, 255),
  blue = Color.fromRgba(0, 0, 255, 255),
  yellow = Color.fromRgba(255, 255, 0, 255),
  cyan = Color.fromRgba(0, 255, 255, 255),
  magenta = Color.fromRgba(255, 0, 255, 255),
  silver = Color.fromRgba(192, 192, 192, 255),
  gray = Color.fromRgba(128, 128, 128, 255),
  maroon = Color.fromRgba(128, 0, 0, 255),
  olive = Color.fromRgba(128, 128, 0, 255),
  green = Color.fromRgba(0, 128, 0, 255),
  purple = Color.fromRgba(128, 0, 128, 255),
  teal = Color.fromRgba(0, 128, 128, 255),
  navy = Color.fromRgba(0, 0, 128, 255),

  none = Color.fromRgba(0, 0, 0, 0),
}

return Color
