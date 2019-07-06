-- NoIndex: true

local Buffer = require("public.buffer")

local Font = require("public.font")
local Color = require("public.color")
local GFX = require("public.gfx")
local Text = require("public.text")
local Config = require("gui.config")

local ColorPicker = require("gui.element"):new()
ColorPicker.__index = ColorPicker
ColorPicker.defaultProps = {
  name = "colorPicker",
  type = "ColorPicker",
  x = 0,
  y = 0,
  w = 256,
  h = 256,
  frameColor = "elmFrame",
  color = "elmFill",
  round = 0,
  caption = "",
  bg = "windowBg",
  captionFont = 3,
  captionColor = "txt",
  pad = 4,
  shadow = true,
}

function ColorPicker:new(props)
	local picker = self:addDefaultProps(props)

  return setmetatable(picker, self)
end

function ColorPicker:init()
  self.buffer = self.buffer or Buffer.get()

  gfx.dest = self.buffer
  gfx.setimgdim(self.buffer, -1, -1)
  gfx.setimgdim(self.buffer, 2 * self.w + 4, self.h + 2)

  self:drawFrame()
end

function ColorPicker:onDelete()
	Buffer.release(self.buffer)
end

function ColorPicker:val(new)
	if new then
		self.color = new
		self:redraw()
	else
		return self.color
	end
end

function ColorPicker:draw()
  local x, y, w, h = self.x, self.y, self.w, self.h

  if self.shadow then
    for i = 1, Config.shadowSize do
      gfx.blit(self.buffer, 1, 0, w + 2, 0, w + 2, h + 2, x + i - 1, y + i - 1)
    end
  end

  gfx.blit(self.buffer, 1, 0, 0, 0, w + 2, h + 2, x - 1, y - 1)

  self:drawCaption()
  self:drawColor()
end

function ColorPicker:onMouseUp()
  self:selectColor()
	self:redraw()
end

function ColorPicker:selectColor()
  local retval, colorOut = reaper.GR_SelectColor()

  if retval ~= 0 then
    local r, g, b = reaper.ColorFromNative(colorOut)
    self.color = {r / 255, g / 255, b / 255}
    self:redraw()
  end
end



------------------------------------
-------- Drawing methods -----------
------------------------------------


function ColorPicker:drawFrame()

  local w, h = self.w, self.h
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
	Color.set(self.frameColor)
	if round > 0 then
		GFX.roundRect(1, 1, w, h, round, 1, false)
	else
		gfx.rect(1, 1, w, h, false)
	end

end

function ColorPicker:drawCaption()

  if not self.caption or self.caption == "" then return end

  Font.set(self.captionFont)
  local strWidth, strHeight = gfx.measurestr(self.caption)

  gfx.x = self.x - strWidth - self.pad
  gfx.y = self.y + (self.h - strHeight) / 2

  Text.drawBackground(self.caption, self.bg)
  Text.drawWithShadow(self.caption, self.captionColor, "shadow")

end

-- Draw the chosen color inside the frame
function ColorPicker:drawColor()

  local x, y, w, h = self.x + 1, self.y + 1, self.w - 2, self.h - 2

  Color.set(self.color)
  gfx.rect(x, y, w, h, true)

  if self.color then
    Color.set(self.color)
    gfx.rect(x + 1, y + 1, w - 2, h - 2, true)
  end

  Color.set("black")
  gfx.rect(x, y, w, h, false)

end

return ColorPicker
