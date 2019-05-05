-- NoIndex: true

local Color = require("public.color")

local Option = require("gui.elements.shared.option")

local Radio = setmetatable({}, {__index = Option})
Radio.__index = Radio

function Radio:new(props)
  local radio = Option:new(props)

  radio.type = "Radio"

  radio.retval, radio.state = 1, 1

  return self:assignChild(radio)
end


function Radio:initOptions()

	local r = self.optionSize / 2

	-- Option bubble
	Color.set(self.bg)
	gfx.circle(r + 1, r + 1, r + 2, 1, 0)
	gfx.circle(3*r + 3, r + 1, r + 2, 1, 0)
	Color.set("elmFrame")
	gfx.circle(r + 1, r + 1, r, 0)
	gfx.circle(3*r + 3, r + 1, r, 0)
	Color.set(self.fillColor)
	gfx.circle(3*r + 3, r + 1, 0.5*r, 1)

end


function Radio:val(newval)

	if newval then
		self.retval = newval
		self.state = newval
		self:redraw()
	else
		return self.retval
	end

end


function Radio:onMouseDown(state)

	self.state = self:getMouseOption(state) or self.state

	self:redraw()

end


function Radio:onMouseUp(state)

  -- Bypass option for GUI Builder
  if not self.focus then
    self:redraw()
    return
  end

	-- Set the new option, or revert to the original if the cursor
  -- isn't inside the list anymore
	if self:isInside(state.mouse.x, state.mouse.y) then
		self.retval = self.state
	else
		self.state = self.retval
	end

  self.focus = false
	self:redraw()

end


function Radio:onDrag(state)

	self:onMouseDown(state)
	self:redraw()

end


function Radio:onWheel(state)

  self.state = self:getNextOption(    ( (state.mouse.wheelInc > 0) ~= self.horizontal )
                                      and -1
                                      or 1 )

	self.retval = self.state

	self:redraw()

end


function Radio:isOptionSelected(opt)

  return opt == self.state

end


function Radio:getNextOption(dir)

  local j = dir > 0 and #self.options or 1

  for i = self.state + dir, j, dir do

    if self.options[i] ~= "_" then
        return i
    end

  end

  return self.state

end

return Radio
