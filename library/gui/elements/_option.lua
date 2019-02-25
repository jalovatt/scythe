-- NoIndex: true

--[[	Lokasenna_GUI - Options classes

    This file provides two separate element classes:

    Radio       A list of options from which the user can only choose one at a time.
    Checklist   A list of options from which the user can choose any, all or none.

    Both classes take the same parameters on creation, and offer the same parameters
    afterward - their usage only differs when it comes to their respective :val methods.

    For documentation, see the class pages on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Checklist
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Radio

    Creation parameters:
	name, z, x, y, w, h, caption, opts[, dir, pad]

]]--

local Option = require("gui.element"):new()

function Option:new(props)

	local option = props

	option.z = option.z or z

	option.x = option.x or 0
  option.y = option.y or 0
  option.w = option.w or 128
  option.h = option.h or 128

	option.caption = option.caption or (props.type .. ":")

  if option.frame == nil then option.frame = true end
	option.bg = option.bg or "wnd_bg"

	option.dir = option.dir or dir or "v"
	option.pad = option.pad or pad or 4

	option.col_txt = option.col_txt or "txt"
	option.col_fill = option.col_fill or "elm_fill"

	option.font_a = option.font_a or 2
	option.font_b = option.font_b or 3

  if option.shadow == nil then option.shadow = true end

	-- Size of the option bubbles
	option.opt_size = option.opt_size or 20

  option.options = option.options or {"Option 1", "Option 2", "Option 3"}

	setmetatable(option, self)
    self.__index = self
    return option

end


function Option:init()

    -- Make sure we're not trying to use the base class.
    if self.type == "Option" then
        reaper.ShowMessageBox(  "'"..self.name.."' was initialized as an Option element,"..
                                "but Option doesn't do anything on its own!",
                                "GUI Error", 0)

        GUI.quit = true
        return

    end

	self.buff = self.buff or GUI.GetBuffer()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*self.opt_size + 4, 2*self.opt_size + 2)


    self:initoptions()


	if self.caption and self.caption ~= "" then
		GUI.font(self.font_a)
		local str_w, str_h = gfx.measurestr(self.caption)
		self.cap_h = 0.5*str_h
		self.cap_x = self.x + (self.w - str_w) / 2
	else
		self.cap_h = 0
		self.cap_x = 0
	end

end


function Option:ondelete()

	GUI.FreeBuffer(self.buff)

end


function Option:draw()

	if self.frame then
		GUI.color("elm_frame")
		gfx.rect(self.x, self.y, self.w, self.h, 0)
	end

    if self.caption and self.caption ~= "" then self:drawcaption() end

    self:drawoptions()

end




------------------------------------
-------- Input helpers -------------
------------------------------------




function Option:getmouseopt()

    local len = #self.options

	-- See which option it's on
	local mouseopt = self.dir == "h"
                    and (GUI.mouse.x - (self.x + self.pad))
					or	(GUI.mouse.y - (self.y + self.cap_h + 1.5*self.pad) )

	mouseopt = mouseopt / ((self.opt_size + self.pad) * len)
	mouseopt = GUI.clamp( math.floor(mouseopt * len) + 1 , 1, len )

    return self.options[mouseopt] ~= "_" and mouseopt or false

end


------------------------------------
-------- Drawing methods -----------
------------------------------------


function Option:drawcaption()

    GUI.font(self.font_a)

    gfx.x = self.cap_x
    gfx.y = self.y - self.cap_h

    GUI.text_bg(self.caption, self.bg)

    GUI.shadow(self.caption, self.col_txt, "shadow")

end


function Option:drawoptions()

    local x, y, w, h = self.x, self.y, self.w, self.h

    local horz = self.dir == "h"
	local pad = self.pad

    -- Bump everything down for the caption
    y = y + ((self.caption and self.caption ~= "") and self.cap_h or 0) + 1.5 * pad

    -- Bump the options down more for horizontal options
    -- with the text on top
	if horz and self.caption ~= "" and not self.swap then
        y = y + self.cap_h + 2*pad
    end

	local opt_size = self.opt_size

    local adj = opt_size + pad

    local str, opt_x, opt_y

	for i = 1, #self.options do

		str = self.options[i]
		if str ~= "_" then

            opt_x = x + (horz   and (i - 1) * adj + pad
                                or  (self.swap  and (w - adj - 1)
                                                or   pad))

            opt_y = y + (i - 1) * (horz and 0 or adj)

			-- Draw the option bubble
            self:drawoption(opt_x, opt_y, opt_size, self:isoptselected(i))

            self:drawvalue(opt_x,opt_y, opt_size, str)

		end

	end

end


function Option:drawoption(opt_x, opt_y, size, selected)

    gfx.blit(   self.buff, 1,  0,
                selected and (size + 3) or 1, 1,
                size + 1, size + 1,
                opt_x, opt_y)

end


function Option:drawvalue(opt_x, opt_y, size, str)

    if not str or str == "" then return end

	GUI.font(self.font_b)

    local str_w, str_h = gfx.measurestr(str)

    if self.dir == "h" then

        gfx.x = opt_x + (size - str_w) / 2
        gfx.y = opt_y + (self.swap and (size + 4) or -size)

    else

        gfx.x = opt_x + (self.swap and -(str_w + 8) or 1.5*size)
        gfx.y = opt_y + (size - str_h) / 2

    end

    GUI.text_bg(str, self.bg)
    if #self.options == 1 or self.shadow then
        GUI.shadow(str, self.col_txt, "shadow")
    else
        GUI.color(self.col_txt)
        gfx.drawstr(str)
    end

end

return Option
