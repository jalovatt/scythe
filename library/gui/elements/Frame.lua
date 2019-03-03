-- NoIndex: true

--[[	Lokasenna_GUI - Frame class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Frame

    Creation parameters:
	name, z, x, y, w, h[, shadow, fill, color, round]

]]--

local Font = require("public.font")
local Color = require("public.color")
local GFX = require("public.gfx")
local Text = require("public.text")

local Frame = require("gui.element"):new()

function Frame:new(props)

	local frame = props

	frame.type = "Frame"

	frame.x = frame.x or 0
  frame.y = frame.y or 0
  frame.w = frame.w or 256
  frame.h = frame.h or 256

	frame.color = frame.color or "elm_frame"
	frame.round = frame.round or 0

	frame.text, frame.last_text = frame.text or "", ""
	frame.txt_indent = frame.txt_indent or 0
	frame.txt_pad = frame.txt_pad or 0

	frame.bg = frame.bg or "wnd_bg"

	frame.font = frame.font or 4
	frame.col_txt = frame.col_txt or "txt"
	frame.pad = frame.pad or 4

	setmetatable(frame, self)
	self.__index = self
	return frame

end


function Frame:init()

    self.buff = self.buff or GUI.GetBuffer()

    gfx.dest = self.buff
    gfx.setimgdim(self.buff, -1, -1)
    gfx.setimgdim(self.buff, 2 * self.w + 4, self.h + 2)

    self:drawframe()

    self:drawtext()

end


function Frame:ondelete()

	GUI.FreeBuffer(self.buff)

end


function Frame:draw()

    local x, y, w, h = self.x, self.y, self.w, self.h

    if self.shadow then

        for i = 1, Text.drawWithShadow_dist do

            gfx.blit(self.buff, 1, 0, w + 2, 0, w + 2, h + 2, x + i - 1, y + i - 1)

        end

    end

    gfx.blit(self.buff, 1, 0, 0, 0, w + 2, h + 2, x - 1, y - 1)

end


function Frame:val(new)

	if new then
		self.text = new
    if self.buff then self:init() end
		self:redraw()
	else
		return string.gsub(self.text, "\n", "")
	end

end




------------------------------------
-------- Drawing methods -----------
------------------------------------


function Frame:drawframe()

    local w, h = self.w, self.h
	local fill = self.fill
	local round = self.round

    -- Frame background
    if self.bg then
        Color.set(self.bg)
        if round > 0 then
            GFX.roundrect(1, 1, w, h, round, 1, true)
        else
            gfx.rect(1, 1, w, h, true)
        end
    end

    -- Shadow
    local r, g, b, a = table.unpack(Color.colors["shadow"])
	gfx.set(r, g, b, 1)
	GFX.roundrect(self.w + 2, 1, self.w, self.h, round, 1, 1)
	gfx.muladdrect(self.w + 2, 1, self.w + 2, self.h + 2, 1, 1, 1, a, 0, 0, 0, 0 )


    -- Frame
	Color.set(self.color)
	if round > 0 then
		GFX.roundrect(1, 1, w, h, round, 1, fill)
	else
		gfx.rect(1, 1, w, h, fill)
	end

end


function Frame:drawtext()

	if self.text and self.text:len() > 0 then

        if self.text ~= self.last_text then
            self.text = self:wrap_text(self.text)
            self.last_text = self.text
        end

		Font.set(self.font)
		Color.set(self.col_txt)

		gfx.x, gfx.y = self.pad + 1, self.pad + 1
		if not fill then Text.text_bg(self.text, self.bg) end
		gfx.drawstr(self.text)

	end

end




------------------------------------
-------- Helpers -------------------
------------------------------------


function Frame:wrap_text(text)

    return Text.word_wrap(   text, self.font, self.w - 2*self.pad,
                            self.txt_indent, self.txt_pad)

end

return Frame
