local T = require("public.table")[2]

local String = {}
setmetatable(String, {__index = getmetatable("")})
setmetatable(string, {__index = String})

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

String.splitLines = function(s)
  local out = T{}
  for line in s:gmatch(linesPattern) do
    out[#out + 1] = line
  end

  return out
end
