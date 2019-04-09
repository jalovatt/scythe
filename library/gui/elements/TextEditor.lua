-- NoIndex: true

--[[	Lokasenna_GUI - TextEditor class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/TextEditor

    Creation parameters:
	name, z, x, y, w, h[, text, caption, pad]

]]--

local Buffer = require("gui.buffer")

local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local GFX = require("public.gfx")
local Text = require("public.text")
local Const = require("public.const")

local TextEditor = require("gui.element"):new()
function TextEditor:new(props)

	local txt = props

	txt.type = "TextEditor"

	txt.x = txt.x or 0
  txt.y = txt.y or 0
  txt.w = txt.w or 256
  txt.h = txt.h or 128

	txt.retval = txt.retval or ""

	txt.caption = txt.caption or ""
	txt.pad = txt.pad or 4

  if txt.shadow == nil then
    txt.shadow = true
  end

	txt.bg = txt.bg or "elm_bg"
  txt.cap_bg = txt.cap_bg or "wnd_bg"
	txt.color = txt.color or "txt"

	-- Scrollbar fill
	txt.col_fill = txt.col_fill or "elm_fill"

	txt.font_cap = txt.font_cap or 3

	-- Forcing a safe monospace font to make our lives easier
	txt.font_text = "monospace"

	txt.wnd_pos = {x = 0, y = 1}
	txt.caret = {x = 0, y = 1}

	txt.char_h, txt.wnd_h, txt.wnd_w, txt.char_w = nil, nil, nil, nil

	txt.focus = false

	txt.undo_limit = 20
	txt.undo_states = {}
	txt.redo_states = {}

	txt.blink = 0

	setmetatable(txt, self)
	self.__index = self
	return txt

end


function TextEditor:init()

	-- Process the initial string; split it into a table by line
	if type(self.retval) == "string" then self:val(self.retval) end

	local x, y, w, h = self.x, self.y, self.w, self.h

	self.buff = Buffer.get()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*w, h)

	Color.set(self.bg)
	gfx.rect(0, 0, 2*w, h, 1)

	Color.set("elm_frame")
	gfx.rect(0, 0, w, h, 0)

	Color.set("elm_fill")
	gfx.rect(w, 0, w, h, 0)
	gfx.rect(w + 1, 1, w - 2, h - 2, 0)


end


function TextEditor:ondelete()

	Buffer.release(self.buff)

end


function TextEditor:draw()

	-- Some values can't be set in :init() because the window isn't
	-- open yet - measurements won't work.
	if not self.wnd_h then self:wnd_recalc() end

	-- Draw the caption
	if self.caption and self.caption ~= "" then self:drawcaption() end

	-- Draw the background + frame
	gfx.blit(self.buff, 1, 0, (self.focus and self.w or 0), 0,
            self.w, self.h, self.x, self.y)

	-- Draw the text
	self:drawtext()

	-- Caret
	-- Only needs to be drawn for half of the blink cycle
	if self.focus then
       --[[
        --Draw line highlight a la NP++ ??
        Color.set("elm_bg")
        gfx.a = 0.2
        gfx.mode = 1


        gfx.mode = 0
        gfx.a = 1
       ]]--

        -- Selection
        if self.sel_s and self.sel_e then

            self:drawselection()

        end

        if self.show_caret then self:drawcaret() end

    end


	-- Scrollbars
	self:drawscrollbars()

end


function TextEditor:val(newval)

	if newval then
		self:seteditorstate(
            type(newval) == "table" and newval
                                    or self:stringtotable(newval))
		self:redraw()
	else
		return table.concat(self.retval, "\n")
	end

end


function TextEditor:onupdate()

	if self.focus then

		if self.blink == 0 then
			self.show_caret = true
			self:redraw()
		elseif self.blink == math.floor(GUI.txt_blink_rate / 2) then
			self.show_caret = false
			self:redraw()
		end
		self.blink = (self.blink + 1) % GUI.txt_blink_rate

	end

end


function TextEditor:lostfocus()

	self:redraw()

end




-----------------------------------
-------- Input methods ------------
-----------------------------------


