-- NoIndex: true
local math = math

local Const = require("public.const")

local Math = {}

-- Round a number to the nearest integer (or optional decimal places)
-- (Rounds up at n.5)
Math.round = function (n, places)

  if not places then
    return n > 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
  else
    places = 10^places
    return n > 0 and math.floor(n * places + 0.5)
                  or math.ceil(n * places - 0.5) / places
  end

end


-- Returns 'val', rounded to the nearest multiple of 'snap'
Math.nearestMultiple = function (n, snap)

  local int, frac = math.modf(n / snap)
  return (math.floor( frac + 0.5 ) == 1 and int + 1 or int) * snap

end



-- Clamps a number to a given range. The returned value is also the median of
-- the three values. Argument order doesn't matter.
Math.clamp = function (a, b, c)
  if b > c then b, c = c, b end
  return math.min(math.max(a, b), c)
end


-- Returns an ordinal string (i.e. 30 --> 30th)
Math.ordinal = function (n)
  n = Math.round(n)

  local endings2 = {
    ["11"] = "th",
    ["13"] = "th",
  }

  local endings1 = {
    ["1"] = "st",
    ["2"] = "nd",
    ["3"] = "rd",
  }

  local str = tostring(n)
  local ending
  if endings2[str:sub(-2)] then
    ending = endings2[str:sub(-2)]
  elseif endings1[str:sub(-1)] then
    ending = endings1[str:sub(-1)]
  else
    ending = "th"
  end

  return n .. ending
end

--[[
    Takes an angle in radians (omitting Pi) and a radius, returns x, y
    Will return coordinates relative to an origin of (0,0), or absolute
    coordinates if an origin point is specified
]]--
Math.polarToCart = function (angle, radius, ox, oy)

  local theta = angle * Const.PI
  local x = radius * math.cos(theta)
  local y = radius * math.sin(theta)


  if ox and oy then x, y = x + ox, y + oy end

  return x, y

end


--[[
    Takes cartesian coords, with optional origin coords, and returns
    an angle (in radians) and radius. The angle is given without reference
    to Pi; that is, Pi/4 radians would return as simply 0.25
]]--
Math.cartToPolar = function (x, y, ox, oy)

  local dx, dy = x - (ox or 0), y - (oy or 0)

  local angle = math.atan(dy, dx) / Const.PI
  local r = math.sqrt(dx * dx + dy * dy)

  return angle, r

end

return Math
