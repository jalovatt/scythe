local Table, T = require("public.table"):unpack()
local Color = require("public.color")

local Window = T{}
function Window:new(props)
  local window = props

  window.name = window.name or "Window"

  window.x = window.x or 0
  window.y = window.y or 0
  window.w = window.w or 640
  window.h = window.h or 480

  window.layerCount = 0
  window.layers = T{}

  window.isOpen = false
  window.isRunning = (window.isRunning == nil) and true

  window.needsRedraw = false

  setmetatable(window, self)
  self.__index = self

  return window
end

function Window:open()
  -- TODO: Restore previous size and position

  -- Create the window
  local bg = Table.map(Color.colors.wnd_bg,
    function(val) return val * 255 end
  )
  gfx.clear = reaper.ColorToNative(table.unpack(bg))

  if self.anchor and self.corner then
    self.x, self.y = self:getAnchoredPosition( self.x, self.y, self.w, self.h,
                                          self.anchor, self.corner)
  end

  gfx.init(self.name, self.w, self.h, self.dock or 0, self.x, self.y)

  self.cur_w, self.cur_h = gfx.w, gfx.h

  -- Measure the window's title bar, in case we need it
  local _, _, wnd_y, _, _ = gfx.dock(-1, 0, 0, 0, 0)
  local _, gui_y = gfx.clienttoscreen(0, 0)
  self.title_height = gui_y - wnd_y


  -- Initialize a few values
  self.state = T{
    mouse = {
      x = 0,
      y = 0,
      cap = 0,
      down = false,
      wheel = 0,
      lwheel = 0
    }
  }

  self.last_state = self.state

  self.isOpen = true

  self:sortLayers()

  for _, layer in pairs(self.layers) do
    layer:init()
  end
end

function Window:sortLayers()
  self.sortedLayers = self.layers:sortHashesByKey("z")
  -- self.z_max = self.sortedLayers[self.layerCount].z
end

function Window:close()
  -- TODO: Store current size and position
  self.isOpen = false
  self:onClose()
  gfx.quit()
end

function Window:pause()
  self.isRunning = false
end

function Window:run()
  self.isRunning = true
end

