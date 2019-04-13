-- NoIndex: true

--[[	Lokasenna_GUI - Label class.

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Label

    Creation parameters:
	name, z, x, y, caption[, shadow, font, color, bg]

]]--

local Buffer = require("gui.buffer")

local Font = require("public.font")
local Color = require("public.color")
local Text = require("public.text")

local Table = require("public.table")

local Label = require("gui.element"):new()
Label.__index = Label

function Label:new(props)

	local label = Table.copy({
    type = "Label",

    x = 0,
    y = 0,
    -- Placeholders; we'll get these at runtime
    w = 0,
    h = 0,

    caption = "Label",
    shadow =  false,
    font =    2,
    color =   "txt",
    bg =      "wnd_bg",
  }, props)

  return self:assignChild(label)
end


function Label:init()

    -- We can't do font measurements without an open window
    if gfx.w == 0 then return end

    self.buffs = self.buffs or Buffer.get(2)

    Font.set(self.font)
    self.w, self.h = gfx.measurestr(self.caption)

    local w, h = self.w + 4, self.h + 4

    -- Because we might be doing this in mid-draw-loop,
    -- make sure we put this back the way we found it
    local dest = gfx.dest


    -- Keeping the background separate from the text to avoid graphical
    -- issues when the text is faded.
    gfx.dest = self.buffs[1]
    gfx.setimgdim(self.buffs[1], -1, -1)
    gfx.setimgdim(self.buffs[1], w, h)

    Color.set(self.bg)
    gfx.rect(0, 0, w, h)

    -- Text + shadow
    gfx.dest = self.buffs[2]
    gfx.setimgdim(self.buffs[2], -1, -1)
    gfx.setimgdim(self.buffs[2], w, h)

    -- Text needs a background or the antialiasing will look like shit
    Color.set(self.bg)
    gfx.rect(0, 0, w, h)

    gfx.x, gfx.y = 2, 2

    Color.set(self.color)

	if self.shadow then
        Text.drawWithShadow(self.caption, self.color, "shadow")
    else
        gfx.drawstr(self.caption)
    end

    gfx.dest = dest

end


function Label:ondelete()

	Buffer.release(self.buffs)

end


function Label:fade(len, dest, curve)

  if curve < 0 then self:moveToLayer(dest) end

	self.fade_arr = {
    length = len,
    dest = dest,
    start = reaper.time_precise(),
    curve = (curve or 3)
  }
	self:redraw()

end


function Label:draw()

    -- Font stuff doesn't work until we definitely have a gfx window
	if self.w == 0 then self:init() end

    local a = self.fade_arr and self:getalpha() or 1
    if a == 0 then return end

    gfx.x, gfx.y = self.x - 2, self.y - 2

    -- Background
    gfx.blit(self.buffs[1], 1, 0)

    gfx.a = a

    -- Text
    gfx.blit(self.buffs[2], 1, 0)

    gfx.a = 1

end


function Label:val(newval)

	if newval then
		self.caption = newval
		self:init()
		self:redraw()
	else
		return self.caption
	end

end


function Label:getalpha()

    local sign = self.fade_arr.curve > 0 and 1 or -1

    local diff = (reaper.time_precise() - self.fade_arr.start) / self.fade_arr.length
    diff = math.floor(diff * 100) / 100
    diff = diff^(math.abs(self.fade_arr.curve))

    local a = sign > 0 and (1 - (gfx.a * diff)) or (gfx.a * diff)

    self:redraw()

    -- Terminate the fade loop at some point
    if sign == 1 and a < 0.02 then
        self:moveToLayer(self.fade_arr.dest)
        self.fade_arr = nil
        return 0
    elseif sign == -1 and a > 0.98 then
        -- self:moveToLayer(self.fade_arr.dest)
        self.fade_arr = nil
        return 1
    end

    return a

end

return Label
