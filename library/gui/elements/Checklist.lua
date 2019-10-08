-- NoIndex: true

local Color = require("public.color")
local Table = require("public.table")

local Option = require("gui.elements.shared.option")

local Checklist = setmetatable({}, {__index = Option})
Checklist.__index = Checklist

function Checklist:new(props)
    local checklist = Option:new(props)

    checklist.type = "Checklist"

    checklist.selectedOptions = checklist.selectedOptions or {}

    return setmetatable(checklist, self)
end


function Checklist:initOptions()

	local size = self.optionSize

	-- Option frame
	Color.set("elmFrame")
	gfx.rect(1, 1, size, size, 0)
  gfx.rect(size + 3, 1, size, size, 0)

  -- Option fill
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
      return Table.map(self.selectedOptions, function(val) return not not val end)
    end
	end

end


function Checklist:onMouseUp(state)
  if state.preventDefault then return end

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
