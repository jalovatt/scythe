local Table, T = require("public.table"):unpack()

local function nameFromSignature(sig)
  local key = sig:match("(.+) = function") or sig:match("function (.+) ?%(")
  local stripped = key:match("^local (.+)")

  return stripped or key
end

local escapes = T{
  ["|"] = "&#124;",
  ["\n"] = "<br>",
}

local function escapeForTable(str)
  return escapes:reduce(function(acc, new, old)
    return acc:gsub(old, new)
  end, str)
end

local function paramParser(paramStr)
  local param = {}
  param.name, param.type, param.description = paramStr:match("([^ ]+) +([^ ]+) *(.*)")
  param.type = escapeForTable(param.type)
  param.description = escapeForTable(param.description)
  return param
end

local function returnParser(returnStr)
  local ret = {}
  ret.type, ret.description = returnStr:match("([^ ]+) *(.*)")
  ret.type = ret.type:gsub("|", "&#124;")
  ret.description = ret.description:gsub("|", "&#124;")
  return ret
end

local parseTag = {
  description = function(desc) return desc end,
  param = paramParser,
  option = paramParser,
  ["return"] = returnParser
}

local Segment = {}
Segment.__index = Segment
function Segment:new(line)
  local segment = {
    name = nil,
    rawTags = T{
      description = T{},
      param = T{},
      option = T{},
      ["return"] = T{},
    },
    signature = nil,
    tags = T{
      description = T{},
      param = T{},
      option = T{},
      ["return"] = T{},
    },
    currentTag = {
      type = "description",
      content = T{line},
    },
  }
  return setmetatable(segment, self)
end

function Segment:closeTag()
  local tagType = self.currentTag.type
  local tag = self.currentTag.content:concat(tagType == "description" and "\n" or " ")

  self.rawTags[self.currentTag.type]:insert(tag)

  -- function Segment:parseTags()
  --   self.rawTags:forEach(function(v, k) self.tags[k] = parseTag[k](v) end)
  -- end
  local parsed = parseTag[tagType](tag)
  self.tags[tagType]:insert(parsed)
  self.currentTag = nil
end

function Segment:push(line)
  if line:match("^@") then
    self:closeTag()
    local tag, rest = line:match("@([^ ]+) (.+)")

    self.currentTag = T{
      type = tag,
      content = T{rest}
    }
  else
    self.currentTag.content:insert((line ~= "" and line or "\n"))
  end
end

--[[
Given:
-- @param t     table    This is a table.
-- @param cb    function    This is a callback function.
-- @option iter iterator  Defaults to `ipairs`
-- @return      value|boolean     Returns `t`
-- @return      key
Table.find = function(t, cb, iter)
Expected:
Table.find(t, cb[, iter])
]]--
function Segment:generateSignature()
  local args = self.args:reduce(function (acc, arg)
    local argType = self.tags.param:find(function(v) return v.name == arg end)
      and 1
      or 2

    acc[argType]:insert(arg)
    return acc
  end, {T{}, T{}})

  local optionSig = ""
  if #args[2] > 0 then
    optionSig = ((#args[1] > 0) and "[, " or "[") .. args[2]:concat(", ") .. "]"
  end

  return self.name .. "(" .. args[1]:concat(", ") .. optionSig .. ")"
end

function Segment:finalize(rawSignature)
  self:closeTag()
  self.args = rawSignature:match("%((.-)%)"):split("[^ ,]+")
  self.name = nameFromSignature(rawSignature)
  self.signature = self:generateSignature()
end

local Doc = {}
function Doc.fromFile(path)
  local segments = T{}
  local file, err = io.open(path)
  if not file then
    Msg("Error opening " .. path .. ": " .. err)
    return nil
  end

  local currentSegment
  local n = 0
  local isModule = false

  for line in file:lines() do
    n = n + 1
    if not isModule then
      if line:match("@module") then
        isModule = true
      elseif n == 50 then
        break
      end
    elseif line:match("^%-%-%-") then
      currentSegment = Segment:new(line:match("^%-%-%- (.+)"))
    elseif currentSegment then
      if not line:match("^%-%-") then
        currentSegment:finalize(line)
        segments:insert(currentSegment)

        currentSegment = nil
      else
        currentSegment:push(line:match("^%-%-+ (.+)") or "")
      end
    end
  end

  return #segments > 0 and segments or nil
end

return Doc
