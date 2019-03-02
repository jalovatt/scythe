-- NoIndex: true

--[[	Lokasenna_GUI - Tabs class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Tabs

    Creation parameters:
    name, z, x, y, tab_w, tab_h, opts[, pad]

]]--

local Tabs = require("gui.element"):new()
function Tabs:new(props)

	local tab = props

	tab.type = "Tabs"

	tab.x = tab.x or 0
  tab.y = tab.y or 0
	tab.tab_w = tab.tab_w or 48
  tab.tab_h = tab.tab_h or 20

	tab.font_a = tab.font_a or 3
  tab.font_b = tab.font_b or 4

	tab.bg = tab.bg or "elm_bg"
	tab.col_txt = tab.col_txt or "txt"
	tab.col_tab_a = tab.col_tab_a or "wnd_bg"
	tab.col_tab_b = tab.col_tab_b or "tab_bg"

  -- Placeholder for if I ever figure out downward tabs
	tab.dir = tab.dir or "u"

	tab.pad = tab.pad or 8

  --[[
    Data shape:

    tab.tabs = {
      {label = "First", layers = { layer1, layer2, layer3 },
      {label = "Second", layers = { layer4, layer5, layer6 },
    }
  ]]--
	-- Parse the string of options into a table
  --   if not tab.optarray then
  --       local opts = tab.opts or opts

  --       tab.optarray = {}
  --       if type(opts) == "string" then
  --           for word in string.gmatch(opts, '([^,]+)') do
  --               tab.optarray[#tab.optarray + 1] = word
  --           end
  --       elseif type(opts) == "table" then
  --           tab.optarray = opts
  --       end
  --   end

	-- tab.z_sets = {}
	-- for i = 1, #tab.optarray do
	-- 	tab.z_sets[i] = {}
  -- end



	-- Figure out the total size of the tab frame now that we know the
    -- number of buttons, so we can do the math for clicking on it
	tab.w, tab.h = (tab.tab_w + tab.pad) * #tab.tabs + 2*tab.pad + 12, tab.tab_h

  if tab.fullwidth == nil then
    tab.fullwidth = true
  end

	-- Currently-selected option
	tab.retval = tab.retval or 1
  tab.state = tab.retval or 1

	setmetatable(tab, self)
	self.__index = self
	return tab

end


function Tabs:init()

    self:update_sets()

end


function Tabs:draw()

	local x, y = self.x + 16, self.y
  local tab_w, tab_h = self.tab_w, self.tab_h
	local pad = self.pad
	local font = self.font_b
	local dir = self.dir
	local state = self.state

    -- Make sure w is at least the size of the tabs.
    -- (GUI builder will let you try to set it lower)
    self.w = self.fullwidth and (GUI.cur_w - self.x) or math.max(self.w, (tab_w + pad) * #self.tabs + 2*pad + 12)

	GUI.color(self.bg)
	gfx.rect(x - 16, y, self.w, self.h, true)

	local x_adj = tab_w + pad

	-- Draw the inactive tabs first
	for i = #self.tabs, 1, -1 do

		if i ~= state then
			--
			local tab_x, tab_y = x + GUI.shadow_dist + (i - 1) * x_adj,
								 y + GUI.shadow_dist * (dir == "u" and 1 or -1)

			self:draw_tab(tab_x, tab_y, tab_w, tab_h, dir, font, self.col_txt, self.col_tab_b, self.tabs[i].label)

		end

	end

	self:draw_tab(x + (state - 1) * x_adj, y, tab_w, tab_h, dir, self.font_a, self.col_txt, self.col_tab_a, self.tabs[state].label)

    -- Keep the active tab's top separate from the window background
	GUI.color(self.bg)
    gfx.line(x + (state - 1) * x_adj, y, x + state * x_adj, y, 1)

	-- Cover up some ugliness at the bottom of the tabs
	GUI.color("wnd_bg")
	gfx.rect(self.x, self.y + (dir == "u" and tab_h or -6), self.w, 6, true)


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


function Tabs:onmousedown()

    -- Offset for the first tab
	local adj = 0.75*self.h

	local mouseopt = (GUI.mouse.x - (self.x + adj)) / (#self.tabs * (self.tab_w + self.pad))

	mouseopt = GUI.clamp((math.floor(mouseopt * #self.tabs) + 1), 1, #self.tabs)

	self.state = mouseopt

	self:redraw()

end


function Tabs:onmouseup()

	-- Set the new option, or revert to the original if the cursor isn't inside the list anymore
	if self:isInside(GUI.mouse.x, GUI.mouse.y) then

		self.retval = self.state
		self:update_sets()

	else
		self.state = self.retval
	end

	self:redraw()

end


function Tabs:ondrag()

	self:onmousedown()
	self:redraw()

end


function Tabs:onwheel()

	self.state = GUI.round(self.state + GUI.mouse.inc)

	if self.state < 1 then self.state = 1 end
	if self.state > #self.tabs then self.state = #self.tabs end

	self.retval = self.state
	self:update_sets()
	self:redraw()

end




------------------------------------
-------- Drawing helpers -----------
------------------------------------


function Tabs:draw_tab(x, y, w, h, dir, font, col_txt, col_bg, lbl)

	local dist = GUI.shadow_dist
    local y1, y2 = table.unpack(dir == "u" and  {y, y + h}
                                           or   {y + h, y})

	GUI.color("shadow")

    -- tab shadow
    for i = 1, dist do

        gfx.rect(x + i, y, w, h, true)

        gfx.triangle(   x + i, y1,
                        x + i, y2,
                        x + i - (h / 2), y2)

        gfx.triangle(   x + i + w, y1,
                        x + i + w, y2,
                        x + i + w + (h / 2), y2)

    end

    -- Hide those gross, pixellated edges
    gfx.line(x + dist, y1, x + dist - (h / 2), y2, 1)
    gfx.line(x + dist + w, y1, x + dist + w + (h / 2), y2, 1)

    GUI.color(col_bg)

    gfx.rect(x, y, w, h, true)

    gfx.triangle(   x, y1,
                    x, y2,
                    x - (h / 2), y2)

    gfx.triangle(   x + w, y1,
                    x + w, y2,
                    x + w + (h / 2), y + h)

    gfx.line(x, y1, x - (h / 2), y2, 1)
    gfx.line(x + w, y1, x + w + (h / 2), y2, 1)


	-- Draw the tab's label
	GUI.color(col_txt)
	GUI.font(font)

	local str_w, str_h = gfx.measurestr(lbl)
	gfx.x = x + ((w - str_w) / 2)
	gfx.y = y + ((h - str_h) / 2)
	gfx.drawstr(lbl)

end




------------------------------------
-------- tab helpers ---------------
------------------------------------


-- Updates visibility for any layers assigned to the tabs
function Tabs:update_sets(init)

	local state = self.state

	if init then
		self.tabs = init
	end

	local tabs = self.tabs

	if not tabs or #tabs[1].layers < 1 then return end

	for i = 1, #tabs do
    if i ~= state then
        for _, layer in pairs(tabs[i].layers) do
            layer:hide()
        end
    end
	end

  for _, layer in pairs(tabs[state].layers) do
    layer:show()
  end

end

return Tabs
