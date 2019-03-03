-- NoIndex: true

--[[	Lokasenna_GUI - Knob class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Knob

    Creation parameters:
	name, z, x, y, w, caption, min, max, default,[ inc, vals]

]]--

local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local GFX = require("public.gfx")
local Text = require("public.text")

local Knob = require("gui.element"):new()

function Knob:new(props)

	local knob = props

	knob.type = "Knob"

	knob.x = knob.x or 0
  knob.y = knob.y or 0
  knob.w = knob.w or 64
  knob.h = knob.w

	knob.caption = knob.caption or "Knob"
	knob.bg = knob.bg or "wnd_bg"

  knob.cap_x = knob.cap_x or 0
  knob.cap_y = knob.cap_y or 0

	knob.font_a = knob.font_a or 3
	knob.font_b = knob.font_b or 4

	knob.col_txt = knob.col_txt or "txt"
	knob.col_head = knob.col_head or "elm_fill"
	knob.col_body = knob.col_body or "elm_frame"

	knob.min = knob.min or 0
  knob.max = knob.max or 10
  knob.inc = knob.inc or inc or 1


  knob.steps = math.abs(knob.max - knob.min) / knob.inc

  function knob:formatretval(val)
    local decimal = tonumber(string.match(val, "%.(.*)") or 0)
    local places = decimal ~= 0 and string.len( decimal) or 0
    return string.format("%." .. places .. "f", val)
  end

	knob.vals = knob.vals or (knob.vals == nil and true)

	-- Determine the step angle
	knob.stepangle = (3 / 2) / knob.steps

	knob.default = knob.default or 5
  knob.curstep = knob.default

	knob.curval = knob.curstep / knob.steps

  knob.retval = knob:formatretval(
              ((knob.max - knob.min) / knob.steps) * knob.curstep + knob.min
                                    )

  knob.prototype = Knob
	setmetatable(knob, self)
	self.__index = self
	return knob

end


function Knob:init()

	self.buff = self.buff or GUI.GetBuffer()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)

	-- Figure out the points of the triangle

	local r = self.w / 2
	local rp = r * 1.5
	local curangle = 0
	local o = rp + 1

	local w = 2 * rp + 2

	gfx.setimgdim(self.buff, 2*w, w)

	local side_angle = (math.acos(0.666667) / Math.pi) * 0.9

	local Ax, Ay = Math.polar2cart(curangle, rp, o, o)
    local Bx, By = Math.polar2cart(curangle + side_angle, r - 1, o, o)
	local Cx, Cy = Math.polar2cart(curangle - side_angle, r - 1, o, o)

	-- Head
	Color.set(self.col_head)
	GFX.triangle(true, Ax, Ay, Bx, By, Cx, Cy)
	Color.set("elm_outline")
	GFX.triangle(false, Ax, Ay, Bx, By, Cx, Cy)

	-- Body
	Color.set(self.col_body)
	gfx.circle(o, o, r, 1)
	Color.set("elm_outline")
	gfx.circle(o, o, r, 0)

	--gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs] )
	gfx.blit(self.buff, 1, 0, 0, 0, w, w, w + 1, 0)
	gfx.muladdrect(w + 1, 0, w, w, 0, 0, 0, Color.colors["shadow"][4])

end


function Knob:ondelete()

	GUI.FreeBuffer(self.buff)

end


-- Knob - Draw
function Knob:draw()

	local x, y = self.x, self.y

	local r = self.w / 2
	local o = {x = x + r, y = y + r}


	-- Value labels
	if self.vals then self:drawvals(o, r) end

    if self.caption and self.caption ~= "" then self:drawcaption(o, r) end


	-- Figure out where the knob is pointing
	local curangle = (-5 / 4) + (self.curstep * self.stepangle)

	local blit_w = 3 * r + 2
	local blit_x = 1.5 * r

	-- Shadow
	for i = 1, Text.drawWithShadow_dist do

		gfx.blit(   self.buff, 1, curangle * Math.pi,
                    blit_w + 1, 0, blit_w, blit_w,
                    o.x - blit_x + i - 1, o.y - blit_x + i - 1)

	end

	-- Body
	gfx.blit(   self.buff, 1, curangle * Math.pi,
                0, 0, blit_w, blit_w,
                o.x - blit_x - 1, o.y - blit_x - 1)

