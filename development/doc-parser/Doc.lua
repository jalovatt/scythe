local Table, T = require("public.table"):unpack()

local function nameFromSignature(sig)
  local key = sig:match("(.+) = function") or sig:match("function (.+) ?%(")
  local stripped = key:match("^local (.+)")

  return stripped or key
end

local function paramParser(params)
  return params:reduce(function(acc, paramStr)
    local param = {}
    param.name, param.type, param.description = paramStr:match("([^ ]+) +([^ ]+) *(.*)")
    acc:insert(param)
    return acc
  end, T{})
end

local parseTag = {
  description = function(desc) return desc:join("\n") end,
  param = paramParser,
  option = paramParser,
  ["return"] = function(returns)
    return returns:reduce(function(acc, returnStr)
      local ret = {}
      ret.type, ret.description = returnStr:match("([^ ]+) *(.*)")
      acc:insert(ret)
      return acc
    end, T{})
  end,
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
      signature = nil
    },
    tags = T{},
    currentTag = {
      type = "description",
      content = T{line},
    },
  }
  return setmetatable(segment, self)
end

function Segment:closeTag()
  self.rawTags[self.currentTag.type]:insert(self.currentTag.content:concat(" "))
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
    self.currentTag.content:insert(line)
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

  local optionSig = ((#args[1] > 0) and "[, " or "[") .. args[2]:concat(", ") .. "]"
  self.signature = self.name .. "(" .. args[1]:concat(", ") .. optionSig .. ")"

  Msg(self.signature)
end

function Segment:finalize(rawSignature)
  self:closeTag()
  self.args = rawSignature:match("%((.+)%)"):split("[^ ,]+")
  self.name = nameFromSignature(rawSignature)
  self:parseTags()
  self.signature = self:generateSignature()
end

function Segment:parseTags()
  self.rawTags:forEach(function(v, k) self.tags[k] = parseTag[k](v) end)
end

local Doc = {}
function Doc.segmentsFromFile(filename)
  local segments = T{}
  local file = io.open(filename)
  local currentSegment

  for line in file:lines() do
    if line:match("^%-%-%-") then
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

  return segments
end

return Doc
