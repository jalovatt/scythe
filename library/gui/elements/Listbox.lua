-- NoIndex: true

--[[	Lokasenna_GUI - Listbox class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Listbox

    Creation parameters:
	name, z, x, y, w, h[, list, multi, caption, pad]

]]--
local Buffer = require("gui.buffer")

local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local GFX = require("public.gfx")
local Text = require("public.text")
require("public.string")

-- Listbox - New
local Listbox = require("gui.element"):new()
function Listbox:new(props)

	local list = props

	list.type = "Listbox"

	list.x = list.x or 0
  list.y = list.y or 0
  list.w = list.w or 96
  list.h = list.h or 128

	list.list = list.list or {}
	list.retval = list.retval or {}

  list.multi = list.multi -- or false

	list.caption = list.caption or ""
	list.pad = list.pad or 4

  list.shadow = list.shadow or (list.shadow == nil)

	list.bg = list.bg or "elm_bg"
  list.cap_bg = list.cap_bg or "wnd_bg"
	list.color = list.color or "txt"

	-- Scrollbar fill
	list.col_fill = list.col_fill or "elm_fill"

	list.font_cap = list.font_cap or 3

	list.font_text = list.font_text or 4

	list.wnd_y = 1

	list.wnd_h, list.wnd_w, list.char_w = nil, nil, nil

	setmetatable(list, self)
	self.__index = self
	return list

end


function Listbox:init()

	-- If we were given a CSV, process it into a table
	if type(self.list) == "string" then self.list = self:CSVtotable(self.list) end

	local x, y, w, h = self.x, self.y, self.w, self.h

	self.buff = Buffer.get()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, w, h)

	Color.set(self.bg)
	gfx.rect(0, 0, w, h, 1)

	Color.set("elm_frame")
	gfx.rect(0, 0, w, h, 0)


end


function Listbox:ondelete()

	Buffer.release(self.buff)

end


function Listbox:draw()


	local x, y, w, h = self.x, self.y, self.w, self.h

	local caption = self.caption
	local pad = self.pad

	-- Some values can't be set in :init() because the window isn't
	-- open yet - measurements won't work.
	if not self.wnd_h then self:wnd_recalc() end

	-- Draw the caption
	if caption and caption ~= "" then self:drawcaption() end

	-- Draw the background and frame
	gfx.blit(self.buff, 1, 0, 0, 0, w, h, x, y)

	-- Draw the text
	self:drawtext()

	-- Highlight any selected items
	self:drawselection()

	-- Vertical scrollbar
	if #self.list > self.wnd_h then self:drawscrollbar() end

end


function Listbox:val(newval)

	if newval then
		--self.list = type(newval) == "string" and self:CSVtotable(newval) or newval
        if type(newval) == "table" then

            for i = 1, #self.list do
                self.retval[i] = newval[i] or nil
            end

        elseif type(newval) == "number" then

            newval = math.floor(newval)
            for i = 1, #self.list do
                self.retval[i] = (i == newval)
            end

        end

		self:redraw()

	else

		if self.multi then
			return self.retval
		else
			for k, v in pairs(self.retval) do
				return k
			end
		end

	end

end


---------------------------------
------ Input methods ------------
---------------------------------


function Listbox:onmouseup(state)

	if not self:overscrollbar(state.mouse.x) then

		local item = self:getitem(state.mouse.y)

		if self.multi then

			-- Ctrl
			if state.mouse.cap & 4 == 4 then

				self.retval[item] = not self.retval[item]

			-- Shift
			elseif state.mouse.cap & 8 == 8 then

				self:selectrange(item)

			else

				self.retval = {[item] = true}

			end

		else

			self.retval = {[item] = true}

		end

	end

	self:redraw()

end