end


-- Knob - Get/set value
function Knob:val(newval)

	if newval then

        self:setcurstep(newval)

		self:redraw()

	else
		return self.retval
	end

end


-- Knob - Dragging.
function Knob:ondrag()

	local y = GUI.mouse.y
	local ly = GUI.mouse.ly

	-- Ctrl?
	local ctrl = GUI.mouse.cap&4==4

	-- Multiplier for how fast the knob turns. Higher = slower
	--					Ctrl	Normal
	local adj = ctrl and 1200 or 150

    self:setcurval( Math.clamp(self.curval + ((ly - y) / adj), 0, 1) )

    --[[
	self.curval = self.curval + ((ly - y) / adj)
	if self.curval > 1 then self.curval = 1 end
	if self.curval < 0 then self.curval = 0 end



	self.curstep = Math.round(self.curval * self.steps)

	self.retval = Math.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
    ]]--
	self:redraw()

end


-- Knob - Doubleclick
function Knob:ondoubleclick()
	--[[
	self.curstep = self.default
	self.curval = self.curstep / self.steps
	self.retval = Math.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
	]]--

    self:setcurstep(self.default)

	self:redraw()

end


-- Knob - Mousewheel
function Knob:onwheel()

	local ctrl = GUI.mouse.cap&4==4

	-- How many steps per wheel-step
	local fine = 1
	local coarse = math.max( Math.round(self.steps / 30), 1)

	local adj = ctrl and fine or coarse

    self:setcurval( Math.clamp( self.curval + (GUI.mouse.inc * adj / self.steps), 0, 1))

	self:redraw()

end



------------------------------------
-------- Drawing methods -----------
------------------------------------

function Knob:drawcaption(o, r)

    local str = self.caption

	Font.set(self.font_a)
	local cx, cy = Math.polar2cart(1/2, r * 2, o.x, o.y)
	local str_w, str_h = gfx.measurestr(str)
	gfx.x, gfx.y = cx - str_w / 2 + self.cap_x, cy - str_h / 2  + 8 + self.cap_y
	Text.text_bg(str, self.bg)
	Text.drawWithShadow(str, self.col_txt, "shadow")

end


function Knob:drawvals(o, r)

    for i = 0, self.steps do

        local angle = (-5 / 4 ) + (i * self.stepangle)

        -- Highlight the current value
        if i == self.curstep then
            Color.set(self.col_head)
            Font.set({Font.fonts[self.font_b][1], Font.fonts[self.font_b][2] * 1.2, "b"})
        else
            Color.set(self.col_txt)
            Font.set(self.font_b)
        end

        --local output = (i * self.inc) + self.min
        local output = self:formatretval( i * self.inc + self.min )

        if self.output then
            local t = type(self.output)

            if t == "string" or t == "number" then
                output = self.output
            elseif t == "table" then
                output = self.output[output]
            elseif t == "function" then
                output = self.output(output)
            end
        end

        -- Avoid any crashes from weird user data
        output = tostring(output)

        if output ~= "" then

            local str_w, str_h = gfx.measurestr(output)
            local cx, cy = Math.polar2cart(angle, r * 2, o.x, o.y)
            gfx.x, gfx.y = cx - str_w / 2, cy - str_h / 2
            Text.text_bg(output, self.bg)
            gfx.drawstr(output)
        end

    end

end




------------------------------------
-------- Value helpers -------------
------------------------------------

function Knob:setcurstep(step)

    self.curstep = step
    self.curval = self.curstep / self.steps
    self:setretval()

end


function Knob:setcurval(val)

    self.curval = val
    self.curstep = Math.round(val * self.steps)
    self:setretval()

end


function Knob:setretval()

    self.retval = self:formatretval(self.inc * self.curstep + self.min)

end

return Knob
