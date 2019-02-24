------------------------------------
-------- Checklist methods ---------
------------------------------------

local Option = require("gui.elements._option")

local Checklist = setmetatable({}, {__index = Option})

function Checklist:new(props)
--name, z, x, y, w, h, caption, opts, dir, pad
    local checklist = Option:new(props.name, props.x, props.y, props.w, props.h, props.caption, props.opts, props.dir, props.pad)

    checklist.type = "Checklist"

    checklist.optsel = {}

    setmetatable(checklist, self)
    self.__index = self
    return checklist

end


function Checklist:initoptions()

	local size = self.opt_size

	-- Option bubble
	GUI.color("elm_frame")
	gfx.rect(1, 1, size, size, 0)
  gfx.rect(size + 3, 1, size, size, 0)

	GUI.color(self.col_fill)
	gfx.rect(size + 3 + 0.25*size, 1 + 0.25*size, 0.5*size, 0.5*size, 1)

end


function Checklist:val(newval)

	if newval then
		if type(newval) == "table" then
			for k, v in pairs(newval) do
				self.optsel[tonumber(k)] = v
			end
			self:redraw()
        elseif type(newval) == "boolean" and #self.optarray == 1 then

            self.optsel[1] = newval
            self:redraw()
		end
	else
        if #self.optarray == 1 then
            return self.optsel[1]
        else
            local tmp = {}
            for i = 1, #self.optarray do
                tmp[i] = not not self.optsel[i]
            end
            return tmp
        end
		--return #self.optarray > 1 and self.optsel or self.optsel[1]
	end

end


function Checklist:onmouseup()

    -- Bypass option for GUI Builder
    if not self.focus then
        self:redraw()
        return
    end

    local mouseopt = self:getmouseopt()

    if not mouseopt then return end

	self.optsel[mouseopt] = not self.optsel[mouseopt]

    self.focus = false
	self:redraw()

end


function Checklist:isoptselected(opt)

   return self.optsel[opt]

end

return Checklist
