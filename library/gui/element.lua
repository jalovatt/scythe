-- NoIndex: true

------------------------------------
-------- Prototype element ---------
----- + all default methods --------
------------------------------------

local Table, T = require("public.table"):unpack()
local Config = require("gui.config")

--[[
    All classes will use this as their template, so that
    elements are initialized with every method available.
]]--
local Element = T{}
Element.__index = Element
Element.__noRecursive = true

function Element:new()
  return setmetatable(T{}, self)
end

-- Called a) when the script window is first opened
-- 		  b) when any element is created via GUI.New after that
-- i.e. Elements can draw themselves to a buffer once on :init()
-- and then just blit/rotate/etc as needed afterward
function Element:init() end

-- Called whenever the element's z layer is told to redraw
function Element:draw() end

-- Ask for a redraw on the next update
function Element:redraw()
  self.layer.needsRedraw = true
end

-- Called on every update loop, unless the element is hidden or frozen
function Element:onUpdate() end

function Element:delete()

  self.onDelete(self)
  if self.layer then self.layer:remove(self) end

end

-- Called when the element is deleted by GUI.update_elms_list() or :delete.
-- Use it for freeing up buffers and anything else memorywise that this
-- element was doing
function Element:onDelete() end


-- Set or return the element's value
-- Can be useful for something like a Slider that doesn't have the same
-- value internally as what it's displaying
function Element:val() end

function Element:onMouseEnter() end
function Element:onMouseLeave() end

-- Called on every update loop if the mouse is over this element.
function Element:onMouseOver() end

-- Only called once; won't repeat if the button is held
function Element:onMouseDown() end

function Element:onMouseUp() end
function Element:onDoubleclick() end

-- Will continue being called even if you drag outside the element
function Element:onDrag() end

-- Right-click
function Element:onRightMouseDown() end
function Element:onRightMouseUp() end
function Element:onRightDoubleclick() end
function Element:onRightDrag() end

-- Middle-click
function Element:onMiddleMouseDown() end
function Element:onMiddleMouseUp() end
function Element:onMiddleDoubleclick() end
function Element:onMiddleDrag() end

function Element:onWheel() end
function Element:onType() end


-- Elements like a Textbox that need to keep track of their focus
-- state will use this to e.g. update the text somewhere else
-- when the user clicks out of the box.
function Element:onLostFocus() end

-- Called when the script window has been resized
function Element:onResize() end


--	See if the any of the given element's methods need to be called
function Element:Update(state, last)

  local skip = self:onUpdate(state, last)

  if state.resized then self:onResize(state, last) end

  if state.elmUpdated then
    if self.focus then
      self.focus = false
      self:onLostFocus(state, last)
    end

    return
  end

  if skip then return end

  local x, y = state.mouse.x, state.mouse.y
  local inside = self:isInside(x, y)

  local buttons = {
    {
      btn = "",
      down = "leftDown",
    },
    {
      btn = "Right",
      down = "rightDown",
    },
    {
      btn = "Middle",
      down = "middleDown",
    },
  }

  for _, button in ipairs(buttons) do
    if state.elmUpdated then break end

    if state.mouse[button.down] then

      -- If it wasn't down already...
      if not last.mouse[button.down] then

        -- Was a different element clicked?
        if not inside then

          if self.focus then
            self.focus = false
            self:onLostFocus(state, last)
          end

          return
        else
          state.mouse.downElm = self

          -- Double clicked?
          if state.mouse.downTime
          and reaper.time_precise() - state.mouse.downTime < Config.doubleclickTime
          then

            state.mouse.downTime = nil
            state.mouse.doubleClicked = true
            self["on"..button.btn.."Doubleclick"](self, state, last)

          elseif not state.mouse.doubleClicked then

            state.mouse.downTime = reaper.time_precise()
            self.focus = true
            self["on"..button.btn.."MouseDown"](self, state, last)

          end

          state.elmUpdated = true

          state.mouse.ox, state.mouse.oy = x, y

          -- Where in the element the mouse was clicked. For dragging stuff
          -- and keeping it in the place relative to the cursor.
          state.mouse.relativeX, state.mouse.relativeY = x - self.x, y - self.y

        end

      -- 		Dragging? Did the mouse start out in this element?
      elseif last.mouse.downElm == self then

        if (state.mouse.dx ~= 0 or state.mouse.dy ~= 0)
        and self.focus ~= false then

          state.elmUpdated = true
          self["on"..button.btn.."Drag"](self, state, last)

        end
        state.mouse.downElm = last.mouse.downElm
      end

    -- If it was originally clicked in this element and has been released
    -- Important: Clicking in an element, moving the cursor, and releasing the
    -- mouse outside of the element will still trigger an :onMouseUp, since
    -- elements like the Button need to know that the mouse has been released.
    -- Elements should check if state.mouse is inside them
    elseif last.mouse[button.down] and last.mouse.downElm == self then

      state.mouse.downElm = nil

      if not state.mouse.doubleClicked then

        self["on"..button.btn.."MouseUp"](self, state, last)
      end

      state.elmUpdated = true

    end
  end

  -- If the mouse is hovering over the element
  if inside then
    state.mouseOverElm = self
    if not state.mouse.down and not state.mouse.rightDown then

      -- Initial mouseover an element
      if last.mouseOverElm ~= self then
        self:onMouseEnter(state, last)
        state.mouse.mouseOverTime = reaper.time_precise()

      else
        self:onMouseOver(state, last)
        -- Mouse was moved; reset the timer
        if state.mouse.dx ~= 0 or state.mouse.dy ~= 0 then

          state.mouse.mouseOverTime = reaper.time_precise()

        -- Display a tooltip
        elseif self.tooltip
          and (reaper.time_precise() - state.mouse.mouseOverTime)
                >= Config.tooltipTime then

          state.setTooltip(self.tooltip)

        end
      end
    end

  else
    if last.mouseOverElm == self then
      self:onMouseLeave()
    end
  end


  -- If the mousewheel's state has changed
  if inside and state.mouse.wheel ~= last.mouse.wheel then

    state.mouse.wheelInc = (state.mouse.wheel - last.mouse.wheel) / 120

    self:onWheel(state, last)
    state.elmUpdated = true

  end

  -- If the element is in focus and the user typed something
  if self.focus and state.kb.char ~= 0 then
    self:onType(state, last)
    state.elmUpdated = true
  end

