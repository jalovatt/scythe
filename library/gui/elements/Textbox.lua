-- NoIndex: true

--[[	Lokasenna_GUI - Textbox class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Textbox

    Creation parameters:
	name, z, x, y, w, h[, caption, pad]

]]--

local Buffer = require("gui.buffer")

local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local Text = require("public.text")
-- local Table = require("public.table")

local Config = require("gui.config")

local Const = require("public.const")

local TextUtils = require("gui.elements._text_utils")

local Textbox = require("gui.element"):new()
Textbox.__index = Textbox
Textbox.defaultProps = {

  type = "Textbox",
  x = 0,
  y = 0,
  w = 96,
  h = 24,
  retval = "",
  caption = "Textbox",
  pad = 4,
  bg = "wnd_bg",
  color = "txt",
  font_a = 3,
  font_b = "monospace",
  cap_pos = "left",
  undo_limit = 20,
  undo_states = {},
  redo_states = {},
  wnd_pos = 0,
  caret = 0,
  sel_s = nil,
  sel_e = nil,
  char_h = nil,
  wnd_h = nil,
  wnd_w = nil,
  char_w = nil,
  focus = false,
  blink = 0,
  shadow = true,
}

function Textbox:new(props)
	local txt = self:addDefaultProps(props)

	return self:assignChild(txt)
end


function Textbox:init()

	local w, h = self.w, self.h

	self.buff = Buffer.get()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*w, h)

	Color.set("elm_bg")
	gfx.rect(0, 0, 2*w, h, 1)

	Color.set("elm_frame")
	gfx.rect(0, 0, w, h, 0)

	Color.set("elm_fill")
	gfx.rect(w, 0, w, h, 0)
	gfx.rect(w + 1, 1, w - 2, h - 2, 0)

  -- Make sure we calculate this ASAP to avoid errors with
  -- dynamically-generated textboxes
  if gfx.w > 0 then self:wnd_recalc() end

end


function Textbox:ondelete()

	Buffer.release(self.buff)

end


function Textbox:draw()

	-- Some values can't be set in :init() because the window isn't
	-- open yet - measurements won't work.
	if not self.wnd_w then self:wnd_recalc() end

	if self.caption and self.caption ~= "" then self:drawcaption() end

	-- Blit the textbox frame, and make it brighter if focused.
	gfx.blit(self.buff, 1, 0, (self.focus and self.w or 0), 0,
           self.w, self.h, self.x, self.y)

  if self.retval ~= "" then self:drawtext() end

	if self.focus then

		if self.sel_s then self:drawselection() end
		if self.show_caret then self:drawcaret() end

	end

  self:drawgradient()

end


function Textbox:val(newval)

	if newval then
    self:seteditorstate(tostring(newval))
		self:redraw()
	else
		return self.retval
	end

end


-- Just for making the caret blink
function Textbox:onupdate()

	if self.focus then

		if self.blink == 0 then
			self.show_caret = true
			self:redraw()
		elseif self.blink == math.floor(Config.txt_blink_rate / 2) then
			self.show_caret = false
			self:redraw()
		end
		self.blink = (self.blink + 1) % Config.txt_blink_rate

	end

end

-- Make sure the box highlight goes away
function Textbox:lostfocus()

    self:redraw()

end



------------------------------------
-------- Input methods -------------
------------------------------------


function Textbox:onmousedown(state)

  self.caret = self:getcaret(state.mouse.x)

  -- Reset the caret so the visual change isn't laggy
  self.blink = 0

  -- Shift+click to select text
  if state.mouse.cap & 8 == 8 and self.caret then

    self.sel_s, self.sel_e = self.caret, self.caret

  else

    self.sel_s, self.sel_e = nil, nil

  end

  self:redraw()

end


function Textbox:ondoubleclick(state)

	self:selectword(state)

end


function Textbox:ondrag(state)

	self.sel_s = self:getcaret(state.mouse.ox, state.mouse.oy)
  self.sel_e = self:getcaret(state.mouse.x, state.mouse.y)

	self:redraw()

end


function Textbox:ontype(state)

	local char = state.kb.char

  -- Navigation keys, Return, clipboard stuff, etc
  if self.keys[char] then

    local shift = state.mouse.cap & 8 == 8

    if shift and not self.sel then
      self.sel_s = self.caret
    end

    -- Flag for some keys (clipboard shortcuts) to skip
    -- the next section
    local bypass = self.keys[char](self, state)

    if shift and char ~= Const.char.BACKSPACE then

      self.sel_e = self.caret

    elseif not bypass then

      self.sel_s, self.sel_e = nil, nil

    end

  -- Typeable chars
  elseif Math.clamp(32, char, 254) == char then

    if self.sel_s then self:deleteselection() end

    self:insertchar(char)

  end
  self:windowtocaret()

  -- Make sure no functions crash because they got a type==number
  self.retval = tostring(self.retval)

  -- Reset the caret so the visual change isn't laggy
  self.blink = 0

end


