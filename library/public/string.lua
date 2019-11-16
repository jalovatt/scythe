-- NoIndex: true
-- @module

local T = require("public.table")[2]

local String = {}
setmetatable(String, {__index = getmetatable("")})
setmetatable(string, {__index = String})

--- Splits a string at each occurrence of a given separator
-- @param s string
-- @option separator string Any number of characters (_not_ a standard Lua pattern).
--
-- - Separators are not included in the split strings
-- - Sequential occurrences of the separator are split as empty strings
--
-- If no pattern is given, splits at every character
-- @return array A list of split strings
String.split = function(s, separator)
  local out = T{}

  local matchPattern
  if not separator or separator == "" or separator == "." then
    matchPattern = "."
  else
    matchPattern = ("[^" .. separator .. "]*")
  end

  for segment in s:gmatch(matchPattern) do
    out[#out + 1] = segment
  end

  return out
end

local linesPattern = "([^\r\n]*)\r?\n?"

--- Splits a string at each new line
-- @param s string
-- @return array A list of split strings
String.splitLines = function(s)
  local out = T{}
  for line in s:gmatch(linesPattern) do
    out[#out + 1] = line
  end

  return out
end

return String
