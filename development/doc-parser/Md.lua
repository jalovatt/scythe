local Table, T = require("public.table"):unpack()

local Md = {}

local tagTemplates = T{}
tagTemplates.description = {
  header = nil,
  item = function (desc) return desc end,
}
tagTemplates.param = {
  header = "| **Required** | []() | []() |\n| --- | --- | --- |",
  item = function (param)
    return "| " .. param.name .. " | " .. param.type .. (param.description and (" | " .. param.description .. " |") or " |   |") end,
}
tagTemplates.option = {
  header = "| **Optional** | []() | []() |\n| --- | --- | --- |",
  item = tagTemplates.param.item,
}
tagTemplates["return"] = {
  header = "| **Returns** | []() |\n| --- | --- |",
  item = function (ret) return "| " .. ret.type .. (ret.description and (" | " .. ret.description .. " |") or " |   |") end,
}

function Md.parseTags(tags)
  return tags:reduce(function(acc, tagArr, tagType)
    if #tagArr == 0 then return acc end

    local template = tagTemplates[tagType]
    local mdTag = T{ template.header }

    tagArr:orderedForEach(function(tag)
      local parsed = template.item(tag)
      mdTag:insert(parsed)
    end)

    acc[tagType] = mdTag:concat("\n")
    return acc
  end, T{})
end

-- This syntax is used by Docsify
local function customHeadingId(name)
  return " :id=" .. name:lower():gsub("[.:]", "-")
end

local function segmentWrapper(name, signature)
  local open = T{
    "<section class=\"segment\">\n",
    "### " .. signature .. customHeadingId(name),
    "",
  }

  local close = "\n</section>"

  return open:concat("\n"), close
end

function Md.parseSegment(name, signature, tags)
  local parsedTags = Md.parseTags(tags)

  local open, close = segmentWrapper(name, signature)

  local out = T{
    open,
    parsedTags.description
  }

  if parsedTags.param then
    out:insert("")
    out:insert(parsedTags.param)
  end

  if parsedTags.option then
    out:insert("")
    out:insert(parsedTags.option)
  end

  if parsedTags["return"] then
    out:insert("")
    out:insert(parsedTags["return"])
  end

  out:insert(close)

  return out:concat("\n")
end

function Md.parseHeader(header)
  Msg(header.description)
  local out = T{
    "# " .. header.name,
    "```lua",
    header.tags.require
      and header.tags.require:concat("\n")
      or ("local " .. header.name .. " = require(" .. header.requirePath .. ")"),
    "```",
    header.tags.description and header.tags.description:concat("\n") or "",
  }

  return out
end

return Md