function Textbox:onwheel(state)

  local len = string.len(self.retval)

  if len <= self.wnd_w then return end

  -- Scroll right/left
  local dir = state > 0 and 3 or -3
  self.wnd_pos = Math.clamp(0, self.wnd_pos + dir, len + 2 - self.wnd_w)

  self:redraw()

end




------------------------------------
-------- Drawing methods -----------
------------------------------------


function Textbox:drawcaption()

  local caption = self.caption

  Font.set(self.font_a)

  local str_w, str_h = gfx.measurestr(caption)

  if self.cap_pos == "left" then
    gfx.x = self.x - str_w - self.pad
    gfx.y = self.y + (self.h - str_h) / 2

  elseif self.cap_pos == "top" then
    gfx.x = self.x + (self.w - str_w) / 2
    gfx.y = self.y - str_h - self.pad

  elseif self.cap_pos == "right" then
    gfx.x = self.x + self.w + self.pad
    gfx.y = self.y + (self.h - str_h) / 2

  elseif self.cap_pos == "bottom" then
    gfx.x = self.x + (self.w - str_w) / 2
    gfx.y = self.y + self.h + self.pad

  end

  Text.text_bg(caption, self.bg)

  if self.shadow then
    Text.drawWithShadow(caption, self.color, "shadow")
  else
    Color.set(self.color)
    gfx.drawstr(caption)
  end

end


function Textbox:drawtext()

	Color.set(self.color)
	Font.set(self.font_b)

  local str = string.sub(self.retval, self.wnd_pos + 1)

  -- I don't think self.pad should affect the text at all. Looks weird,
  -- messes with the amount of visible text too much.
	gfx.x = self.x + 4 -- + self.pad
	gfx.y = self.y + (self.h - gfx.texth) / 2
  local r = gfx.x + self.w - 8 -- - 2*self.pad
  local b = gfx.y + gfx.texth

	gfx.drawstr(str, 0, r, b)

end


function Textbox:drawcaret()

  local caret_wnd = self:adjusttowindow(self.caret)

  if caret_wnd then

      Color.set("txt")

      local caret_h = self.char_h - 2

      gfx.rect(   self.x + (caret_wnd * self.char_w) + 4,
                  self.y + (self.h - caret_h) / 2,
                  self.insert_caret and self.char_w or 2,
                  caret_h)

  end

end


function Textbox:drawselection()

  Color.set("elm_fill")
  gfx.a = 0.5
  gfx.mode = 1

  local s, e = self.sel_s, self.sel_e

  if e < s then s, e = e, s end


  local x = Math.clamp(self.wnd_pos, s, self:wnd_right())
  local w = Math.clamp(x, e, self:wnd_right()) - x

  if self:selectionvisible(x, w) then

    -- Convert from char-based coords to actual pixels
    x = self.x + (x - self.wnd_pos) * self.char_w + 4

    local h = self.char_h - 2

    local y = self.y + (self.h - h) / 2

    w = w * self.char_w
    w = math.min(w, self.x + self.w - x - self.pad)



    gfx.rect(x, y, w, h, true)

  end

  gfx.mode = 0

	-- Later calls to Color.set should handle this, but for
	-- some reason they aren't always.
  gfx.a = 1

end


function Textbox:drawgradient()

  local left, right = self.wnd_pos > 0, self.wnd_pos < (string.len(self.retval) - self.wnd_w + 2)
  if not (left or right) then return end

  local fade_w = 8

  Color.set("elm_bg")

  local left_x = self.x + 2 + fade_w
  local right_x = self.x + self.w - 3 - fade_w
  for i = 0, fade_w do

    gfx.a = i/fade_w

    -- Left
    if left then
      gfx.line(left_x - i, self.y + 2, left_x - i, self.y + self.h - 4)
    end

    -- Right
    if right then
      gfx.line(right_x + i, self.y + 2, right_x + i, self.y + self.h - 4)
    end

  end

end




------------------------------------
-------- Selection methods ---------
------------------------------------


-- Make sure at least part of the selection is visible
function Textbox:selectionvisible(x, w)

	return w > 0                  -- Selection has width,
    and x + w > self.wnd_pos    -- doesn't end to the left
    and x < self:wnd_right()    -- and doesn't start to the right

end


function Textbox:selectall()

  self.sel_s = 0
  self.caret = 0
  self.sel_e = string.len(self.retval)

end


function Textbox:selectword()

  local str = self.retval

  if not str or str == "" then return 0 end

  self.sel_s = string.find( str:sub(1, self.caret), "%s[%S]+$") or 0
  self.sel_e = (      string.find( str, "%s", self.sel_s + 1)
                  or  string.len(str) + 1)
              - (self.wnd_pos > 0 and 2 or 1) -- Kludge, fixes length issues

end


function Textbox:deleteselection()

  if not (self.sel_s and self.sel_e) then return 0 end

  self:storeundostate()

  local s, e = self.sel_s, self.sel_e

  if s > e then s, e = e, s end

  self.retval =   string.sub(self.retval or "", 1, s)..
                  string.sub(self.retval or "", e + 1)

  self.caret = s

  self.sel_s, self.sel_e = nil, nil
  self:windowtocaret()


