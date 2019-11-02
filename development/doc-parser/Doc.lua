local T = require("public.table")[2]

local Doc = {}

Doc.Segment = {}
Doc.Segment.__index = Doc.Segment
function Doc.Segment:new()
  local segment = {
    content = {
      name = nil,
      description = T{},
      param = T{},
      option = T{},
      ["return"] = T{},
      signature = nil,
    },
    currentTag = "description",
  }
  return setmetatable(segment, self)
end

function Doc.Segment:push(line)
  if not line:match("^%-%-") then
    self.content.signature = line
    self.content.name = self:nameFromSignature(line)
  else
    local tag, rest = line:match("@([^ ]+) (.+)")
    if tag then self.currentTag = tag end

    local content = tag and rest or line:match("^%-%-+ (.+)") or ''
    self.content[self.currentTag]:insert(content)
  end
end

function Doc.Segment:nameFromSignature(sig)
  local key = sig:match("(.+) = function") or sig:match("function (.+) ?%(")
  local stripped = key:match("^local (.+)")

  return stripped or key
end

function Doc.segmentsFromFile(filename)
  local segments = T{}
  local file = io.open(filename)
  local currentSegment

  for line in file:lines() do
    if line:match("^%-%-%-") then
      currentSegment = Doc.Segment:new()
      currentSegment:push(line)
    elseif currentSegment then
      if not line:match("^%-%-") then
        currentSegment:push(line)
        segments:insert(currentSegment)

        currentSegment = nil
      else
        currentSegment:push(line)
      end
    end
  end

  return segments
end

return Doc