function Listbox:onmousedown(state, scroll)

	-- If over the scrollbar, or we came from :ondrag with an origin point
	-- that was over the scrollbar...
	if scroll or self:overscrollbar(state.mouse.x) then

    local wnd_c = Math.round( ((state.mouse.y - self.y) / self.h) * #self.list  )
		self.wnd_y = math.floor( Math.clamp(1, wnd_c - (self.wnd_h / 2), #self.list - self.wnd_h + 1) )

		self:redraw()

	end

end


function Listbox:ondrag(state, last)

	if self:overscrollbar(last.mouse.x) then

		self:onmousedown(state, true)

	-- Drag selection?
	else


	end

	self:redraw()

end


function Listbox:onwheel(state)

	local dir = state.mouse.inc > 0 and -1 or 1

	-- Scroll up/down one line
	self.wnd_y = Math.clamp(1, self.wnd_y + dir, math.max(#self.list - self.wnd_h + 1, 1))

	self:redraw()

end


---------------------------------
-------- Drawing methods---------
---------------------------------


function Listbox:drawcaption()

	local str = self.caption

	Font.set(self.font_cap)
	local str_w, str_h = gfx.measurestr(str)
	gfx.x = self.x - str_w - self.pad
	gfx.y = self.y + self.pad
	Text.text_bg(str, self.cap_bg)

	if self.shadow then
		Text.drawWithShadow(str, self.color, "shadow")
	else
		Color.set(self.color)
		gfx.drawstr(str)
	end

end


function Listbox:drawtext()

	Color.set(self.color)
	Font.set(self.font_text)

	local tmp = {}
	for i = self.wnd_y, math.min(self:wnd_bottom() - 1, #self.list) do

		local str = tostring(self.list[i]) or ""
        tmp[#tmp + 1] = str

	end

	gfx.x, gfx.y = self.x + self.pad, self.y + self.pad
    local r = gfx.x + self.w - 2*self.pad
    local b = gfx.y + self.h - 2*self.pad
	gfx.drawstr( table.concat(tmp, "\n"), 0, r, b)

end


function Listbox:drawselection()

	local off_x, off_y = self.x + self.pad, self.y + self.pad
	local x, y, w, h

	w = self.w - 2 * self.pad

	Color.set("elm_fill")
	gfx.a = 0.5
	gfx.mode = 1
	-- for wnd_y, wnd_y + wnd_h do

	for i = 1, #self.list do

		if self.retval[i] and i >= self.wnd_y and i < self:wnd_bottom() then

			y = off_y + (i - self.wnd_y) * self.char_h
			gfx.rect(off_x, y, w, self.char_h, true)

		end

	end

	gfx.mode = 0
	gfx.a = 1

end


function Listbox:drawscrollbar()

	local x, y, w, h = self.x, self.y, self.w, self.h
	local sx, sy, sw, sh = x + w - 8 - 4, y + 4, 8, h - 12


	-- Draw a gradient to fade out the last ~16px of text
	Color.set("elm_bg")
	for i = 0, 15 do
		gfx.a = i/15
		gfx.line(sx + i - 15, y + 2, sx + i - 15, y + h - 4)
	end

	gfx.rect(sx, y + 2, sw + 2, h - 4, true)

	-- Draw slider track
	Color.set("tab_bg")
	GFX.roundrect(sx, sy, sw, sh, 4, 1, 1)
	Color.set("elm_outline")
	GFX.roundrect(sx, sy, sw, sh, 4, 1, 0)

	-- Draw slider fill
	local fh = (self.wnd_h / #self.list) * sh - 4
	if fh < 4 then fh = 4 end
	local fy = sy + ((self.wnd_y - 1) / #self.list) * sh + 2

	Color.set(self.col_fill)
	GFX.roundrect(sx + 2, fy, sw - 4, fh, 2, 1, 1)

end


---------------------------------
-------- Helpers ----------------
---------------------------------


-- Updates internal values for the window size
function Listbox:wnd_recalc()

	Font.set(self.font_text)

    self.char_w, self.char_h = gfx.measurestr("_")
	self.wnd_h = math.floor((self.h - 2*self.pad) / self.char_h)
	self.wnd_w = math.floor(self.w / self.char_w)

end


-- Get the bottom edge of the window (in rows)
function Listbox:wnd_bottom()

	return self.wnd_y + self.wnd_h

end


-- Determine which item the user clicked
function Listbox:getitem(y)

	--local item = math.floor( ( (y - self.y) / self.h ) * self.wnd_h) + self.wnd_y

	Font.set(self.font_text)

	local item = math.floor(	(y - (self.y + self.pad))
								/	self.char_h)
				+ self.wnd_y

	item = Math.clamp(1, item, #self.list)

	return item

end


-- Split a CSV into a table
function Listbox:CSVtotable(str)

  return str:split(",")

end


-- Is the mouse over the scrollbar (true) or the text area (false)?
function Listbox:overscrollbar(x)

	return (#self.list > self.wnd_h and x >= (self.x + self.w - 12))

end


-- Selects from the first selected item to the current mouse position
function Listbox:selectrange(mouse)

	-- Find the first selected item
	local first
	for k, v in pairs(self.retval) do
		first = first and math.min(k, first) or k
	end

	if not first then first = 1 end

	self.retval = {}

	-- Select everything between the first selected item and the mouse
	for i = mouse, first, (first > mouse and 1 or -1) do
		self.retval[i] = true
	end

end

return Listbox
