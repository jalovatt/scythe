local Table, T = require("public.table"):unpack()

local Md = {}

local tagTemplates = T{}
tagTemplates.description = {
  header = nil,
  item = function (desc) return desc end,
}
tagTemplates.param = {
  header = "| **Required** | []() | []() |\n| --- | --- | --- |",
  item = function (param) return "| " .. param.name .. " | " .. param.type .. (param.description and (" | " .. param.description .. " |") or " |   |") end,
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
      mdTag:insert(template.item(tag))
    end)

    acc[tagType] = mdTag:concat("\n")
    return acc
  end, T{})
end

function Md.parseSegment(signature, tags)
  Msg(signature)
  local parsedTags = Md.parseTags(tags)

  local out = T{
    "### "..signature,
    "",
    parsedTags.description,
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

  return out:concat("\n")
end

return Md