end

-- Are these coordinates inside the element?
-- If no coords are given, will use the mouse cursor
function Element:isInside (x, y)

  return	(	x >= (self.x or 0) and x < ((self.x or 0) + (self.w or 0)) and
            y >= (self.y or 0) and y < ((self.y or 0) + (self.h or 0))	)

end

-- Returns the x,y that would center elm1 within elm2.
-- Axis can be "x", "y", or "xy".
-- If elm2 is omitted, centers elm1 in the window instead
function Element:center (elm1, elm2)

  elm2 = elm2
    or (elm1.layer and elm1.layer.window and {
      x = 0,
      y = 0,
      w = elm1.layer.window.currentW,
      h = elm1.layer.window.currentH
    })

  if not elm2
    and (   elm2.x and elm2.y and elm2.w and elm2.h
        and elm1.x and elm1.y and elm1.w and elm1.h) then return end

  return (elm2.x + (elm2.w - elm1.w) / 2), (elm2.y + (elm2.h - elm1.h) / 2)

end


-- Returns the specified parameters for a given element.
-- If nothing is specified, returns all of the element's properties.
-- ex. local str = GUI.Elements.my_element:Msg("x", "y", "caption", "textColor")
function Element:debug(...)

  local arg = {...}

  if #arg == 0 then
    arg = {}
    for k in Table.kpairs(self, "full") do
      arg[#arg+1] = k
    end
  end

  if not self or not self.type then return end
  local pre = tostring(self.name) .. "."
  local strs = {}

  for i = 1, #arg do
    local k, v = arg[i], self[arg[i]]

    strs[#strs + 1] = pre .. tostring(k) .. " = "

    if type(v) == "table" then
      strs[#strs] = strs[#strs] .. "table:"

      -- Hacks to break infinite loops; should probably be done
      -- with some sort of override in the element classes
      -- local depth = (k == "layer" or k == "tabs") and 2
      if (k == "layer") then
        strs[#strs + 1] = Table.stringify(v, 0, 1)
      elseif (k == "tabs") then
        local tabs = {}
        for _, tab in pairs(v) do
          tabs[#tabs + 1] = "  " .. tab.label
          for _, layer in pairs(tab.layers) do
            tabs[#tabs + 1] = "    " .. layer.name .. ", z = " .. layer.z
          end
        end
        strs[#strs + 1] = table.concat(tabs, "\n")
      else
        strs[#strs + 1] = Table.stringify(v, nil, 1)
      end
    else
        strs[#strs] = strs[#strs] .. tostring(v)
    end

  end

  return table.concat(strs, "\n")
end


function Element:moveToLayer(dest)
  if self.layer then self.layer:removeElements(self) end
  if dest then dest:addElements(self) end
end

-- .prototyep isn't strictly necessary, but it offers easy access to an
-- element's parent class
function Element:assignChild(instance)
  setmetatable(instance, self)
  instance.prototype = self

  return instance
end

function Element:formatOutput(val)
  local output

  if self.output then
    local t = type(self.output)

    if t == "string" or t == "number" then
      output = self.output
    elseif t == "table" then
      output = self.output[val]
    elseif t == "function" then
      output = self.output(val)
    end

  end

  return output and tostring(output) or tostring(val)
end

function Element:addDefaultProps (props)
  if type(props) ~= "table" then return props end

  local new = Table.deepCopy(props or {})

  return Table.addMissingKeys(new, self.defaultProps)
end

return Element
