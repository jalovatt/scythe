local Math = {}

-- Odds are you don't need too much precision here
-- If you do, just specify Math.pi = math.pi() in your code
Math.pi = 3.14159

-- Round a number to the nearest integer (or optional decimal places)
Math.round = function (num, places)

  if not places then
    return num > 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
  else
    places = 10^places
    return num > 0 and math.floor(num * places + 0.5)
                    or math.ceil(num * places - 0.5) / places
  end

end


-- Returns 'val', rounded to the nearest multiple of 'snap'
Math.nearestmultiple = function (val, snap)

  local int, frac = math.modf(val / snap)
  return (math.floor( frac + 0.5 ) == 1 and int + 1 or int) * snap

end



-- Make sure num is between min and max
-- I think it will return the correct value regardless of what
-- order you provide the values in.
Math.clamp = function (num, min, max)

  if min > max then min, max = max, min end
  return math.min(math.max(num, min), max)

end


-- Returns an ordinal string (i.e. 30 --> 30th)
Math.ordinal = function (num)
  local rem = num % 10
  num = Math.round(num)

  local endings = {
    [1] = "st",
    [2] = "nd",
    [13] = "th",
    [3] = "rd",
  }

  return num .. (endings[rem] or "")
end


--[[
    Takes an angle in radians (omit Pi) and a radius, returns x, y
    Will return coordinates relative to an origin of (0,0), or absolute
    coordinates if an origin point is specified
]]--
Math.polar2cart = function (angle, radius, ox, oy)

  local theta = angle * Math.pi
  local x = radius * math.cos(theta)
  local y = radius * math.sin(theta)


  if ox and oy then x, y = x + ox, y + oy end

  return x, y

end


--[[
    Takes cartesian coords, with optional origin coords, and returns
    an angle (in radians) and radius. The angle is given without reference
    to Pi; that is, pi/4 rads would return as simply 0.25
]]--
Math.cart2polar = function (x, y, ox, oy)

  local dx, dy = x - (ox or 0), y - (oy or 0)

  local angle = math.atan(dy, dx) / Math.pi
  local r = math.sqrt(dx * dx + dy * dy)

  return angle, r

end

return Math
