-- NoIndex: true

local T = require("public.table")[2]

local String = {}
setmetatable(String, {__index = getmetatable("")})
setmetatable(string, {__index = String})

-- Splits a string into table elements at each occurrence of the given pattern
-- (the pattern is not included in the table strings)
-- If no pattern is given, splits at every character
String.split = function(s, pattern)
  local out = T{}

  local matchPattern
  if not pattern or pattern == "" or pattern == "." then
    matchPattern = "."
  else
    matchPattern = ("[^" .. pattern .. "]+")
  end

  for segment in s:gmatch(matchPattern) do
    out[#out + 1] = segment
  end

  return out
end

local linesPattern = "([^\r\n]*)\r?\n?"

-- Splits a string into table elements by line
String.splitLines = function(s)
  local out = T{}
  for line in s:gmatch(linesPattern) do
    out[#out + 1] = line
  end

  return out
end
