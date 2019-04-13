-- NoIndex: true

--[[	Lokasenna_GUI - Frame class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Frame

    Creation parameters:
	name, z, x, y, w, h[, shadow, fill, color, round]

]]--

local Buffer = require("gui.buffer")

local Font = require("public.font")
local Color = require("public.color")
local GFX = require("public.gfx")
local Text = require("public.text")
local Table = require("public.table")

local Frame = require("gui.element"):new()

function Frame:new(props)

	local frame = Table.copy({

	  type = "Frame",
    x = 0,
    y = 0,
    w = 256,
    h = 256,
    color = "elm_frame",
	  round = 0,
    text = "",
    last_text = "",
	  txt_indent = 0,
	  txt_pad = 0,
    bg = "wnd_bg",
    font = 4,
	  col_txt = "txt",
	  pad = 4,

  }, props)

	setmetatable(frame, self)
	self.__index = self
	return frame

end


function Frame:init()

    self.buff = self.buff or Buffer.get()

    gfx.dest = self.buff
    gfx.setimgdim(self.buff, -1, -1)
    gfx.setimgdim(self.buff, 2 * self.w + 4, self.h + 2)

    self:drawframe()

    self:drawtext()

end


function Frame:ondelete()

	Buffer.release(self.buff)

end


function Frame:draw()

    local x, y, w, h = self.x, self.y, self.w, self.h

    if self.shadow then

        for i = 1, Text.shadow_size do

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
		if not self.fill then Text.text_bg(self.text, self.bg) end
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
