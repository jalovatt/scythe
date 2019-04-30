-- NoIndex: true
-- luacheck: globals Scythe

local Table, T = require("public.table"):unpack()
local Color = require("public.color")
local Font = require("public.font")
local Math = require("public.math")
local Config = require("gui.config")

local Window = T{}
Window.__index = Window
Window.__noRecursive = true

Window.defaultProps = {
  name = "Window",
  x = 0,
  y = 0,
  w = 640,
  h = 480,
  layerCount = 0,
  isOpen = false,
  isRunning = true,
  needsRedraw = false,
  onClose = function() Scythe.quit = true end,
}

function Window:new(props)
  local window = Table.deepCopy(props)
  Table.addMissingKeys(window, self.defaultProps)

  window.layers = T{}

  return setmetatable(window, self)

end

function Window:open()
  -- TODO: Restore previous size and position

  -- Create the window
  local bg = Table.map(Color.colors.windowBg,
    function(val) return val * 255 end
  )
  gfx.clear = reaper.ColorToNative(table.unpack(bg))

  if self.anchor and self.corner then
    self.x, self.y = self:getAnchoredPosition( self.x, self.y, self.w, self.h,
                                          self.anchor, self.corner)
  end

  gfx.init(self.name, self.w, self.h, self.dock or 0, self.x, self.y)

  self.currentW, self.currentH = gfx.w, gfx.h

  -- Measure the window's title bar, in case we need it
  local _, _, windowY, _, _ = gfx.dock(-1, 0, 0, 0, 0)
  local _, innerY = gfx.clienttoscreen(0, 0)
  self.titleHeight = innerY - windowY


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

  self.lastState = self.state

  self.isOpen = true

  self:sortLayers()
  for _, layer in pairs(self.layers) do
    layer:init()
  end
end

function Window:reopen(params)
  -- params: x, y, w, h, dock
  local currentDock,currentX,currentY,currentW,currentH = gfx.dock(-1,0,0,0,0)

  gfx.quit()
  gfx.init(
    self.name,
    params.w or currentW,
    params.h or currentH,
    params.dock or currentDock,
    params.x or currentX,
    params.y or currentY
  )

  self.currentW = gfx.w
  self.currentH = gfx.h
end

function Window:sortLayers()
  self.sortedLayers = self.layers:sortHashesByKey("z")
end

function Window:close()
  -- TODO: Store current size and position
  self:clearTooltip()
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
  local w, h = self.currentW, self.currentH

  if self.layers:any(function(l) return l.needsRedraw end)
    or self.needsRedraw then

    -- All of the layers will be drawn to their own buffer (dest = z), then
    -- composited in buffer 0. This allows buffer 0 to be blitted as a whole
    -- when none of the layers need to be redrawn.

    gfx.dest = 0
    gfx.setimgdim(0, -1, -1)
    gfx.setimgdim(0, w, h)

    Color.set("windowBg")
    gfx.rect(0, 0, w, h, 1)

    for i = #self.sortedLayers, 1, -1 do
      local layer = self.sortedLayers[i]
        if  (layer.elementCount > 0 and not layer.hidden) then

          if layer.needsRedraw or self.needsRedraw then
            layer:redraw()
          end

          gfx.blit(layer.buffer, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
        end
    end

    -- Draw developer hints if necessary
    if Scythe.developerMode then
      self:drawDev()
    else
      self:drawVersion()
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
  if Scythe.quit then
    self:close()
    return
  end

  if (not self.isOpen and self.isRunning) then return end
  self:sortLayers()

  self:updateInputState()
  self.elmUpdated = false

  self:handleWindowEvents()

  if self.layerCount > 0 and self.isOpen and self.isRunning then
    self:updateLayers()
  end

  if self.tooltip and not self.state.mouseOverElm then
    self:clearTooltip()
  end

end

function Window:handleWindowEvents()
  local state, last = self.state, self.lastState

  -- Window closed
  if (state.kb.char == 27 and not (  state.mouse.cap & 4 == 4
                              or 	state.mouse.cap & 8 == 8
                              or 	state.mouse.cap & 16 == 16))
    or state.kb.char == -1
    or Scythe.quit == true then

    self:close()
    return 0
  end

  -- Dev mode toggle
  if  state.kb.char == 282         and state.mouse.cap & 4 ~= 0
  and state.mouse.cap & 8 ~= 0  and state.mouse.cap & 16 ~= 0 then
    Scythe.developerMode = not Scythe.developerMode
    self.elmUpdated = true
    self.needsRedraw = true
  end

  if not self.lastState then return end

  -- Window resized
  if last.currentW
  and (state.currentW ~= last.currentW or state.currentH ~= last.currentH) then
    if self.onResize then self.onResize() end
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

    -- Values that need to persist from one loop to the next
    downTime = last.mouse.downTime,
    downElm = last.mouse.downElm,
    doubleClicked = last.doubleClicked,
    ox = last.mouse.ox,
    oy = last.mouse.oy,
    relativeX = last.mouse.relativeX,
    relativeY = last.mouse.relativeY,
    mouseOverTime = last.mouse.mouseOverTime,
  }

  state.kb = {
    char = gfx.getchar(),
  }

  state.currentW = gfx.w
  state.currentH = gfx.h

  state.setTooltip = function(str) self:setTooltip(state.mouse.x, state.mouse.y, str) end

  self.state = state
  self.lastState = last

