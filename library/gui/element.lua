------------------------------------
-------- Prototype element ---------
----- + all default methods --------
------------------------------------

local Table, T = require("public.table"):unpack()

--[[
    All classes will use this as their template, so that
    elements are initialized with every method available.
]]--
local Element = T{}
function Element:new(name)

    local elm = {}
    if name then elm.name = name end
    self.z = 1

    setmetatable(elm, self)
    self.__index = self
    return elm

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
function Element:onupdate() end

function Element:delete()

    self.ondelete(self)
    -- GUI.Elements[self.name] = nil
    if self.layer then self.layer:remove(self) end

end

-- Called when the element is deleted by GUI.update_elms_list() or :delete.
-- Use it for freeing up buffers and anything else memorywise that this
-- element was doing
function Element:ondelete() end


-- Set or return the element's value
-- Can be useful for something like a Slider that doesn't have the same
-- value internally as what it's displaying
function Element:val() end

-- Called on every update loop if the mouse is over this element.
function Element:onmouseover() end

-- Only called once; won't repeat if the button is held
function Element:onmousedown() end

function Element:onmouseup() end
function Element:ondoubleclick() end

-- Will continue being called even if you drag outside the element
function Element:ondrag() end

-- Right-click
function Element:onmouser_down() end
function Element:onmouser_up() end
function Element:onr_doubleclick() end
function Element:onr_drag() end

-- Middle-click
function Element:onmousem_down() end
function Element:onmousem_up() end
function Element:onm_doubleclick() end
function Element:onm_drag() end

function Element:onwheel() end
function Element:ontype() end


-- Elements like a Textbox that need to keep track of their focus
-- state will use this to e.g. update the text somewhere else
-- when the user clicks out of the box.
function Element:lostfocus() end

-- Called when the script window has been resized
function Element:onresize() end


