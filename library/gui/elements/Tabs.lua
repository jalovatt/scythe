-- NoIndex: true

--[[	Lokasenna_GUI - Tabs class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Tabs

    Creation parameters:
    name, z, x, y, tab_w, tab_h, opts[, pad]

]]--

local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local Buffer = require("gui.buffer")
-- local Table = require("public.table")
local Config = require("gui.config")

local Tabs = require("gui.element"):new()
Tabs.__index = Tabs
Tabs.defaultProps = {

  type = "Tabs",

  x = 0,
  y = 0,
  tab_w = 72,
  tab_h = 20,

  font_a = 3,
  font_b = 4,

  bg = "elm_bg",
  col_txt = "txt",
  col_tab_a = "wnd_bg",
  col_tab_b = "tab_bg",

  -- Placeholder for if I ever figure out downward tabs
  dir = "u",

  pad = 8,

  first_tab_offset = 16,

  -- Currently-selected option
  retval = 1,
  state = 1,

  fullwidth = true,
}

function Tabs:new(props)

	local tab = self:addDefaultProps(props)

	-- Figure out the total size of the tab frame now that we know the
  -- number of buttons, so we can do the math for clicking on it
  tab.w = (tab.tab_w + tab.pad) * #tab.tabs + 2*tab.pad + 12
  tab.h = tab.tab_h

	return self:assignChild(tab)
end


