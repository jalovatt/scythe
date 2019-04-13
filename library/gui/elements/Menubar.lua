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
local Text = require("public.text")
local Table = require("public.table")

local Menubar = require("gui.element"):new()
function Menubar:new(props)

	local mnu = Table.copy({

    type = "Menubar",

    x = 0,
    y = 0,

    font = 2,
    col_txt = "txt",
    col_bg = "elm_frame",
    col_hover = "elm_fill",

    w = 256,
    h = 24,

    -- Optional parameters should be given default values to avoid errors/crashes:
    pad = 0,

  }, props)

  mnu.menus = mnu.menus or {}

  if mnu.shadow == nil then
    mnu.shadow = true
  end

  if mnu.fullwidth == nil then
    mnu.fullwidth = true
  end

	setmetatable(mnu, self)
	self.__index = self
	return mnu

end


function Menubar:init()

  if gfx.w == 0 then return end

  self.buff = self.buff or Buffer.get()

  -- We'll have to reset this manually since we're not running :init()
  -- until after the window is open
  local dest = gfx.dest

  gfx.dest = self.buff
  gfx.setimgdim(self.buff, -1, -1)


  -- Store some text measurements
  Font.set(self.font)

  self.tab = gfx.measurestr(" ") * 4

  for i = 1, #self.menus do

      self.menus[i].width = gfx.measurestr(self.menus[i].title)

  end

  self.w = self.w or 0
  self.w = self.fullwidth and (self.layer.window.cur_w - self.x) or math.max(self.w, self:measuretitles(nil, true))
  self.h = self.h or gfx.texth


  -- Draw the background + shadow
  gfx.setimgdim(self.buff, self.w, self.h * 2)

  Color.set(self.col_bg)

  gfx.rect(0, 0, self.w, self.h, true)

  Color.set("shadow")
  local r, g, b, a = table.unpack(Color.colors["shadow"])
  gfx.set(r, g, b, 1)
  gfx.rect(0, self.h + 1, self.w, self.h, true)
  gfx.muladdrect(0, self.h + 1, self.w, self.h, 1, 1, 1, a, 0, 0, 0, 0 )

  self.did_init = true

  gfx.dest = dest

end


function Menubar:ondelete()

	Buffer.release(self.buff)

end



function Menubar:draw()

  if not self.did_init then self:init() end

  local x, y = self.x, self.y
  local w, h = self.w, self.h

  -- Blit the menu background + shadow
  if self.shadow then

    for i = 1, Text.shadow_size do

      gfx.blit(self.buff, 1, 0, 0, h, w, h, x, y + i, w, h)

    end

  end

  gfx.blit(self.buff, 1, 0, 0, 0, w, h, x, y, w, h)

  -- Draw menu titles
  self:drawtitles()

  -- Draw highlight
  if self.mousemnu then self:drawhighlight() end

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


function Menubar:onresize()

    if self.fullwidth then
        self:init()
        self:redraw()
    end

end


------------------------------------
-------- Drawing methods -----------
------------------------------------


function Menubar:drawtitles()

    local x = self.x

    Font.set(self.font)
    Color.set(self.col_txt)

    for i = 1, #self.menus do

        local str = self.menus[i].title
        local str_w, _ = gfx.measurestr(str)

        gfx.x = x + (self.tab + self.pad) / 2
        gfx.y = self.y

        gfx.drawstr(str)

        x = x + str_w + self.tab + self.pad

    end

end


function Menubar:drawhighlight()

    if self.menus[self.mousemnu].title == "" then return end

    Color.set(self.col_hover)
    gfx.mode = 1
    --                                            Hover  Click
    gfx.a = (self.mouse_down and self.mousemnu) and 0.3 or 0.5

    gfx.rect(self.x + self.mousemnu_x, self.y, self.menus[self.mousemnu].width + self.tab + self.pad, self.h, true)

    gfx.a = 1
    gfx.mode = 0

end




------------------------------------
-------- Input methods -------------
------------------------------------


-- Make sure to disable the highlight if the mouse leaves
function Menubar:onupdate(state)

    if self.mousemnu and not self:isInside(state.mouse.x, state.mouse.y) then
        self.mousemnu = nil
        self.mousemnu_x = nil
        self:redraw()

        -- Skip the rest of the update loop for this elm
        return true
    end

end



function Menubar:onmouseup(state)

    if not self.mousemnu then return end

    gfx.x, gfx.y = self.x + self:measuretitles(self.mousemnu - 1, true), self.y + self.h
    local menu_str, sep_arr = self:prepmenu()
    local opt = gfx.showmenu(menu_str)

	if #sep_arr > 0 then opt = self:stripseps(opt, sep_arr) end

    if opt > 0 then

       self.menus[self.mousemnu].options[opt][2]()

    end

  self.mouse_down = false
	self:redraw()

end


function Menubar:onmousedown()

    self.mouse_down = true
    self:redraw()

end


function Menubar:onmouseover(state)

    local opt = self.mousemnu

    local x = state.mouse.x - self.x

    if  self.mousemnu_x and x > self:measuretitles(nil, true) then

        self.mousemnu = nil
        self.mousemnu_x = nil
        self:redraw()

        return

    end


    -- Iterate through the titles by overall width until we
    -- find which one the mouse is in.
    for i = 1, #self.menus do

        if x <= self:measuretitles(i, true) then

            self.mousemnu = i
            self.mousemnu_x = self:measuretitles(i - 1, true)

            if self.mousemnu ~= opt then self:redraw() end

            return
        end

    end

end


function Menubar:ondrag(state)

    self:onmouseover(state)

end


------------------------------------
-------- Menu methods --------------
------------------------------------


-- Return a table of the menu titles
function Menubar:gettitles()

   local tmp = {}
   for i = 1, #self.menus do
       tmp[i] = self.menus.title
   end

   return tmp

end


-- Returns the length of the specified number of menu titles, or
-- all of them if 'num' isn't given
-- Will include tabs + padding if tabs = true
function Menubar:measuretitles(num, tabs)

    local len = 0

    for i = 1, num or #self.menus do

        len = len + self.menus[i].width

    end

    return not tabs and len
                    or (len + (self.tab + self.pad) * (num or #self.menus))

end


-- Parse the current menu into a string for gfx.showmenu
-- Returns the string and a table of separators for offsetting the
-- value returned when the user clicks something.
function Menubar:prepmenu()

  local arr = self.menus[self.mousemnu].options

  local sep_arr = {}
	local str_arr = {}

	for i = 1, #arr do

        table.insert(str_arr, arr[i][1])

		if str_arr[#str_arr] == ""
		or string.sub(str_arr[#str_arr], 1, 1) == ">" then
			table.insert(sep_arr, i)
		end

		table.insert( str_arr, "|" )

	end

	local menu_str = table.concat( str_arr )

	return string.sub(menu_str, 1, string.len(menu_str) - 1), sep_arr

end


-- Adjust the returned value to account for any separators,
-- since gfx.showmenu doesn't count them
function Menubar:stripseps(opt, sep_arr)

    for i = 1, #sep_arr do
        if opt >= sep_arr[i] then
            opt = opt + 1
        else
            break
        end
    end

    return opt

end

return Menubar
