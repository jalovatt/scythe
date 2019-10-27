-- NoIndex: true

require("public.string")
local _, T = require("public.table"):unpack()

local Menu = {}

Menu.parse = {}

local psvPattern = "[^|]*"

-- Accepts a |-separated string. Returns the given string along
-- with a table of any separators it found.
function Menu.parseString(str)
  local separators = T{}

  local i = 1
  for item in str:gmatch(psvPattern) do
	-- for i = 1, #menuArr do
		if item == ""
		or item:sub(1, 1) == ">" then
			separators:insert(i)
    end

    i = i + 1
	end

	return str, separators
end

--[[
  Parses a table into a string for gfx.showmenu

  Accepts an *indexed* table and optional caption key. If given, the caption
  key will be used for each table entry to get the displayed text in the menu:

  local options = {
      {theCaption = "a", value = 11},
      ...

  local parsed, separators = Menu.parseTable(options, "theCaption")

  If captionkey is not specified, will use the table entry itself.
]]--
function Menu.parseTable(menuArr, captionKey)
  local separators = T{}
	local menus = T{}

  for i = 1, #menuArr do
    local val
    if captionKey then
      val = menuArr[i][captionKey]
    else
      val = menuArr[i]
    end

    menus:insert(tostring(val))

    if (type(val) == "string"
      and (menus[#menus] == "" or menus[#menus]:sub(1, 1) == ">")
    ) then
			separators:insert(i)
		end
	end

	return menus:concat("|"), separators
end

-- Adjust the returned value to account for any separators,
-- since gfx.showmenu doesn't count them
function Menu.getTrueIndex(parsed, val, separators)
  for i = 1, #separators do
    if val >= separators[i] then
      val = val + 1
    else
      break
    end
  end

  local i = 1
  local optionOut
  for option in parsed:gmatch(psvPattern) do
    if i == val then
      optionOut = option
      break
    end

    i = i + 1
  end

  return val, optionOut
end

-- Wraps gfx.showmenu with some additional processing to account for separators
-- and submenus in the returned value since Reaper doesn't do it for us
-- Accepts a menu in either string or table form
-- For nested tables, will use a given captionKey and valKey to read item
-- captions and the output value, i.e:
--[[
    local options = {
      {caption = "a", value = 11},
      {caption = ">b"},
      {caption = "c", value = 13},
      {caption = "<d", value = 14},
      {caption = ""},
      {caption = "e", value = 15},
      {caption = "f", value = 16},
    }

    local index, value = Menu.showMenu(options, "caption", "value")
]]--
-- For strings, returns the index and value of the chosen option:
--[[
    local str = "1|2||3|4|5||6.12435213613"
    local index, value = Menu.showMenu(str)

    User clicks 1 --> 1, 1
    User clicks 3 --> 4, 3
    User clicks 6.12... --> 8, 6.12435213613
]]--

function Menu.showMenu(menuIn, captionKey, valKey)
  local parsed, separators
  if type(menuIn) == "string" then
    parsed, separators = Menu.parseString(menuIn)
    local rawIdx = gfx.showmenu(parsed)
    local trueIdx = Menu.getTrueIndex(parsed, rawIdx, separators)

    local options = parsed:split("|")
    return trueIdx, options[trueIdx]
  else
    parsed, separators = Menu.parseTable(menuIn, captionKey)

    local rawIdx = gfx.showmenu(parsed)
    local trueIdx = Menu.getTrueIndex(parsed, rawIdx, separators)

    if valKey then
      return trueIdx, menuIn[trueIdx][valKey]
    else
      return trueIdx, menuIn[trueIdx]
    end
  end
end

return Menu