function Tabs:init()

  self.buffer = self.buffer or Buffer.get()
  self:update_sets()

  self.buffer_size = (#self.tabs * (self.tab_w + 4))

  gfx.dest = self.buffer
  gfx.setimgdim(self.buffer, -1, -1)
  gfx.setimgdim(self.buffer, self.buffer_size, self.buffer_size)

  Color.set(self.bg)
  gfx.rect(0, 0, self.buffer_size, self.buffer_size, true)

  local x_adj = self.tab_w + self.pad - self.tab_h

  -- Because of anti-aliasing, we can't just draw and blit the tabs individually
  -- We'll draw the entire row separately for each state
  for state = 1, #self.tabs do
    for tab = #self.tabs, 1, -1 do
      if tab ~= state then
        -- Inactive
        self:draw_tab(
          (tab - 1) * (x_adj),
          (state - 1) * (self.tab_h + 4) + Config.shadow_size,
          self.tab_w,
          self.tab_h,
          self.dir, self.font_b, self.col_txt, self.col_tab_b, self.tabs[tab].label)
      end
    end

    -- Active
    self:draw_tab(
      (state - 1) * (x_adj),
      (state - 1) * (self.tab_h + 4),
      self.tab_w,
      self.tab_h,
      self.dir, self.font_b, self.col_txt, self.col_tab_a, self.tabs[state].label)
  end

end

function Tabs:ondelete()

	Buffer.release(self.buffs)

end


function Tabs:draw()

	local x, y = self.x + self.first_tab_offset, self.y
  local tab_w, tab_h = self.tab_w, self.tab_h
	local state = self.state

  -- Make sure w is at least the size of the tabs.
  -- (GUI builder will let you try to set it lower)
  self.w = self.fullwidth and (self.layer.window.cur_w - self.x) or math.max(self.w, (tab_w + self.pad) * #self.tabs + 2*self.pad + 12)

	Color.set(self.bg)
	gfx.rect(x - 16, y, self.w, self.h, true)

  local x_adj = tab_w + self.pad - tab_h
  gfx.blit(self.buffer, 1, 0, 0, (state - 1) * (tab_h + 4), self.buffer_size, (tab_h + 4), x, y)

    -- Keep the active tab's top separate from the window background
	Color.set(self.bg)
    gfx.line(x + (state - 1) * x_adj, y, x + state * x_adj, y, 1)

	-- Cover up some ugliness at the bottom of the tabs
	Color.set("wnd_bg")
	gfx.rect(self.x, self.y + (self.dir == "u" and tab_h or -6), self.w, 6, true)


end


function Tabs:val(newval)

	if newval then
		self.state = newval
		self.retval = self.state

		self:update_sets()
		self:redraw()
	else
		return self.state
	end

end


function Tabs:onresize()
  if self.fullwidth then self:redraw() end
end


------------------------------------
-------- Input methods -------------
------------------------------------


function Tabs:onmousedown(state)

  local x_offset = (state.mouse.x - (self.x + self.first_tab_offset))
  local width = (#self.tabs * (self.tab_w + self.pad - self.tab_h))

  local mouse_percent = x_offset / width

	local mouseopt = Math.clamp((math.floor(mouse_percent * #self.tabs) + 1), 1, #self.tabs)

	self.state = mouseopt

	self:redraw()

end


function Tabs:onmouseup(state)
	-- Set the new option, or revert to the original if the cursor isn't inside the list anymore
	if self:isInside(state.mouse.x, state.mouse.y) then

		self.retval = self.state
		self:update_sets()

	else
		self.state = self.retval
	end

	self:redraw()

end


function Tabs:ondrag(state, last)

	self:onmousedown(state, last)
	self:redraw()

end


function Tabs:onwheel(state)

	self.state = Math.round(self.state + state.mouse.inc)

	if self.state < 1 then self.state = 1 end
	if self.state > #self.tabs then self.state = #self.tabs end

	self.retval = self.state
	self:update_sets()
	self:redraw()

end




------------------------------------
-------- Drawing helpers -----------
------------------------------------

function Tabs:draw_tab_left(x, i, y1, y2, h)
  gfx.triangle(x + i, y1, x + i, y2, x + i - (h / 2), y2)
end

function Tabs:draw_tab_right(r, i, y1, y2, h)
  gfx.triangle(r + i, y1, r + i, y2, r + i + (h / 2), y2)
end

function Tabs:draw_aliasing_fix(x, r, i, y1, y2, h)
  gfx.line(x + i, y1, x + i - (h / 2), y2, 1)
  gfx.line(r + i, y1, r + i + (h / 2), y2, 1)
end

function Tabs:draw_tab(x, y, w, h, dir, font, col_txt, col_bg, lbl)

	local dist = Config.shadow_size
  local y1, y2 = table.unpack(dir == "u" and  {y, y + h}
                                         or   {y + h, y})

  local adjusted_x = x + (h / 2)
  local adjusted_w = w - h
  local adjusted_right = adjusted_x + adjusted_w

	Color.set("shadow")

  -- tab shadow
  for i = 1, dist do

    gfx.rect(adjusted_x + i, y, adjusted_w, h, true)

    self:draw_tab_left(adjusted_x, i, y1, y2, h)
    self:draw_tab_right(adjusted_right, i, y1, y2, h)

  end

  self:draw_aliasing_fix(adjusted_x, adjusted_right, dist, y1, y2, h)

  Color.set(col_bg)

  gfx.rect(adjusted_x, y, adjusted_w, h, true)

  self:draw_tab_left(adjusted_x, 0, y1, y2, h)
  self:draw_tab_right(adjusted_right, 0, y1, y2, h)
  self:draw_aliasing_fix(adjusted_x, adjusted_right, 0, y1, y2, h)

	-- Draw the tab's label
	Color.set(col_txt)
	Font.set(font)

	local str_w, str_h = gfx.measurestr(lbl)
	gfx.x = adjusted_x + ((adjusted_w - str_w) / 2)
	gfx.y = y + ((h - str_h) / 2)
	gfx.drawstr(lbl)

end




------------------------------------
-------- tab helpers ---------------
------------------------------------


-- Updates visibility for any layers assigned to the tabs
function Tabs:update_sets()

	if not self.tabs or #self.tabs[1].layers < 1 then return end

	for i = 1, #self.tabs do
    if i ~= self.state then
      for _, layer in pairs(self.tabs[i].layers) do
        layer:hide()
      end
    end
	end

  for _, layer in pairs(self.tabs[self.state].layers) do
    layer:show()
  end

end

return Tabs
