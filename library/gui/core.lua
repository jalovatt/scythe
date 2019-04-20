-- NoIndex: true

-- luacheck: globals Scythe Error

if not Scythe then
  error("Couldn't find Scythe. Please make sure the Scythe library has been loaded.")
  return
end

local Error = Error

-- luacheck: globals GUI
local GUI = {}

local Table, T = require("public.table"):unpack()
-- local Font = require("public.font")
local Color = require("public.color")
-- local Math = require("public.math")
local Layer = require("gui.layer")
local Window = require("gui.window")
-- local Config = require("gui.config")




------------------------------------
-------- Main functions ------------
------------------------------------

GUI.Windows = T{}
-- GUI.Layers = T{}

-- Loaded classes
GUI.elementClasses = {}

GUI.Init = function ()
  xpcall( function()
    -- -- Initialize a few values
    GUI.last_time = 0

    -- Convert color presets from 0..255 to 0..1
    for _, col in pairs(Color.colors) do
      col[1], col[2], col[3], col[4] =    col[1] / 255, col[2] / 255,
                                          col[3] / 255, col[4] / 255
    end

    if GUI.exit then reaper.atexit(GUI.exit) end

  end, Error.crash)
end

GUI.update_windows = function()
  for _, window in pairs(GUI.Windows) do
    window:update()
  end
end

GUI.Main = function ()
  xpcall( function ()
    GUI.update_windows()

    if GUI.quit then return end

    -- If the user gave us a function to run, check to see if it needs to be
    -- run again, and do so.
    if GUI.func then

      local new_time = reaper.time_precise()
      if new_time - GUI.last_time >= (GUI.freq or 1) then
        GUI.func()
        GUI.last_time = new_time
      end
    end

    GUI.Main_Draw()

    reaper.defer(GUI.Main)

  end, Error.crash)
end

GUI.Main_Draw = function ()
  for _, window in pairs(GUI.Windows) do
    window:redraw()
  end
end




------------------------------------
-------- Element functions ---------
------------------------------------

GUI.addElementClass = function(type)
  local ret, val = pcall(require, ("gui.elements."..type))

  if not ret then
    error("Error loading the element class '" .. type .."':\n" .. val)
    return nil
  end

  GUI.elementClasses[type] = val
  return val
end

GUI.createElement = function (props)
  local class = GUI.elementClasses[props.type]
             or GUI.addElementClass(props.type)

  if not class then return nil end

  local elm = class:new(props)

  if GUI.gfx_open then elm:init() end

  return elm
end

GUI.createElements = function (...)
  local elms = {}

  for _, props in pairs({...}) do
    elms[#elms + 1] = GUI.createElement(props)
  end

  return table.unpack(elms)
end

GUI.createLayer = function(props)
  local layer = Layer:new(props)

  return layer
end

GUI.createLayers = function (...)
  local layers = {}

  for _, props in pairs({...}) do
    layers[#layers + 1] = GUI.createLayer(props)
  end

  return table.unpack(layers)
end

GUI.createWindow = function (props)
  local window = Window:new(props)
  GUI.Windows[window.name] = window

  return window
end

GUI.createWindows = function (...)
  local windows = {}

  for _, props in pairs({...}) do
    windows[#windows + 1] = GUI.createWindow(props)
  end

  return table.unpack(windows)
end

GUI.findElementByName = function (name, ...)
  for _, window in pairs(... and {...} or GUI.Windows) do
    local elm = window:findElementByName(name)
    if elm then return elm end
  end
end

--[[	Return or change an element's value

    *** DEPRECATED ***
    This is now just a wrapper for GUI.findElementByName("elm"):val(newval)

    For use with external user functions. Returns the given element's current
    value or, if specified, sets a new one.	Changing values with this is often
    preferable to setting them directly, as most :val methods will also update
    some internal parameters and redraw the element when called.
]]--
GUI.Val = function (elmName, newval)
  local elm = GUI.findElementByName(elmName)
  if not elm then return nil end

  if newval ~= nil then
      elm:val(newval)
  else
      return elm:val()
  end
end


------------------------------------
-------- File/Storage functions ----
------------------------------------

-- To open files in their default app, or URLs in a browser
-- Using os.execute because reaper.ExecProcess behaves weird
-- occasionally stops working entirely on my system.
GUI.open_file = function(path)

  local OS = reaper.GetOS()

  local cmd = ( string.match(OS, "Win") and "start" or "open" ) ..
              ' "" "' .. path .. '"'

  os.execute(cmd)

end


-- CURRENTLY BROKEN
-- Saves the current script window parameters to an ExtState under the given section name
-- Returns dock, x, y, w, h
GUI.save_window_state = function (name, title)

  if not name then return end
  local state = {gfx.dock(-1, 0, 0, 0, 0)}
  reaper.SetExtState(name, title or "window", table.concat(state, ","), true)

  return table.unpack(state)

end


-- CURRENTLY BROKEN
-- Looks for an ExtState containing saved window parameters
-- Returns dock, x, y, w, h
GUI.load_window_state = function (name, title)

  if not name then return end

  local str = reaper.GetExtState(name, title or "window")
  if not str or str == "" then return end

  local dock, x, y, w, h =
    str:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")

  if not (dock and x and y and w and h) then return end
  GUI.dock, GUI.x, GUI.y, GUI.w, GUI.h = dock, x, y, w, h

  -- Probably don't want these messing up where the user put the window
  GUI.anchor, GUI.corner = nil, nil

  return dock, x, y, w, h

end

return GUI
