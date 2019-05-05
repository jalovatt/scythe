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

-- Loaded classes
GUI.elementClasses = {}

GUI.Init = function ()
  xpcall( function()

    -- -- Initialize a few values
    GUI.lastFuncTime = 0

    -- Convert color presets from 0..255 to 0..1
    for _, col in pairs(Color.colors) do
      col[1], col[2], col[3], col[4] =    col[1] / 255, col[2] / 255,
                                          col[3] / 255, col[4] / 255
    end

  end, Error.crash)
end


GUI.Main = function ()
  xpcall( function ()
    for _, window in pairs(GUI.Windows) do
      window:update()
    end

    if Scythe.quit then return end

    -- If the user gave us a function to run, check to see if it needs to be
    -- run again, and do so.
    if GUI.func then

      local newTime = reaper.time_precise()
      if newTime - GUI.lastFuncTime >= (GUI.funcTime or 1) then
        GUI.func()
        GUI.lastFuncTime = newTime
      end
    end

    for _, window in pairs(GUI.Windows) do
      window:redraw()
    end

    reaper.defer(GUI.Main)

  end, Error.crash)
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

  return class and class:new(props)
end

GUI.createElements = function (...)
  local elms = {}

  for _, props in pairs({...}) do
    elms[#elms + 1] = GUI.createElement(props)
  end

  return table.unpack(elms)
end

GUI.createLayer = function(props)
  return Layer:new(props)
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

    This is just a wrapper for GUI.findElementByName("elm"):val(newval). Any
    elements you plan on checking frequently should have a reference kept
    locally.

    For use with external user functions. Returns the given element's current
    value or, if specified, sets a new one.	Changing values with this is
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

return GUI
