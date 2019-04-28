------------------------------------
-------- Checklist methods ---------
------------------------------------

local Color = require("public.color")

local Option = require("gui.elements._option")

local Checklist = setmetatable({}, {__index = Option})
Checklist.__index = Checklist

function Checklist:new(props)
    local checklist = Option:new(props)

    checklist.type = "Checklist"

    checklist.selectedOptions = checklist.selectedOptions or {}

    return self:assignChild(checklist)
end


function Checklist:initOptions()

	local size = self.optionSize

	-- Option bubble
	Color.set("elmFrame")
	gfx.rect(1, 1, size, size, 0)
  gfx.rect(size + 3, 1, size, size, 0)

	Color.set(self.fillColor)
	gfx.rect(size + 3 + 0.25*size, 1 + 0.25*size, 0.5*size, 0.5*size, 1)

end


function Checklist:val(newval)

	if newval then
		if type(newval) == "table" then
			for k, v in pairs(newval) do
				self.selectedOptions[tonumber(k)] = v
			end
    elseif type(newval) == "boolean" and #self.options == 1 then
      self.selectedOptions[1] = newval
    end
    self:redraw()
	else
    if #self.options == 1 then
      return self.selectedOptions[1]
    else
      local tmp = {}
      for i = 1, #self.options do
        tmp[i] = not not self.selectedOptions[i]
      end
      return tmp
    end
	end

end


function Checklist:onMouseUp(state)

  local mouseOption = self:getMouseOption(state)

  if not mouseOption then return end

	self.selectedOptions[mouseOption] = not self.selectedOptions[mouseOption]

  self.focus = false
	self:redraw()

end


function Checklist:isOptionSelected(opt)

  return self.selectedOptions[opt]

end

return Checklist