--	See if the any of the given element's methods need to be called
function Element:Update(state)

  local x, y = state.mouse.x, state.mouse.y
  local x_delta, y_delta = x-state.mouse.lx, y-state.mouse.ly
  local inside = self:isInside(x, y)

  local skip = self:onupdate() or false

  if state.resized then self:onresize() end

  if state.elm_updated then
      if self.focus then
          self.focus = false
          self:lostfocus()
      end
      skip = true
  end


  if skip then return end

  -- Left button
  if state.mouse.cap&1==1 then

      -- If it wasn't down already...
      if not state.mouse.last_down then


          -- Was a different element clicked?
          if not inside then
              if state.mouse_down_elm == self then
                  -- Should already have been reset by the mouse-up, but safeguard...
                  state.mouse_down_elm = nil
              end
              if self.focus then
                  self.focus = false
                  self:lostfocus()
              end
              return 0
          else
              if state.mouse_down_elm == nil then -- Prevent click-through

                  state.mouse_down_elm = self

                  -- Double clicked?
                  if state.mouse.downtime
                  and reaper.time_precise() - state.mouse.downtime < 0.10
                  then

                      state.mouse.downtime = nil
                      state.mouse.dbl_clicked = true
                      self:ondoubleclick()

                  elseif not state.mouse.dbl_clicked then

                      self.focus = true
                      self:onmousedown()

                  end

                  state.elm_updated = true
              end

              state.mouse.down = true
              state.mouse.ox, state.mouse.oy = x, y

              -- Where in the self the mouse was clicked. For dragging stuff
              -- and keeping it in the place relative to the cursor.
              state.mouse.off_x, state.mouse.off_y = x - self.x, y - self.y

          end

      -- 		Dragging? Did the mouse start out in this element?
      elseif (x_delta ~= 0 or y_delta ~= 0)
      and     state.mouse_down_elm == self then
          if self.focus ~= false then

              state.elm_updated = true
              self:ondrag(x_delta, y_delta)

          end
      end

  -- If it was originally clicked in this element and has been released
  elseif state.mouse.down and state.mouse_down_elm.name == self.name then

          state.mouse_down_elm = nil

          if not state.mouse.dbl_clicked then

          self:onmouseup() end

          state.elm_updated = true
          state.mouse.down = false
          state.mouse.dbl_clicked = false
          state.mouse.ox, state.mouse.oy = -1, -1
          state.mouse.off_x, state.mouse.off_y = -1, -1
          state.mouse.lx, state.mouse.ly = -1, -1
          state.mouse.downtime = reaper.time_precise()


  end


  -- Right button
  if state.mouse.cap&2==2 then

      -- If it wasn't down already...
      if not state.mouse.last_r_down then

          -- Was a different element clicked?
          if not inside then
              if state.rmouse_down_elm == self then
                  -- Should have been reset by the mouse-up, but in case...
                  state.rmouse_down_elm = nil
              end
              --self.focus = false
          else

              -- Prevent click-through
              if state.rmouse_down_elm == nil then

                  state.rmouse_down_elm = self

                      -- Double clicked?
                  if state.mouse.r_downtime
                  and reaper.time_precise() - state.mouse.r_downtime < 0.20
                  then

                      state.mouse.r_downtime = nil
                      state.mouse.r_dbl_clicked = true
                      self:onr_doubleclick()

                  elseif not state.mouse.r_dbl_clicked then

                      self:onmouser_down()

                  end

                  state.elm_updated = true

              end

              state.mouse.r_down = true
              state.mouse.r_ox, state.mouse.r_oy = x, y
              -- Where in the self the mouse was clicked. For dragging stuff
              -- and keeping it in the place relative to the cursor.
              state.mouse.r_off_x, state.mouse.r_off_y = x - self.x, y - self.y

          end


      -- 		Dragging? Did the mouse start out in this element?
      elseif (x_delta ~= 0 or y_delta ~= 0)
      and     state.rmouse_down_elm == self then

          if self.focus ~= false then

              self:onr_drag(x_delta, y_delta)
              state.elm_updated = true

          end

      end

  -- If it was originally clicked in this element and has been released
  elseif state.mouse.r_down and state.rmouse_down_elm.name == self.name then

      state.rmouse_down_elm = nil

      if not state.mouse.r_dbl_clicked then self:onmouser_up() end

      state.elm_updated = true
      state.mouse.r_down = false
      state.mouse.r_dbl_clicked = false
      state.mouse.r_ox, state.mouse.r_oy = -1, -1
      state.mouse.r_off_x, state.mouse.r_off_y = -1, -1
      state.mouse.r_lx, state.mouse.r_ly = -1, -1
      state.mouse.r_downtime = reaper.time_precise()

  end



  -- Middle button
  if state.mouse.cap&64==64 then


      -- If it wasn't down already...
      if not state.mouse.last_m_down then


          -- Was a different element clicked?
          if not inside then
              if state.mmouse_down_elm == self then
                  -- Should have been reset by the mouse-up, but in case...
                  state.mmouse_down_elm = nil
              end
          else
              -- Prevent click-through
              if state.mmouse_down_elm == nil then

                  state.mmouse_down_elm = self

                  -- Double clicked?
                  if state.mouse.m_downtime
                  and reaper.time_precise() - state.mouse.m_downtime < 0.20
                  then

                      state.mouse.m_downtime = nil
                      state.mouse.m_dbl_clicked = true
                      self:onm_doubleclick()

                  else

                      self:onmousem_down()

                  end

                  state.elm_updated = true

            end

              state.mouse.m_down = true
              state.mouse.m_ox, state.mouse.m_oy = x, y
              state.mouse.m_off_x, state.mouse.m_off_y = x - self.x, y - self.y

          end



      -- 		Dragging? Did the mouse start out in this element?
      elseif (x_delta ~= 0 or y_delta ~= 0)
      and     state.mmouse_down_elm == self then

          if self.focus ~= false then

              self:onm_drag(x_delta, y_delta)
              state.elm_updated = true

          end

      end

  -- If it was originally clicked in this element and has been released
  elseif state.mouse.m_down and state.mmouse_down_elm.name == self.name then

      state.mmouse_down_elm = nil

      if not state.mouse.m_dbl_clicked then self:onmousem_up() end

      state.elm_updated = true
      state.mouse.m_down = false
      state.mouse.m_dbl_clicked = false
      state.mouse.m_ox, state.mouse.m_oy = -1, -1
      state.mouse.m_off_x, state.mouse.m_off_y = -1, -1
      state.mouse.m_lx, state.mouse.m_ly = -1, -1
      state.mouse.m_downtime = reaper.time_precise()

  end



  -- If the mouse is hovering over the element
  if inside and not state.mouse.down and not state.mouse.r_down then
      self:onmouseover()

      -- Initial mouseover an element
      if state.mouseover_self ~= self then
          state.mouseover_self = self
          state.mouseover_time = reaper.time_precise()

      -- Mouse was moved; reset the timer
      elseif x_delta > 0 or y_delta > 0 then

          state.mouseover_time = reaper.time_precise()

      -- Display a tooltip
      elseif (reaper.time_precise() - state.mouseover_time)
        >= state.tooltip_time then

          state.settooltip(self.tooltip)

      end

  end


  -- If the mousewheel's state has changed
  if inside and state.mouse.wheel ~= state.mouse.lwheel then

      state.mouse.inc = (state.mouse.wheel - state.mouse.lwheel) / 120

      self:onwheel(state.mouse.inc)
      state.elm_updated = true
      state.mouse.lwheel = state.mouse.wheel

  end

  -- If the element is in focus and the user typed something
  if self.focus and state.char ~= 0 then
      self:ontype()
      state.elm_updated = true
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
        w = elm1.layer.window.cur_w,
        h = elm1.layer.window.cur_h
      })

    if not elm2
      and (   elm2.x and elm2.y and elm2.w and elm2.h
          and elm1.x and elm1.y and elm1.w and elm1.h) then return end

    return (elm2.x + (elm2.w - elm1.w) / 2), (elm2.y + (elm2.h - elm1.h) / 2)


end


-- Returns the specified parameters for a given element.
-- If nothing is specified, returns all of the element's properties.
-- ex. local str = GUI.Elements.my_element:Msg("x", "y", "caption", "col_txt")
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

return Element