end

function Window:updateLayers()
  for i = 1, self.layerCount do
    self.sortedLayers[i]:update(self.state, self.lastState)
  end
end


--[[
Returns x,y coordinates for a window with the specified anchor position

If no anchor is specified, it will default to the top-left corner of the screen.
    x,y		offset coordinates from the anchor position
    w,h		window dimensions
    anchor	"screen" or "mouse"
    corner	"TL"
            "T"
            "TR"
            "R"
            "BR"
            "B"
            "BL"
            "L"
            "C"
]]--
function Window:getAnchoredPosition(x, y, w, h, anchor, corner)

  local ax, ay, aw, ah = 0, 0, 0 ,0

  local _, _, screenW, screenH = reaper.my_getViewport( x, y, x + w, y + h,
                                                        x, y, x + w, y + h, 1)

  if anchor == "screen" then
    aw, ah = screenW, screenH
  elseif anchor =="mouse" then
    ax, ay = reaper.GetMousePosition()
  end

  local cx, cy = 0, 0
  if corner then
    local corners = {
        TL = 	{0, 				      0},
        T =		{(aw - w) / 2, 		0},
        TR = 	{(aw - w) - 16,		0},
        R =		{(aw - w) - 16,		(ah - h) / 2},
        BR = 	{(aw - w) - 16,		(ah - h) - 40},
        B =		{(aw - w) / 2, 		(ah - h) - 40},
        BL = 	{0, 				      (ah - h) - 40},
        L =	 	{0, 				      (ah - h) / 2},
        C =	 	{(aw - w) / 2,		(ah - h) / 2},
    }

    cx, cy = table.unpack(corners[string.upper(corner)])
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


-- Display a tooltip
function Window:setTooltip(x, y, str)
  if not str or str == "" then return end

  --Lua: reaper.TrackCtl_SetToolTip(string fmt, integer xpos, integer ypos, boolean topmost)
  --displays tooltip at location, or removes if empty string
  -- local x, y = gfx.clienttoscreen(0, 0)

  reaper.TrackCtl_SetToolTip(
    str,
    self.x + x + 16,
    self.y + y + 16,
    true
  )
  self.tooltip = str

end


-- Clear the tooltip
function Window:clearTooltip()

  reaper.TrackCtl_SetToolTip("", 0, 0, true)
  self.tooltip = nil

end


-- Display the GUI version number
-- Set Scythe.version = 0 to hide this
function Window:drawVersion()

  if not Scythe.version then return 0 end

  local str = "Scythe "..Scythe.version

  Font.set("version")
  Color.set("txt")

  local strWidth, strHeight = gfx.measurestr(str)

  gfx.x = gfx.w - strWidth - 6
  gfx.y = gfx.h - strHeight - 4

  gfx.drawstr(str)

end

-- Draws a grid overlay and some developer hints
-- Toggled via Ctrl+Shift+Alt+Z, or by setting Scythe.developerMode = true
function Window:drawDev()

  -- Draw a grid for placing elements
  Color.set("magenta")
  Font.set("monospace")

  for i = 0, self.w, Config.dev.gridMinor do

    local a = (i % Config.dev.gridMajor == 0)

    gfx.a = a and 1 or 0.3
    gfx.line(i, 0, i, self.h)
    gfx.line(0, i, self.w, i)

    if a then
      gfx.x, gfx.y = i + 4, 4
      gfx.drawstr(i)
      gfx.x, gfx.y = 4, i + 4
      gfx.drawstr(i)
    end

  end

  local str = "Mouse: "..
    math.modf(self.state.mouse.x)..", "..
    math.modf(self.state.mouse.y).." "

  local strWidth, strHeight = gfx.measurestr(str)
  gfx.x, gfx.y = self.w - strWidth - 2, self.h - 2*strHeight - 2

  Color.set("black")
  gfx.rect(gfx.x - 2, gfx.y - 2, strWidth + 4, 2*strHeight + 4, true)

  Color.set("white")
  gfx.drawstr(str)

  local snapX = Math.nearestMultiple(self.state.mouse.x, Config.dev.gridMinor)
  local snapY = Math.nearestMultiple(self.state.mouse.y, Config.dev.gridMinor)

  gfx.x, gfx.y = self.w - strWidth - 2, self.h - strHeight - 2
  gfx.drawstr(" Snap: "..snapX..", "..snapY)

  gfx.a = 1

end




return Window