function TextEditor:onmousedown(state)

	-- If over the scrollbar, or we came from :ondrag with an origin point
	-- that was over the scrollbar...
	local scroll = self:overscrollbar(state.mouse.x, state.mouse.y)
	if scroll then

        self:setscrollbar(scroll, state)

    else

        -- Place the caret
        self.caret = self:getcaret(state.mouse.x, state.mouse.y)

        -- Reset the caret so the visual change isn't laggy
        self.blink = 0

        -- Shift+click to select text
        if state.mouse.cap & 8 == 8 and self.caret then

                self.sel_s = {x = self.caret.x, y = self.caret.y}
                self.sel_e = {x = self.caret.x, y = self.caret.y}

        else

            self:clearselection()

        end

    end

    self:redraw()

end


function TextEditor:ondoubleclick()

	self:selectword()

end


function TextEditor:ondrag(state, last)

	local scroll = self:overscrollbar(last.mouse.x, last.mouse.y)
	if scroll then

        self:setscrollbar(scroll, state)

	-- Select from where the mouse is now to where it started
	else

		self.sel_s = self:getcaret(last.mouse.x, last.mouse.y)
		self.sel_e = self:getcaret(state.mouse.x, last.mouse.y)

	end

	self:redraw()

end


function TextEditor:ontype(state)

    local char = state.kb.char
    local mod = state.mouse.cap

	-- Non-typeable / navigation chars
	if self.keys[char] then

		local shift = mod & 8 == 8

		if shift and not self.sel_s then
			self.sel_s = {x = self.caret.x, y = self.caret.y}
		end

		-- Flag for some keys (clipboard shortcuts) to skip
		-- the next section
        local bypass = self.keys[char](self, state)

		if shift and char ~= Const.char.BACKSPACE and char ~= Const.char.TAB then

			self.sel_e = {x = self.caret.x, y = self.caret.y}

		elseif not bypass then

			self:clearselection()

		end

	-- Typeable chars
	elseif Math.clamp(32, char, 254) == char then

		if self.sel_s then self:deleteselection() end

		self:insertchar(char)
        -- Why are we doing this when the selection was just deleted?
		--self:clearselection()


	end
	self:windowtocaret()

	-- Reset the caret so the visual change isn't laggy
	self.blink = 0

end


function TextEditor:onwheel(state)

	-- Ctrl -- maybe zoom?
	if state.mouse.cap & 4 == 4 then

		--[[ Buggy, disabled for now
		local font = self.font_text
		font = 	(type(font) == "string" and GUI.fonts[font])
			or	(type(font) == "table" and font)

		if not font then return end

		local dir = inc > 0 and 4 or -4

		font[2] = Math.clamp(8, font[2] + dir, 30)

		self.font_text = font

		self:wnd_recalc()
		]]--

	-- Shift -- Horizontal scroll
	elseif state.mouse.cap & 8 == 8 then

		local len = self:getmaxlength()

		if len <= self.wnd_w then return end

		-- Scroll right/left
		local dir = state.mouse.inc > 0 and 3 or -3
		self.wnd_pos.x = Math.clamp(0, self.wnd_pos.x + dir, len - self.wnd_w + 4)

	-- Vertical scroll
	else

		local len = self:getwndlength()

		if len <= self.wnd_h then return end

		-- Scroll up/down
		local dir = state.mouse.inc > 0 and -3 or 3
		self.wnd_pos.y = Math.clamp(1, self.wnd_pos.y + dir, len - self.wnd_h + 1)

	end

	self:redraw()

end




------------------------------------
-------- Drawing methods -----------
------------------------------------


function TextEditor:drawcaption()

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


