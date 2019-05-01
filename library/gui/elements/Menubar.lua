-- NoIndex: true

--[[	Lokasenna_GUI - Menubar clas

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Menubar

    Creation parameters:
	name, z, x, y, menus[, w, h, pad]

]]--

local Buffer = require("gui.buffer")

local Font = require("public.font")
local Color = require("public.color")
-- local Table = require("public.table")
local Config = require("gui.config")

local Menubar = require("gui.element"):new()
Menubar.__index = Menubar
Menubar.defaultProps = {
  name = "menubar",
  type = "Menubar",

  x = 0,
  y = 0,

  font = 2,
  textColor = "txt",
  backgroundColor = "elmFrame",
  hoverColor = "elmFill",

  w = 256,
  h = 24,

  pad = 0,

  shadow = true,
  fullWidth = true,

  menus = {},

}

function Menubar:new(props)

	local mnu = self:addDefaultProps(props)

  return self:assignChild(mnu)

end


function Menubar:init()

  if gfx.w == 0 then return end

  self.buffer = self.buffer or Buffer.get()

  -- We'll have to reset this manually since we're not running :init()
  -- until after the window is open
  local dest = gfx.dest

  gfx.dest = self.buffer
  gfx.setimgdim(self.buffer, -1, -1)


  -- Store some text measurements
  Font.set(self.font)

  self.tab = gfx.measurestr(" ") * 4

  for i = 1, #self.menus do

    self.menus[i].width = gfx.measurestr(self.menus[i].title)

  end

  self.w = self.fullWidth and (self.layer.window.currentW - self.x) or self:measureTitles(nil, true)
  self.h = self.h or gfx.texth

  -- Draw the background + shadow
  gfx.setimgdim(self.buffer, self.w, self.h * 2)

  Color.set(self.backgroundColor)

  gfx.rect(0, 0, self.w, self.h, true)

  Color.set("shadow")
  local r, g, b, a = table.unpack(Color.colors["shadow"])
  gfx.set(r, g, b, 1)
  gfx.rect(0, self.h + 1, self.w, self.h, true)
  gfx.muladdrect(0, self.h + 1, self.w, self.h, 1, 1, 1, a, 0, 0, 0, 0 )

  self.didInit = true

  gfx.dest = dest

end


function Menubar:onDelete()

	Buffer.release(self.buffer)

end



function Menubar:draw()

  if not self.didInit then self:init() end

  local x, y = self.x, self.y
  local w, h = self.w, self.h

  -- Blit the menu background + shadow
  if self.shadow then

    for i = 1, Config.shadowSize do

      gfx.blit(self.buffer, 1, 0, 0, h, w, h, x, y + i, w, h)

    end

  end

  gfx.blit(self.buffer, 1, 0, 0, 0, w, h, x, y, w, h)

  -- Draw menu titles
  self:drawTitles()

  -- Draw highlight
  if self.mouseMenu then self:drawHover() end

end


function Menubar:val(newval)

  if newval and type(newval) == "table" then

    self.menus = newval
    self.w, self.h = nil, nil
    self:init()
    self:redraw()

  else

    return self.menus

  end

end


function Menubar:onResize()

  if self.fullWidth then
    self:init()
    self:redraw()
  end

end


------------------------------------
-------- Drawing methods -----------
------------------------------------


function Menubar:drawTitles()

  local currentX = self.x

  Font.set(self.font)
  Color.set(self.textColor)

  for i = 1, #self.menus do

    local str = self.menus[i].title
    local strWidth, strHeight = gfx.measurestr(str)

    gfx.x = currentX + (self.tab + self.pad) / 2
    gfx.y = self.y + (self.h - strHeight) / 2

    gfx.drawstr(str)

    currentX = currentX + strWidth + self.tab + self.pad

  end

end


function Menubar:drawHover()

    if self.menus[self.mouseMenu].title == "" then return end

    Color.set(self.hoverColor)
    gfx.mode = 1
    --                                            Hover  Click
    gfx.a = (self.mouseDown and self.mouseMenu) and 0.3 or 0.5

    gfx.rect(
      self.x + self.mouseMenuX,
      self.y,
      self.menus[self.mouseMenu].width + self.tab + self.pad,
      self.h,
      true
    )

    gfx.a = 1
    gfx.mode = 0

end




------------------------------------
-------- Input methods -------------
------------------------------------


-- Make sure to disable the highlight if the mouse leaves
function Menubar:onUpdate(state)

  if self.mouseMenu and not self:isInside(state.mouse.x, state.mouse.y) then
    self.mouseMenu = nil
    self.mouseMenuX = nil
    self:redraw()

    -- Skip the rest of the update loop for this elm
    return true
  end

end



function Menubar:onMouseUp(state)

  if not self.mouseMenu then return end

  gfx.x, gfx.y = self.x + self:measureTitles(self.mouseMenu - 1, true), self.y + self.h
  local menuStr, separators = self:prepMenu()
  local opt = gfx.showmenu(menuStr)

	if #separators > 0 then opt = self:stripSeparators(opt, separators) end

  if opt > 0 then

    self.menus[self.mouseMenu].options[opt][2]()

  end

  self.mouseDown = false
	self:redraw()

end


function Menubar:onMouseDown()

    self.mouseDown = true
    self:redraw()

end


function Menubar:onMouseOver(state)

  local opt = self.mouseMenu

  local x = state.mouse.x - self.x

  if  self.mouseMenuX and x > self:measureTitles(nil, true) then

    self.mouseMenu = nil
    self.mouseMenuX = nil
    self:redraw()

    return

  end


  -- Iterate through the titles by overall width until we
  -- find which one the mouse is in.
  for i = 1, #self.menus do

    if x <= self:measureTitles(i, true) then

      self.mouseMenu = i
      self.mouseMenuX = self:measureTitles(i - 1, true)

      if self.mouseMenu ~= opt then self:redraw() end

      return
    end

  end

end


function Menubar:onDrag(state)

  self:onMouseOver(state)

end


------------------------------------
-------- Menu methods --------------
------------------------------------


-- Return a table of the menu titles
function Menubar:gettitles()

  local titles = {}
  for i = 1, #self.menus do
    titles[i] = self.menus.title
  end

  return titles

end


-- Returns the length of the specified number of menu titles, or
-- all of them if 'num' isn't given
-- Will include tabs + padding if tabs = true
function Menubar:measureTitles(num, tabs)

  local len = 0

  for i = 1, num or #self.menus do
    len = len + self.menus[i].width
  end

  return not tabs
    and len
    or (len + (self.tab + self.pad) * (num or #self.menus))

end


-- Parse the current menu into a string for gfx.showmenu
-- Returns the string and a table of separators for offsetting the
-- value returned when the user clicks something.
function Menubar:prepMenu()

  local arr = self.menus[self.mouseMenu].options

  local separators = {}
	local menus = {}

	for i = 1, #arr do

    table.insert(menus, arr[i][1])

		if menus[#menus] == ""
		or string.sub(menus[#menus], 1, 1) == ">" then
			table.insert(separators, i)
		end

		table.insert( menus, "|" )

	end

	local menuStr = table.concat( menus )

	return string.sub(menuStr, 1, string.len(menuStr) - 1), separators

end


-- Adjust the returned value to account for any separators,
-- since gfx.showmenu doesn't count them
function Menubar:stripSeparators(opt, separators)

  for i = 1, #separators do
    if opt >= separators[i] then
      opt = opt + 1
    else
      break
    end
  end

  return opt

end

return Menubar
