local function Msg(msg, indents)
  local str = string.rep("  ", indents or 0) .. msg
  if (reaper) then
    reaper.ShowConsoleMsg(str)
    reaper.ShowConsoleMsg("\n")
  else
    print(str)
  end
end

local Test = {}

function Test.describe(msg, cb)
  Msg(msg)
  cb()
end

function Test.xdescribe(msg)
  Msg(msg .. " (skipped)")
end

function Test.test(msg, cb)
  Msg(msg, 1)
  cb()
end

function Test.xtest(msg)
  Msg(msg .. " (skipped)", 1)
end

-- Returns true if a and b are equal to the given number of decimal places
local function almostEquals(a, b, places)
  return math.abs(a - b) <= (1 / (10^(places or 1)))
end

local function deepEquals(a, b)
  for k, v in pairs(a) do
    if b[k] ~= v then
      if (type(v) == "table" and type(b[k]) == "table") then
        if not deepEquals(v, b[k]) then
          return false
        end
      else
        return false
      end
    end
  end

  for k, v in pairs(b) do
    if (not a[k] and v ~= nil) then
      return false
    end
  end

  return true
end

local function almostDeepEquals(a, b, places)
  for k, v in pairs(a) do
    if b[k] ~= v and not (type(b[k]) == "number" and type(v) == "number" and almostEquals(b[k], v, places)) then
      if (type(v) == "table" and type(b[k]) == "table") then
        if not almostDeepEquals(v, b[k], places) then
          return false
        end
      else
        return false
      end
    end
  end

  for k, v in pairs(b) do
    if (not a[k] and v ~= nil) then
      return false
    end
  end

  return true
end

local function pass()
  return true
end

local function fail(str, a, b)
  Msg("fail", 2)
  Msg("expected " .. tostring(a) .. " " .. str .. " " .. tostring(b), 3)
  return false
end

local function matcher(exp)
  local matchers = {
    toEqual = function(compare)
      if (exp == compare) then
        return pass()
      else
        return fail("to equal", exp, compare)
      end
    end,
    toNotEqual = function(compare)
      if (exp == compare) then
        return fail("to not equal", exp, compare)
      else
        return pass()
      end
    end,
    toAlmostEqual = function(compare, places)
      if not places then places = 3 end
      if (almostEquals(exp, compare, places)) then
        return pass()
      else
        return fail("to almost equal (to "..places.." places)", exp, compare)
      end
    end,
    toDeepEqual = function(compare)
      if (deepEquals(exp, compare)) then
        return pass()
      else
        return fail("to deep-equal", exp, compare)
      end
    end,
    toNotDeepEqual = function(compare)
      if (deepEquals(exp, compare)) then
        return fail("to not deep-equal", exp, compare)
      else
        return pass()
      end
    end,
    toAlmostDeepEqual = function(compare, places)
      if not places then places = 3 end
      if (almostDeepEquals(exp, compare, places)) then
        return pass()
      else
        return fail("to almost deep-equal (to "..places.." places)", exp, compare)
      end
    end,
  }

  return matchers
end

function Test.expect(val)
  return matcher(val)
end

return Test
