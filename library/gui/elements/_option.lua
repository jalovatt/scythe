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

local Buffer = require("gui.buffer")
local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local Text = require("public.text")
local Table = require("public.table")

local Option = require("gui.element"):new()
Option.__index = Option

function Option:new(props)

	local option = Table.copy({
    x = 0,
    y = 0,
    w = 128,
    h = 128,

    caption = ((props.type or "Option") .. ":"),

    bg = "wnd_bg",

    dir = "v",
    pad = 4,

    col_txt = "txt",
    col_fill = "elm_fill",

    font_a = 2,
    font_b = 3,

    -- Size of the option bubbles
    opt_size = 20,

    options = {"Option 1", "Option 2", "Option 3"},

  }, props)

  if option.frame == nil then option.frame = true end
  if option.shadow == nil then option.shadow = true end

	-- setmetatable(option, self)
  -- self.__index = self
  return self:assignChild(option)

end


function Option:init()

    -- Make sure we're not trying to use the base class.
    -- It shouldn't be possible, but just in case...
    if self.type == "Option" then
        error("Invalid GUI class - '" .. self.name .. "' was initialized as an Option element")
        return
    end

	self.buff = self.buff or Buffer.get()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*self.opt_size + 4, 2*self.opt_size + 2)


    self:initoptions()


	if self.caption and self.caption ~= "" then
		Font.set(self.font_a)
		local str_w, str_h = gfx.measurestr(self.caption)
		self.cap_h = 0.5*str_h
		self.cap_x = self.x + (self.w - str_w) / 2
	else
		self.cap_h = 0
		self.cap_x = 0
	end

end


function Option:ondelete()

	Buffer.release(self.buff)

end


function Option:draw()

	if self.frame then
		Color.set("elm_frame")
		gfx.rect(self.x, self.y, self.w, self.h, 0)
	end

  if self.caption and self.caption ~= "" then self:drawcaption() end

  self:drawoptions()

end




------------------------------------
-------- Input helpers -------------
------------------------------------




function Option:getmouseopt(state)

  local len = #self.options

	-- See which option it's on
	local mouseopt = self.dir == "h"
                and (state.mouse.x - (self.x + self.pad))
					      or	(state.mouse.y - (self.y + self.cap_h + 1.5*self.pad) )

	mouseopt = mouseopt / ((self.opt_size + self.pad) * len)
	mouseopt = Math.clamp( math.floor(mouseopt * len) + 1 , 1, len )

  return self.options[mouseopt] ~= "_" and mouseopt or false

end


------------------------------------
-------- Drawing methods -----------
------------------------------------


function Option:drawcaption()

    Font.set(self.font_a)

    gfx.x = self.cap_x
    gfx.y = self.y - self.cap_h

    Text.text_bg(self.caption, self.bg)

    Text.drawWithShadow(self.caption, self.col_txt, "shadow")

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

  Font.set(self.font_b)

  local output = self:formatOutput(str)

  local str_w, str_h = gfx.measurestr(output)

  if self.dir == "h" then

    gfx.x = opt_x + (size - str_w) / 2
    gfx.y = opt_y + (self.swap and (size + 4) or -size)

  else

    gfx.x = opt_x + (self.swap and -(str_w + 8) or 1.5*size)
    gfx.y = opt_y + (size - str_h) / 2

  end

  Text.text_bg(output, self.bg)
  if #self.options == 1 or self.shadow then
    Text.drawWithShadow(output, self.col_txt, "shadow")
  else
    Color.set(self.col_txt)
    gfx.drawstr(output)
  end

end

return Option
