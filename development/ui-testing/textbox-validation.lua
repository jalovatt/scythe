-- NoIndex: true

--[[
  Scythe example

  - General demonstration
  - Tabs and layer sets
  - Accessing elements' parameters

]]--

-- The core library must be loaded prior to anything else
local libPath = reaper.GetExtState("Scythe", "libPath_v3")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Set Scythe v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

loadfile(libPath .. "scythe.lua")()
local GUI = require("gui.core")




------------------------------------
-------- Functions -----------------
------------------------------------


local layers


------------------------------------
-------- Window settings -----------
------------------------------------


local window = GUI.createWindow({
  name = "Textbox Validation",
  x = 0,
  y = 0,
  w = 432,
  h = 500,
  anchor = "mouse",
  corner = "C",
})

layers = table.pack( GUI.createLayers(
  {name = "Layer1", z = 1}
))

window:addLayers(table.unpack(layers))


------------------------------------
-------- Global elements -----------
------------------------------------


layers[1]:addElements( GUI.createElements(
  {
    name = "txt1",
    type = "Textbox",
    x = 128,
    y = 16,
    w = 96,
    h = 20,
    caption = "Only letters",
    validator = function(text) return text:match("^[a-zA-Z]+$") end,
  },
  {
    name = "txt2",
    type = "Textbox",
    x = 128,
    y = 38,
    w = 96,
    h = 20,
    caption = "Only digits",
    validator = function(text) return text:match("^%d+$") end,
  }
))



------------------------------------
-------- Main functions ------------
------------------------------------


-- This will be run on every update loop of the GUI script; anything you would put
-- inside a reaper.defer() loop should go here. (The function name doesn't matter)
local function Main()

  -- Prevent the user from resizing the window
  if window.state.resized then
    -- If the window's size has been changed, reopen it
    -- at the current position with the size we specified
    window:reopen({w = window.w, h = window.h})
  end

end

-- Open the script window and initialize a few things
window:open()

-- Tell the GUI library to run Main on each update loop
-- Individual elements are updated first, then GUI.func is run, then the GUI is redrawn
GUI.func = Main

-- How often (in seconds) to run GUI.func. 0 = every loop.
GUI.funcTime = 0

-- Start the main loop
GUI.Main()
