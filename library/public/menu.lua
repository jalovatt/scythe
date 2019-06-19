require("public.string")
local _, T = require("public.table"):unpack()

local Menu = {}

Menu.parse = {}

-- Accepts a |-separated string. Returns the given string along
-- with a table of any separators it found.
function Menu.parseString(str)
  local separators = T{}

  local i = 1
  for item in str:gmatch("[^|]*") do
	-- for i = 1, #menuArr do
		if item == ""
		or item:sub(1, 1) == ">" then
			separators:insert(i)
    end

    i = i + 1
	end

	return str, separators
end

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
function Menu.getTrueValue(val, separators)
  for i = 1, #separators do
    if val >= separators[i] then
      val = val + 1
    else
      break
    end
  end

  return val
end

-- Wraps gfx.showmenu with some additional processing to account for separators
-- and submenus in the returned value since Reaper doesn't do it for us
-- Accepts a menu in either string or table form
-- For nested tables, will use a given captionKey and valKey to read item
-- captions and the output value, i.e:
--[[
    local arrIn = {
      {caption = "a", value = 11},
      {caption = ">b"},
      {caption = "c", value = 13},
      {caption = "<d", value = 14},
      {caption = ""},
      {caption = "e", value = 15},
      {caption = "f", value = 16},
    }

    local value, index = Menu.showMenu(arrIn, "caption", "value")
]]--

function Menu.showMenu(menuIn, captionKey, valKey)
  local parsed, separators
  if type(menuIn) == "string" then
    parsed, separators = Menu.parseString(menuIn)
    local rawVal = gfx.showmenu(parsed)

    return Menu.getTrueValue(rawVal, separators)
  else
    parsed, separators = Menu.parseTable(menuIn, captionKey)

    local rawVal = gfx.showmenu(parsed)
    local trueVal = Menu.getTrueValue(rawVal, separators)

    if valKey then
      return menuIn[trueVal][valKey], trueVal
    else
      return menuIn[trueVal], trueVal
    end
  end
end

return Menu
