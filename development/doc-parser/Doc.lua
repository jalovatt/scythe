local Table, T = require("public.table"):unpack()

local function nameFromSignature(sig)
  local key = sig:match("(.+) = function") or sig:match("function (.+) ?%(")
  local stripped = key:match("^local (.+)")

  return stripped or key
end

local parseTag = {
  description = function(desc)
    return desc:join("\n")
  end,
  param = function(params)
    return params:reduce(function(acc, paramStr)
      local param = {}
      param.name, param.type, param.description = paramStr:match("([^ ]+) +([^ ]+) *(.*)")
      acc:insert(param)
      return acc
    end, T{})
  end,
  option = function(option) end,
  ["return"] = function(returns)
    return returns:reduce(function(acc, returnStr)
      local ret = {}
      ret.type, ret.description = returnStr:match("([^ ]+) *(.*)")
      acc:insert(ret)
      return acc
    end, T{})
  end,
  signature = function(signature) end,
}

local Segment = {}
Segment.__index = Segment
function Segment:new(line)
  local segment = {
    name = nil,
    rawContent = T{
      description = T{},
      param = T{},
      option = T{},
      ["return"] = T{},
      signature = nil,
    },
    parsedContent = T{},
    currentTag = {
      type = "description",
      content = T{line},
    },
  }
  return setmetatable(segment, self)
end

function Segment:closeTag()
  self.rawContent[self.currentTag.type]:insert(self.currentTag.content:concat(" "))
  self.currentTag = {
    type = tag,
    content = T{},
  }
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

function Segment:finalize(line)
  self:closeTag()
  self.rawContent.signature = line
  self.name = nameFromSignature(line)

  self:process()
end

function Segment:process()
  self.rawContent:forEach(function(v, k) self.parsedContent[k] = parseTag[k](v) end)
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
