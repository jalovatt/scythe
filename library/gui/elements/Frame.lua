-- NoIndex: true

local Buffer = require("public.buffer")

local Font = require("public.font")
local Color = require("public.color")
local GFX = require("public.gfx")
local Text = require("public.text")
-- local Table = require("public.table")
local Config = require("gui.config")

local Frame = require("gui.element"):new()
Frame.__index = Frame
Frame.defaultProps = {
  name = "frame",
  type = "Frame",
  x = 0,
  y = 0,
  w = 256,
  h = 256,
  color = "elmFrame",
  round = 0,
  text = "",
  lastText = "",
  textIndent = 0,
  textPad = 0,
  bg = "windowBg",
  font = 4,
  textColor = "txt",
  pad = 4,

}

function Frame:new(props)

	local frame = self:addDefaultProps(props)

  return setmetatable(frame, self)
end


function Frame:init()

    self.buffer = self.buffer or Buffer.get()

    gfx.dest = self.buffer
    gfx.setimgdim(self.buffer, -1, -1)
    gfx.setimgdim(self.buffer, 2 * self.w + 4, self.h + 2)

    self:drawFrame()

    self:drawText()

end


function Frame:onDelete()

	Buffer.release(self.buffer)

end


function Frame:draw()

  local x, y, w, h = self.x, self.y, self.w, self.h

  if self.shadow then

    for i = 1, Config.shadowSize do

      gfx.blit(self.buffer, 1, 0, w + 2, 0, w + 2, h + 2, x + i - 1, y + i - 1)

    end

  end

  gfx.blit(self.buffer, 1, 0, 0, 0, w + 2, h + 2, x - 1, y - 1)

end


function Frame:val(new)

	if new then
		self.text = new
    if self.buffer then self:init() end
		self:redraw()
	else
		return self.text:gsub("\n", "")
	end

end




------------------------------------
-------- Drawing methods -----------
------------------------------------


function Frame:drawFrame()

  local w, h = self.w, self.h
	local fill = self.fill
	local round = self.round

  -- Frame background
  if self.bg then
    Color.set(self.bg)
    if round > 0 then
      GFX.roundRect(1, 1, w, h, round, 1, true)
    else
      gfx.rect(1, 1, w, h, true)
    end
  end

  -- Shadow
  local r, g, b, a = table.unpack(Color.colors["shadow"])
	gfx.set(r, g, b, 1)
	GFX.roundRect(w + 2, 1, w, h, round, 1, 1)
	gfx.muladdrect(w + 2, 1, w + 2, h + 2, 1, 1, 1, a, 0, 0, 0, 0 )


    -- Frame
	Color.set(self.color)
	if round > 0 then
		GFX.roundRect(1, 1, w, h, round, 1, fill)
	else
		gfx.rect(1, 1, w, h, fill)
	end

end


function Frame:drawText()

	if self.text and self.text:len() > 0 then

    -- Rewrap the text if it changed
    if self.text ~= self.lastText then
      self.text = self:wrapText(self.text)
      self.lastText = self.text
    end

		Font.set(self.font)
		Color.set(self.textColor)

		gfx.x, gfx.y = self.pad + 1, self.pad + 1
		if not self.fill then Text.drawBackground(self.text, self.bg) end
		gfx.drawstr(self.text)

	end

end




------------------------------------
-------- Helpers -------------------
------------------------------------


function Frame:wrapText(text)

  return Text.wrapText(text, self.font, self.w - 2*self.pad,
                        self.textIndent, self.textPad)

end

return Frame