function Window:redraw()
  if self.layerCount == 0 then return end

  -- Redraw all of the elements, starting from the bottom up.
  local w, h = self.cur_w, self.cur_h

  -- local need_redraw, global_redraw -- luacheck: ignore 221
  -- if GUI.redraw_z[0] then
  --     global_redraw = true
  --     GUI.redraw_z[0] = false
  -- else

  if self.layers:any(function(l) return l.needsRedraw end)
    or self.needsRedraw then

      -- All of the layers will be drawn to their own buffer (dest = z), then
      -- composited in buffer 0. This allows buffer 0 to be blitted as a whole
      -- when none of the layers need to be redrawn.

      gfx.dest = 0
      gfx.setimgdim(0, -1, -1)
      gfx.setimgdim(0, w, h)

      Color.set("wnd_bg")
      gfx.rect(0, 0, w, h, 1)

      for i = #self.sortedLayers, 1, -1 do
        local layer = self.sortedLayers[i]
          if  (layer.elementCount > 0 and not layer.hidden) then

              if layer.needsRedraw or self.needsRedraw then
                layer:redraw(GUI)
              end

              gfx.blit(layer.buff, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
          end
      end

      -- Draw developer hints if necessary
      if GUI.dev_mode then
          GUI.Draw_Dev()
      else
          GUI.Draw_Version()
      end

  end

  -- Reset them again, to be extra sure
  gfx.mode = 0
  gfx.set(0, 0, 0, 1)

  gfx.dest = -1
  gfx.blit(0, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)

  gfx.update()

  self.needsRedraw = false
end

function Window:addLayers(...)
  for _, layer in pairs({...}) do
    self.layers[layer.name] = layer
    layer.window = self
    self.layerCount = self.layerCount + 1
  end

  self.needsRedraw = true
  return self
end

function Window:removeLayers(...)
  for _, layer in pairs({...}) do
    self.layers[layer.name] = nil
    layer.window = nil
    self.layerCount = self.layerCount - 1
  end

  self.needsRedraw = true
  return self
end

function Window:update()
  if (not self.isOpen and self.isRunning) then return end
  self:sortLayers()

  self:updateInputState()
  self.elm_updated = false

  if self:handleWindowEvents() == 0 then return end

  if self.layerCount > 0 and self.isOpen and self.isRunning then
    self:updateLayers()
  end
end

function Window:handleWindowEvents()
  local state, last = self.state, self.last_state

  -- Window closed
  if (state.kb.char == 27 and not (  state.mouse.cap & 4 == 4
                              or 	state.mouse.cap & 8 == 8
                              or 	state.mouse.cap & 16 == 16))
    or state.kb.char == -1
    or state.quit == true then

    GUI.cleartooltip()
    self:close()
    return 0
  end

  -- Dev mode toggle
  if  state.kb.char == 282         and state.mouse.cap & 4 ~= 0
  and state.mouse.cap & 8 ~= 0  and state.mouse.cap & 16 ~= 0 then
    self.dev_mode = not self.dev_mode
    self.elm_updated = true
    self.needsRedraw = true
  end

  if not self.last then return end

  -- Window resized
  if (state.cur_w ~= last.cur_w or state.cur_h ~= last.cur_h)
  and self.onResize then
    self.onResize()
    state.resized = true
  end

  -- Mouse moved
  if (state.x ~= last.x or state.y ~= last.y)
  and self.onMouseMove then
    self.onMouseMove()
  end



end

function Window:updateInputState()
  local last = self.state
  local state = T{}

  state.mouse = {
    x = gfx.mouse_x,
    y = gfx.mouse_y,
    cap         = gfx.mouse_cap,
    leftDown    = gfx.mouse_cap & 1 == 1,
    rightDown   = gfx.mouse_cap & 2 == 2,
    middleDown  = gfx.mouse_cap & 64 == 64,
    wheel = gfx.mouse_wheel,
    dx = gfx.mouse_x - last.mouse.x,
    dy = gfx.mouse_y - last.mouse.y,
  }

  state.kb = {
    char = gfx.getchar(),
  }

  state.cur_w = gfx.w
  state.cur_h = gfx.h

  -- Values that need to persist from one loop to the next
  state.mouse.downtime = last.downtime
  state.mouse_down_elm = last.mouse_down_elm
  state.mouse.dbl_clicked = last.dbl_clicked
  state.mouse.ox = last.mouse.ox
  state.mouse.oy = last.mouse.oy
  state.mouse.off_x = last.mouse.off_x
  state.mouse.off_y = last.mouse.off_y
  state.mouseover_time = last.mouseover_time
  state.tooltip_time = last.tooltip_time

  self.state = state
  self.last_state = last

end

function Window:updateLayers()
  for i = 1, self.layerCount do
    self.sortedLayers[i]:update(self.state, self.last_state)
  end
end

function Window:getAnchoredPosition(x, y, w, h, anchor, corner)

    local ax, ay, aw, ah = 0, 0, 0 ,0

    local _, _, scr_w, scr_h = reaper.my_getViewport( x, y, x + w, y + h,
                                                      x, y, x + w, y + h, 1)

    if anchor == "screen" then
        aw, ah = scr_w, scr_h
    elseif anchor =="mouse" then
        ax, ay = reaper.GetMousePosition()
    end

    local cx, cy = 0, 0
    if corner then
        local corners = {
            TL = 	{0, 				0},
            T =		{(aw - w) / 2, 		0},
            TR = 	{(aw - w) - 16,		0},
            R =		{(aw - w) - 16,		(ah - h) / 2},
            BR = 	{(aw - w) - 16,		(ah - h) - 40},
            B =		{(aw - w) / 2, 		(ah - h) - 40},
            BL = 	{0, 				(ah - h) - 40},
            L =	 	{0, 				(ah - h) / 2},
            C =	 	{(aw - w) / 2,		(ah - h) / 2},
        }

        cx, cy = table.unpack(corners[corner])
    end

    x = x + ax + cx
    y = y + ay + cy

    return x, y
end

function Window:findElementByName(name, ...)
  for _, layer in pairs(... and {...} or self.layers) do
    local elm = layer:findElementByName(name)
    if elm then return elm end
  end
end
return Window