function TextEditor:drawtext()

	Color.set(self.color)
	Font.set(self.font_text)

	local tmp = {}
	for i = self.wnd_pos.y, math.min(self:wnd_bottom() - 1, #self.retval) do

		local str = tostring(self.retval[i]) or ""
		tmp[#tmp + 1] = string.sub(str, self.wnd_pos.x + 1, self:wnd_right() - 1)

	end

	gfx.x, gfx.y = self.x + self.pad, self.y + self.pad
	gfx.drawstr( table.concat(tmp, "\n") )

end


function TextEditor:drawcaret()

	local caret_wnd = self:adjusttowindow(self.caret)

	if caret_wnd.x and caret_wnd.y then

		Color.set("txt")

		gfx.rect(	self.x + self.pad + (caret_wnd.x * self.char_w),
					self.y + self.pad + (caret_wnd.y * self.char_h),
					self.insert_caret and self.char_w or 2,
					self.char_h - 2)

	end

end


function TextEditor:drawselection()

	local off_x, off_y = self.x + self.pad, self.y + self.pad
	local x, y, w, h

	Color.set("elm_fill")
	gfx.a = 0.5
	gfx.mode = 1

	-- Get all the selection boxes that need to be drawn
	local coords = self:getselection()

	for i = 1, #coords do

		-- Make sure at least part of this line is visible
		if self:selectionvisible(coords[i]) then

			-- Convert from char/row coords to actual pixels
			x, y =	off_x + (coords[i].x - self.wnd_pos.x) * self.char_w,
					off_y + (coords[i].y - self.wnd_pos.y) * self.char_h

									-- Really kludgy, but it fixes a weird issue
									-- where wnd_pos.x > 0 was drawing all the widths
									-- one character too short
			w =		(coords[i].w + (self.wnd_pos.x > 0 and 1 or 0)) * self.char_w

			-- Keep the selection from spilling out past the scrollbar
            -- ***recheck this, the self.x doesn't make sense***
			w = math.min(w, self.x + self.w - x - self.pad)

			h =	self.char_h

			gfx.rect(x, y, w, h, true)

		end

	end

	gfx.mode = 0

	-- Later calls to Color.set should handle this, but for
	-- some reason they aren't always.
	gfx.a = 1

end


function TextEditor:drawscrollbars()

	-- Do we need to be here?
	local max_w, txt_h = self:getmaxlength(), self:getwndlength()
	local vert, horz = 	txt_h > self.wnd_h,
						max_w > self.wnd_w


	local x, y, w, h = self.x, self.y, self.w, self.h
	local vx, vy, vw, vh = x + w - 8 - 4, y + 4, 8, h - 16
	local hx, hy, hw, hh = x + 4, y + h - 8 - 4, w - 16, 8
	local fade_w = 12
	local _

    -- Only draw the empty tracks if we don't need scroll bars
	if not (vert or horz) then goto tracks end

	-- Draw a gradient to fade out the last ~16px of text
	Color.set("elm_bg")
	for i = 0, fade_w do

		gfx.a = i/fade_w

		if vert then

			gfx.line(vx + i - fade_w, y + 2, vx + i - fade_w, y + h - 4)

			-- Fade out the top if we're not at wnd_pos.y = 1
			_ = self.wnd_pos.y > 1 and
				gfx.line(x + 2, y + 2 + fade_w - i, x + w - 4, y + 2 + fade_w - i)

		end

		if horz then

			gfx.line(x + 2, hy + i - fade_w, x + w - 4, hy + i - fade_w)

			-- Fade out the left if we're not at wnd_pos.x = 0
			_ = self.wnd_pos.x > 0 and
				gfx.line(x + 2 + fade_w - i, y + 2, x + 2 + fade_w - i, y + h - 4)

		end

	end

	_ = vert and gfx.rect(vx, y + 2, vw + 2, h - 4, true)
	_ = horz and gfx.rect(x + 2, hy, w - 4, hh + 2, true)


    ::tracks::

	-- Draw slider track
	Color.set("tab_bg")
	GFX.roundrect(vx, vy, vw, vh, 4, 1, 1)
	GFX.roundrect(hx, hy, hw, hh, 4, 1, 1)
	Color.set("elm_outline")
	GFX.roundrect(vx, vy, vw, vh, 4, 1, 0)
	GFX.roundrect(hx, hy, hw, hh, 4, 1, 0)


	-- Draw slider fill
	Color.set(self.col_fill)

	if vert then
		local fh = (self.wnd_h / txt_h) * vh - 4
		if fh < 4 then fh = 4 end
		local fy = vy + ((self.wnd_pos.y - 1) / txt_h) * vh + 2

		GFX.roundrect(vx + 2, fy, vw - 4, fh, 2, 1, 1)
	end

	if horz then
		local fw = (self.wnd_w / (max_w + 4)) * hw - 4
		if fw < 4 then fw = 4 end
		local fx = hx + (self.wnd_pos.x / (max_w + 4)) * hw + 2

		GFX.roundrect(fx, hy + 2, fw, hh - 4, 2, 1, 1)
	end

end




------------------------------------
-------- Selection methods ---------
------------------------------------


function TextEditor:getselectioncoords()

	local sx, sy = self.sel_s.x, self.sel_s.y
	local ex, ey = self.sel_e.x, self.sel_e.y

	-- Make sure the Start is before the End
	if sy > ey then
		sx, sy, ex, ey = ex, ey, sx, sy
	elseif sy == ey and sx > ex then
		sx, ex = ex, sx
	end

    return sx, sy, ex, ey

end


-- Figure out what portions of the text are selected
function TextEditor:getselection()

    local sx, sy, ex, ey = self:getselectioncoords()

	local x, w
	local sel_coords = {}

	local function insert_coords(x, y, w)
		table.insert(sel_coords, {x = x, y = y, w = w})
	end

	-- Eliminate the easiest case - start and end are the same line
	if sy == ey then

		x = Math.clamp(self.wnd_pos.x, sx, self:wnd_right())
		w = Math.clamp(x, ex, self:wnd_right()) - x

		insert_coords(x, sy, w)


	-- ...fine, we'll do it the hard way
	else

		-- Start
		x = Math.clamp(self.wnd_pos.x, sx, self:wnd_right())
		w = math.min(self:wnd_right(), #(self.retval[sy] or "")) - x

		insert_coords(x, sy, w)


		-- Any intermediate lines are clearly full
		for i = self.wnd_pos.y, self:wnd_bottom() - 1 do

			x, w = nil, nil

			-- Is this line within the selection?
			if i > sy and i < ey then

				w = math.min(self:wnd_right(), #(self.retval[i] or "")) - self.wnd_pos.x
				insert_coords(self.wnd_pos.x, i, w)

			-- We're past the selection
			elseif i >= ey then

				break

			end

		end


		-- End
		x = self.wnd_pos.x
		w = math.min(self:wnd_right(), ex) - self.wnd_pos.x
		insert_coords(x, ey, w)


	end

	return sel_coords


end


-- Make sure at least part of this selection block is within the window
function TextEditor:selectionvisible(coords)

	return 		    coords.w > 0                            -- Selection has width,
			      and coords.x + coords.w > self.wnd_pos.x    -- doesn't end to the left
            and coords.x < self:wnd_right()             -- doesn't start to the right
			      and coords.y >= self.wnd_pos.y              -- and is on a visible line
			      and coords.y < self:wnd_bottom()

end


function TextEditor:selectall()

	self.sel_s = {x = 0, y = 1}
	self.caret = {x = 0, y = 1}
	self.sel_e = {	x = string.len(self.retval[#self.retval]),
					y = #self.retval}


end


function TextEditor:selectword()

	local str = self.retval[self.caret.y] or ""

	if not str or str == "" then return 0 end

	local sx = string.find( str:sub(1, self.caret.x), "%s[%S]+$") or 0

	local ex =	(	string.find( str, "%s", sx + 1)
			or		string.len(str) + 1 )
				- (self.wnd_pos.x > 0 and 2 or 1)	-- Kludge, fixes length issues

	self.sel_s = {x = sx, y = self.caret.y}
	self.sel_e = {x = ex, y = self.caret.y}

end


function TextEditor:clearselection()

	self.sel_s, self.sel_e = nil, nil

end


function TextEditor:deleteselection()

	if not (self.sel_s and self.sel_e) then return 0 end

	self:storeundostate()

    local sx, sy, ex, ey = self:getselectioncoords()

	-- Easiest case; single line
	if sy == ey then

		self.retval[sy] =   string.sub(self.retval[sy] or "", 1, sx)..
                            string.sub(self.retval[sy] or "", ex + 1)

	else

		self.retval[sy] =   string.sub(self.retval[sy] or "", 1, sx)..
                            string.sub(self.retval[ey] or "", ex + 1)
		for i = sy + 1, ey do
			table.remove(self.retval, sy + 1)
		end

	end

	self.caret.x, self.caret.y = sx, sy

	self:clearselection()
	self:windowtocaret()

end


function TextEditor:getselectedtext()

    local sx, sy, ex, ey = self:getselectioncoords()

	local tmp = {}

	for i = 0, ey - sy do

		tmp[i + 1] = self.retval[sy + i]

	end

	tmp[1] = string.sub(tmp[1], sx + 1)
	tmp[#tmp] = string.sub(tmp[#tmp], 1, ex - (sy == ey and sx or 0))

	return table.concat(tmp, "\n")

end


function TextEditor:toclipboard(cut)

    if self.sel_s and self:SWS_clipboard() then

        local str = self:getselectedtext()
        reaper.CF_SetClipboard(str)
        if cut then self:deleteselection() end

    end

end


function TextEditor:fromclipboard()

    if self:SWS_clipboard() then

        -- reaper.SNM_CreateFastString( str )
        -- reaper.CF_GetClipboardBig( output )
        local fast_str = reaper.SNM_CreateFastString("")
        local str = reaper.CF_GetClipboardBig(fast_str)
        reaper.SNM_DeleteFastString(fast_str)

        self:insertstring(str, true)

    end

end

------------------------------------
-------- Window/Pos Helpers --------
------------------------------------


-- Updates internal values for the window size
function TextEditor:wnd_recalc()

	Font.set(self.font_text)
	self.char_w, self.char_h = gfx.measurestr("i")
	self.wnd_h = math.floor((self.h - 2*self.pad) / self.char_h)
	self.wnd_w = math.floor(self.w / self.char_w)

end


-- Get the right edge of the window (in chars)
function TextEditor:wnd_right()

	return self.wnd_pos.x + self.wnd_w

end


-- Get the bottom edge of the window (in rows)
function TextEditor:wnd_bottom()

	return self.wnd_pos.y + self.wnd_h

end


-- Get the length of the longest line
function TextEditor:getmaxlength()

	local w = 0

	-- Slightly faster because we don't care about order
	for k, v in pairs(self.retval) do
		w = math.max(w, string.len(v))
	end

	-- Pad the window out a little
	return w + 2

end


-- Add 2 to the table length so the horizontal scrollbar isn't in the way
function TextEditor:getwndlength()

	return #self.retval + 2

end


-- See if a given pair of coords is in the visible window
-- If so, adjust them from absolute to window-relative
-- If not, returns nil
function TextEditor:adjusttowindow(coords)

	local x, y = coords.x, coords.y
	x = (Math.clamp(self.wnd_pos.x, x, self:wnd_right() - 3) == x)
						and x - self.wnd_pos.x
						or nil

	-- Fixes an issue with the position being one space to the left of where it should be
	-- when the window isn't at x = 0. Not sure why.
	--x = x and (x + (self.wnd_pos.x == 0 and 0 or 1))

	y = (Math.clamp(self.wnd_pos.y, y, self:wnd_bottom() - 1) == y)
						and y - self.wnd_pos.y
						or nil

	return {x = x, y = y}

end


-- Adjust the window if the caret has been moved off-screen
function TextEditor:windowtocaret()

	-- Horizontal
	if self.caret.x < self.wnd_pos.x + 4 then
		self.wnd_pos.x = math.max(0, self.caret.x - 4)
	elseif self.caret.x > (self:wnd_right() - 4) then
		self.wnd_pos.x = self.caret.x + 4 - self.wnd_w
	end

	-- Vertical
	local bot = self:wnd_bottom()
	local adj = (	(self.caret.y < self.wnd_pos.y) and -1	)
			or	(	(self.caret.y >= bot) and 1	)
			or	(	(bot > self:getwndlength() and -(bot - self:getwndlength() - 1) ) )

	if adj then self.wnd_pos.y = Math.clamp(1, self.wnd_pos.y + adj, self.caret.y) end

end


-- TextEditor - Get the closest character position to the given coords.
function TextEditor:getcaret(x, y)

	local tmp = {}

	tmp.x = math.floor(		((x - self.x) / self.w ) * self.wnd_w)
        + self.wnd_pos.x
	tmp.y = math.floor(		(y - (self.y + self.pad))
						          /	self.char_h)
			  + self.wnd_pos.y

	tmp.y = Math.clamp(1, tmp.y, #self.retval)
	tmp.x = Math.clamp(0, tmp.x, #(self.retval[tmp.y] or ""))

	return tmp

end


-- Is the mouse over either of the scrollbars?
-- Returns "h", "v", or false
function TextEditor:overscrollbar(x, y)

	if	self:getwndlength() > self.wnd_h
	and x >= (self.x + self.w - 12) then

		return "v"

	elseif 	self:getmaxlength() > self.wnd_w
	and	y >= (self.y + self.h - 12) then

		return "h"

	end

end


function TextEditor:setscrollbar(scroll, state)

    -- Vertical scroll
    if scroll == "v" then

        local len = self:getwndlength()
        local wnd_c = Math.round( ((state.mouse.y - self.y) / self.h) * len  )
        self.wnd_pos.y = Math.round(
                            Math.clamp(	1,
                                        wnd_c - (self.wnd_h / 2),
                                        len - self.wnd_h + 1
                                    )
                                    )

    -- Horizontal scroll
    else
    --self.caret.x + 4 - self.wnd_w

        local len = self:getmaxlength()
        local wnd_c = Math.round( ((state.mouse.x - self.x) / self.w) * len   )
        self.wnd_pos.x = Math.round(
                            Math.clamp(	0,
                                        wnd_c - (self.wnd_w / 2),
                                        len + 4 - self.wnd_w
                                    )
                                    )

    end


end




------------------------------------
-------- Char/String Helpers -------
------------------------------------


-- Split a string by line into a table
function TextEditor:stringtotable(str)

    str = self:sanitizetext(str)
	local pattern = "([^\r\n]*)\r?\n?"
	local tmp = {}
	for line in string.gmatch(str, pattern) do
		table.insert(tmp, line )
	end

	return tmp

end


-- Insert a string at the caret, deleting any existing selection
-- i.e. Paste
function TextEditor:insertstring(str, move_caret)

	self:storeundostate()

    str = self:sanitizetext(str)

	if self.sel_s then self:deleteselection() end

    local sx, sy = self.caret.x, self.caret.y

	local tmp = self:stringtotable(str)

	local pre, post =	string.sub(self.retval[sy] or "", 1, sx),
						string.sub(self.retval[sy] or "", sx + 1)

	if #tmp == 1 then

		self.retval[sy] = pre..tmp[1]..post
		if move_caret then self.caret.x = self.caret.x + #tmp[1] end

	else

		self.retval[sy] = tostring(pre)..tmp[1]
		table.insert(self.retval, sy + 1, tmp[#tmp]..tostring(post))

		-- Insert our paste lines backwards so sy+1 is always correct
		for i = #tmp - 1, 2, -1 do
			table.insert(self.retval, sy + 1, tmp[i])
		end

		if move_caret then
			self.caret = {	x =	string.len(tmp[#tmp]),
							y =	self.caret.y + #tmp - 1}
		end

	end

end


-- Insert typeable characters
function TextEditor:insertchar(char)

	self:storeundostate()

	local str = self.retval[self.caret.y] or ""

	local a, b = str:sub(1, self.caret.x),
                 str:sub(self.caret.x + (self.insert_caret and 2 or 1))
	self.retval[self.caret.y] = a..string.char(char)..b
	self.caret.x = self.caret.x + 1

end


-- Place the caret at the end of the current line
function TextEditor:carettoend()
	--[[
	return #(self.retval[self.caret.y] or "") > 0
		and #self.retval[self.caret.y]
		or 0
	]]--

    return string.len(self.retval[self.caret.y] or "")

end


-- Replace any characters that we're unable to reproduce properly
function TextEditor:sanitizetext(str)

    if type(str) == "string" then

        return str:gsub("\t", "    ")

    elseif type(str) == "table" then

        local tmp = {}
        for i = 1, #str do

            tmp[i] = str[i]:gsub("\t", "    ")

            return tmp

        end

    end

end


-- Backspace by up to four " " characters, if present.
function TextEditor:backtab()

    local str = self.retval[self.caret.y]
    local pre, post = string.sub(str, 1, self.caret.x), string.sub(str, self.caret.x + 1)

    local space
    pre, space = string.match(pre, "(.-)(%s*)$")

    pre = pre .. (space and string.sub(space, 1, -5) or "")

    self.caret.x = string.len(pre)
    self.retval[self.caret.y] = pre..post

end


function TextEditor:ctrlchar(state, func, ...)

    if state.mouse.cap & 4 == 4 then
        func(self, ... and table.unpack({...}))

        -- Flag to bypass the "clear selection" logic in :ontype()
        return true

    else
        self:insertchar(state.kb.char)
    end

end


-- Non-typing key commands
-- A table of functions is more efficient to access than using really
-- long if/then/else structures.
TextEditor.keys = {

	[Const.char.LEFT] = function(self)

		if self.caret.x < 1 and self.caret.y > 1 then
			self.caret.y = self.caret.y - 1
			self.caret.x = self:carettoend()
		else
			self.caret.x = math.max(self.caret.x - 1, 0)
		end

	end,

	[Const.char.RIGHT] = function(self)

		if self.caret.x == self:carettoend() and self.caret.y < self:getwndlength() then
			self.caret.y = self.caret.y + 1
			self.caret.x = 0
		else
			self.caret.x = math.min(self.caret.x + 1, self:carettoend() )
		end

	end,

	[Const.char.UP] = function(self)

		if self.caret.y == 1 then
			self.caret.x = 0
		else
			self.caret.y = math.max(1, self.caret.y - 1)
			self.caret.x = math.min(self.caret.x, self:carettoend() )
		end

	end,

	[Const.char.DOWN] = function(self)

		if self.caret.y == self:getwndlength() then
			self.caret.x = string.len(self.retval[#self.retval])
		else
			self.caret.y = math.min(self.caret.y + 1, #self.retval)
			self.caret.x = math.min(self.caret.x, self:carettoend() )
		end

	end,

	[Const.char.HOME] = function(self)

		self.caret.x = 0

	end,

	[Const.char.END] = function(self)

		self.caret.x = self:carettoend()

	end,

	[Const.char.PGUP] = function(self)

		local caret_off = self.caret and (self.caret.y - self.wnd_pos.y)

		self.wnd_pos.y = math.max(1, self.wnd_pos.y - self.wnd_h)

		if caret_off then
			self.caret.y = self.wnd_pos.y + caret_off
			self.caret.x = math.min(self.caret.x, string.len(self.retval[self.caret.y]))
		end

	end,

	[Const.char.PGDN] = function(self)

		local caret_off = self.caret and (self.caret.y - self.wnd_pos.y)

		self.wnd_pos.y = Math.clamp(1, self:getwndlength() - self.wnd_h + 1, self.wnd_pos.y + self.wnd_h)

		if caret_off then
			self.caret.y = self.wnd_pos.y + caret_off
			self.caret.x = math.min(self.caret.x, string.len(self.retval[self.caret.y]))
		end

	end,

	[Const.char.BACKSPACE] = function(self)
		self:storeundostate()

		-- Is there a selection?
		if self.sel_s and self.sel_e then

			self:deleteselection()

		-- If we have something to backspace, delete it
		elseif self.caret.x > 0 then

			local str = self.retval[self.caret.y]
			self.retval[self.caret.y] = str:sub(1, self.caret.x - 1)..
                                        str:sub(self.caret.x + 1, -1)
			self.caret.x = self.caret.x - 1

		-- Beginning of the line; backspace the contents to the prev. line
		elseif self.caret.x == 0 and self.caret.y > 1 then

			self.caret.x = #self.retval[self.caret.y - 1]
			self.retval[self.caret.y - 1] = self.retval[self.caret.y - 1] .. (self.retval[self.caret.y] or "")
			table.remove(self.retval, self.caret.y)
			self.caret.y = self.caret.y - 1

		end

	end,

	[Const.char.TAB] = function(self, state)

        -- Disabled until Reaper supports this properly
		--self:insertchar(9)

        if state.mouse.cap & 8 == 8 then
            self:backtab()
        else
            self:insertstring("    ", true)
		end

	end,

	[Const.char.INSERT] = function(self)

		self.insert_caret = not self.insert_caret

	end,

	[Const.char.DELETE] = function(self)

		self:storeundostate()

		-- Is there a selection?
		if self.sel_s then

			self:deleteselection()

		-- Deleting on the current line
		elseif self.caret.x < self:carettoend() then

			local str = self.retval[self.caret.y] or ""
			self.retval[self.caret.y] = str:sub(1, self.caret.x) ..
                                        str:sub(self.caret.x + 2)

		elseif self.caret.y < self:getwndlength() then

			self.retval[self.caret.y] = self.retval[self.caret.y] ..
                                        (self.retval[self.caret.y + 1] or "")
			table.remove(self.retval, self.caret.y + 1)

		end

	end,

	[Const.char.RETURN] = function(self)

		self:storeundostate()

		if sel_s then self:deleteselection() end

		local str = self.retval[self.caret.y] or ""
		self.retval[self.caret.y] = str:sub(1, self.caret.x)
		table.insert(self.retval, self.caret.y + 1, str:sub(self.caret.x + 1) )
		self.caret.y = self.caret.y + 1
		self.caret.x = 0

	end,

	-- A -- Select All
	[1] = function(self, state)

        return self:ctrlchar(state, self.selectall)

	end,

	-- C -- Copy
	[3] = function(self, state)

		return self:ctrlchar(state, self.toclipboard)

	end,

	-- V -- Paste
	[22] = function(self, state)

		return self:ctrlchar(state, self.fromclipboard)

	end,

	-- X -- Cut
	[24] = function(self, state)

		return self:ctrlchar(state, self.toclipboard, true)

	end,

	-- Y -- Redo
	[25] = function (self, state)

		return self:ctrlchar(state, self.redo)

	end,

	-- Z -- Undo
	[26] = function (self, state)

		return self:ctrlchar(state, self.undo)

	end
}




------------------------------------
-------- Misc. Functions -----------
------------------------------------


function TextEditor:undo()

	if #self.undo_states == 0 then return end
	table.insert(self.redo_states, self:geteditorstate() )
	local state = table.remove(self.undo_states)

	self.retval = state.retval
	self.caret = state.caret

	self:windowtocaret()

end


function TextEditor:redo()

	if #self.redo_states == 0 then return end
	table.insert(self.undo_states, self:geteditorstate() )
	local state = table.remove(self.redo_states)
	self.retval = state.retval
	self.caret = state.caret

	self:windowtocaret()

end


function TextEditor:storeundostate()

	table.insert(self.undo_states, self:geteditorstate() )
	if #self.undo_states > self.undo_limit then table.remove(self.undo_states, 1) end
	self.redo_states = {}

end


function TextEditor:geteditorstate()

	local state = { retval = {} }
	for k,v in pairs(self.retval) do
		state.retval[k] = v
	end
	state.caret = {x = self.caret.x, y = self.caret.y}

	return state

end


function TextEditor:seteditorstate(retval, caret, wnd_pos, sel_s, sel_e)

    self.retval = retval or {""}
    self.wnd_pos = wnd_pos or {x = 0, y = 1}
    self.caret = caret or {x = 0, y = 1}
    self.sel_s = sel_s or nil
    self.sel_e = sel_e or nil

end



-- See if we have a new-enough version of SWS for the clipboard functions
-- (v2.9.7 or greater)
function TextEditor:SWS_clipboard()

	if GUI.SWS_exists then
		return true
	else

		reaper.ShowMessageBox(	"Clipboard functions require the SWS extension, v2.9.7 or newer."..
									"\n\nDownload the latest version at http://www.sws-extension.org/index.php",
									"Sorry!", 0)
		return false

	end

end

return TextEditor