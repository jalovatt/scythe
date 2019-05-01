-- NoIndex: true

--[[	Lokasenna_GUI - Knob class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Knob

    Creation parameters:
	name, z, x, y, w, caption, min, max, default,[ inc, vals]

]]--

local Buffer = require("gui.buffer")

local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local GFX = require("public.gfx")
local Text = require("public.text")
local Table = require("public.table")
local Config = require("gui.config")

local Knob = require("gui.element"):new()
Knob.__index = Knob
Knob.defaultProps = {
  name = "knob",
  type = "Knob",
  x = 0,
  y = 0,
  w = 64,
  caption = "Knob",
  bg = "windowBg",
  captionX = 0,
  captionY = 0,
  captionFont = 3,
  textFont = 4,
  textColor = "txt",
  headColor = "elmFill",
  bodyColor = "elmFrame",

  min = 0,
  max = 10,
  inc = 1,

  default = 5,

  vals = true,
}

function Knob:new(props)

	local knob = self:addDefaultProps(props)

  knob.h = knob.w
  knob.steps = knob.steps or (math.abs(knob.max - knob.min) / knob.inc)

  -- Determine the step angle
  knob.stepAngle = (3 / 2) / knob.steps

  knob.currentStep = knob.default
	knob.currentVal = knob.currentStep / knob.steps

  self:assignChild(knob)

  knob.retval = knob:formatRetval(
    ((knob.max - knob.min) / knob.steps) * knob.currentStep + knob.min
  )

  return knob
end


function Knob:init()

	self.buffer = self.buffer or Buffer.get()

	gfx.dest = self.buffer
	gfx.setimgdim(self.buffer, -1, -1)

	-- Figure out the points of the triangle

	local r = self.w / 2
	local tipRadius = r * 1.5
	local currentAngle = 0
	local o = tipRadius + 1

	local w = 2 * tipRadius + 2

	gfx.setimgdim(self.buffer, 2*w, w)

	local sideAngle = (math.acos(0.666667) / Math.pi) * 0.9

	local Ax, Ay = Math.polarToCart(currentAngle, tipRadius, o, o)
  local Bx, By = Math.polarToCart(currentAngle + sideAngle, r - 1, o, o)
	local Cx, Cy = Math.polarToCart(currentAngle - sideAngle, r - 1, o, o)

	-- Head
	Color.set(self.headColor)
	GFX.triangle(true, Ax, Ay, Bx, By, Cx, Cy)
	Color.set("elmOutline")
	GFX.triangle(false, Ax, Ay, Bx, By, Cx, Cy)

	-- Body
	Color.set(self.bodyColor)
	gfx.circle(o, o, r, 1)
	Color.set("elmOutline")
	gfx.circle(o, o, r, 0)

	--gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs] )
	gfx.blit(self.buffer, 1, 0, 0, 0, w, w, w + 1, 0)
	gfx.muladdrect(w + 1, 0, w, w, 0, 0, 0, Color.colors["shadow"][4])

end


function Knob:onDelete()

	Buffer.release(self.buffer)

end


-- Knob - Draw
function Knob:draw()
	local r = self.w / 2
	local o = {x = self.x + r, y = self.y + r}

	-- Value labels
	if self.vals then self:drawvals(o, r) end

  if self.caption and self.caption ~= "" then self:drawCaption(o, r) end


	-- Figure out where the knob is pointing
	local currentAngle = (-5 / 4) + (self.currentStep * self.stepAngle)

	local blitWidth = 3 * r + 2
	local blitX = 1.5 * r

	-- Shadow
	for i = 1, Config.shadowSize do

		gfx.blit(   self.buffer, 1, currentAngle * Math.pi,
                blitWidth + 1, 0, blitWidth, blitWidth,
                o.x - blitX + i - 1, o.y - blitX + i - 1)

	end

	-- Body
	gfx.blit(   self.buffer, 1, currentAngle * Math.pi,
              0, 0, blitWidth, blitWidth,
              o.x - blitX - 1, o.y - blitX - 1)

end


-- Knob - Get/set value
function Knob:val(newval)

	if newval then

    self:setCurrentStep(newval)

		self:redraw()

	else
		return self.retval
	end

end


-- Knob - Dragging.
function Knob:onDrag(state, last)

  -- Ctrl?
	local ctrl = state.mouse.cap&4==4

	-- Multiplier for how fast the knob turns. Higher = slower
	--					Ctrl	Normal
	local adj = ctrl and 1200 or 150

    self:setCurrentVal(
      Math.clamp(self.currentVal + ((last.mouse.y - state.mouse.y) / adj),
      0,
      1
    ))

	self:redraw()
end


function Knob:onDoubleclick()

  self:setCurrentStep(self.default)

	self:redraw()

end


function Knob:onWheel(state)

	local ctrl = state.mouse.cap&4==4

	-- How many steps per wheel-step
	local fine = 1
	local coarse = math.max( Math.round(self.steps / 30), 1)

	local adj = ctrl and fine or coarse

  self:setCurrentVal( Math.clamp( self.currentVal + (state.mouse.wheelInc * adj / self.steps), 0, 1))

	self:redraw()

end



------------------------------------
-------- Drawing methods -----------
------------------------------------

function Knob:drawCaption(o, r)

	Font.set(self.captionFont)
	local cx, cy = Math.polarToCart(1/2, r * 2, o.x, o.y)
	local strWidth, strHeight = gfx.measurestr(self.caption)
	gfx.x, gfx.y = cx - strWidth / 2 + self.captionX, cy - strHeight / 2  + 8 + self.captionY
	Text.drawBackground(self.caption, self.bg)
	Text.drawWithShadow(self.caption, self.textColor, "shadow")

end


function Knob:drawvals(o, r)

  for i = 0, self.steps do

    local angle = (-5 / 4 ) + (i * self.stepAngle)

    -- Highlight the current value
    if i == self.currentStep then
      Color.set(self.headColor)
      Font.set({Font.fonts[self.textFont][1], Font.fonts[self.textFont][2] * 1.2, "b"})
    else
      Color.set(self.textColor)
      Font.set(self.textFont)
    end

    local output = self:formatOutput(
      self:formatRetval( i * self.inc + self.min )
    )

    if output ~= "" then

      local strWidth, strHeight = gfx.measurestr(output)
      local cx, cy = Math.polarToCart(angle, r * 2, o.x, o.y)
      gfx.x, gfx.y = cx - strWidth / 2, cy - strHeight / 2
      Text.drawBackground(output, self.bg)
      gfx.drawstr(output)
    end

  end

end




------------------------------------
-------- Value helpers -------------
------------------------------------

function Knob:setCurrentStep(step)

  self.currentStep = step
  self.currentVal = self.currentStep / self.steps
  self:setRetval()

end


function Knob:setCurrentVal(val)

  self.currentVal = val
  self.currentStep = Math.round(val * self.steps)
  self:setRetval()

end


function Knob:setRetval()

  self.retval = self:formatRetval(self.inc * self.currentStep + self.min)

end


function Knob:formatRetval(val)
  local decimal = tonumber(string.match(val, "%.(.*)") or 0)
  local places = decimal ~= 0 and string.len( decimal) or 0
  return string.format("%." .. places .. "f", val)
end

return Knob