end


function Textbox:getselectedtext()

  local s, e = self.sel_s, self.sel_e

  if s > e then s, e = e, s end

  return string.sub(self.retval, s + 1, e)

end


Textbox.toclipboard = TextUtils.toclipboard
Textbox.fromclipboard = TextUtils.fromclipboard



------------------------------------
-------- Window/pos helpers --------
------------------------------------


function Textbox:wnd_recalc()

  Font.set(self.font_b)

  self.char_w, self.char_h = gfx.measurestr("i")
  self.wnd_w = math.floor(self.w / self.char_w)

end


function Textbox:wnd_right()

  return self.wnd_pos + self.wnd_w

end


-- See if a given position is in the visible window
-- If so, adjust it from absolute to window-relative
-- If not, returns nil
function Textbox:adjusttowindow(x)

  return ( Math.clamp(self.wnd_pos, x, self:wnd_right() - 1) == x )
    and x - self.wnd_pos
    or nil

end


function Textbox:windowtocaret()

  if self.caret < self.wnd_pos + 1 then
    self.wnd_pos = math.max(0, self.caret - 1)
  elseif self.caret > (self:wnd_right() - 2) then
    self.wnd_pos = self.caret + 2 - self.wnd_w
  end

end


function Textbox:getcaret(x)

  local caret_x = math.floor(  ((x - self.x) / self.w) * self.wnd_w) + self.wnd_pos
  return Math.clamp(0, caret_x, string.len(self.retval or ""))

end




------------------------------------
-------- Char/string helpers -------
------------------------------------


function Textbox:insertstring(str, move_caret)

  self:storeundostate()

  local sanitized = self:sanitizetext(str)

  if self.sel_s then self:deleteselection() end

  local pre, post =   string.sub(self.retval or "", 1, self.caret),
                      string.sub(self.retval or "", self.caret + 1)

  self.retval = pre .. tostring(sanitized) .. post

  if move_caret then self.caret = self.caret + string.len(sanitized) end

end


function Textbox:insertchar(char)

  self:storeundostate()

  local a, b = string.sub(self.retval, 1, self.caret),
                string.sub(self.retval, self.caret + (self.insert_caret and 2 or 1))

  self.retval = a..string.char(char)..b
  self.caret = self.caret + 1

end


function Textbox:carettoend()

  return string.len(self.retval or "")

end


-- Replace any characters that we're unable to reproduce properly
function Textbox:sanitizetext(str)

  return tostring(str):gsub("\t", "    "):gsub("[\n\r]", " ")

end

Textbox.ctrlchar = TextUtils.ctrlchar


-- Non-typing key commands
-- A table of functions is more efficient to access than using really
-- long if/then/else structures.
Textbox.keys = {

  [Const.char.LEFT] = function(self)

    self.caret = math.max( 0, self.caret - 1)

  end,

  [Const.char.RIGHT] = function(self)

    self.caret = math.min( string.len(self.retval), self.caret + 1 )

  end,

  [Const.char.UP] = function(self)

    self.caret = 0

  end,

  [Const.char.DOWN] = function(self)

    self.caret = string.len(self.retval)

  end,

  [Const.char.BACKSPACE] = function(self)

    self:storeundostate()

    if self.sel_s then

      self:deleteselection()

    else

    if self.caret <= 0 then return end

      local str = self.retval
      self.retval =   string.sub(str, 1, self.caret - 1)..
                      string.sub(str, self.caret + 1, -1)
      self.caret = math.max(0, self.caret - 1)

    end

  end,

  [Const.char.INSERT] = function(self)

    self.insert_caret = not self.insert_caret

  end,

  [Const.char.DELETE] = function(self)

    self:storeundostate()

    if self.sel_s then

      self:deleteselection()

    else

      local str = self.retval
      self.retval =   string.sub(str, 1, self.caret) ..
                      string.sub(str, self.caret + 2)

    end

  end,

  [Const.char.RETURN] = function(self)

    self.focus = false
    self:lostfocus()
    self:redraw()

  end,

  [Const.char.HOME] = function(self)

    self.caret = 0

  end,

  [Const.char.END] = function(self)

    self.caret = string.len(self.retval)

  end,

  [Const.char.TAB] = function(self)

    -- tab functionality has been temporarily removed because it was broken anyway
    -- GUI.tab_to_next(self)

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
-------- Misc. helpers -------------
------------------------------------


Textbox.undo = TextUtils.undo
Textbox.redo = TextUtils.redo

Textbox.storeundostate = TextUtils.storeundostate

function Textbox:geteditorstate()

	return { retval = self.retval, caret = self.caret }

end

function Textbox:seteditorstate(retval, caret, wnd_pos, sel_s, sel_e)

  self.retval = retval or ""
  self.caret = math.min(caret and caret or self.caret, string.len(self.retval))
  self.wnd_pos = wnd_pos or 0
  self.sel_s, self.sel_e = sel_s or nil, sel_e or nil

end

Textbox.SWS_clipboard = TextUtils.SWS_clipboard

return Textbox
