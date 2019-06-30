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

local fadeElm, fadeLayer
local function fade_lbl()

  if fadeElm.layer then
    fadeElm:fade(1, nil, 6)
  else
    fadeElm:fade(1, fadeLayer, -6)
  end

end



-- Returns a list of every element in the specified z-layer and
-- a second list of each element's values
local function getValuesForLayer(layerNum)

  -- The '+ 2' here is just to translate from a tab number to its' associated
  -- layer, since this script has few enough elements that there's only one
  -- layer per tab. More complicated scripts would have to actually access the
  -- Tabs element's layer list and iterate over the table's contents directly

  local layer = layers[layerNum + 2]

  local values = {}
  local val

  for key, elm in pairs(layer.elements) do

    if elm.val then
      val = elm:val()
    else
      val = "n/a"
    end

    values[#values + 1] = key .. ": " .. tostring(val)
  end

  return layer.name .. ":\n" .. table.concat(values, "\n")
end


local function btnClick()
  local tab = GUI.findElementByName("tabs"):val()

  local msg = getValuesForLayer(tab)
  reaper.ShowMessageBox(msg, "Yay!", 0)
end




------------------------------------
-------- Window settings -----------
------------------------------------


local window = GUI.createWindow({
  name = "General Demonstration",
  x = 0,
  y = 0,
  w = 432,
  h = 500,
  anchor = "mouse",
  corner = "C",
})

layers = table.pack( GUI.createLayers(
  {name = "Layer1", z = 1},
  {name = "Layer2", z = 2},
  {name = "Layer3", z = 3},
  {name = "Layer4", z = 4},
  {name = "Layer5", z = 5}
))

window:addLayers(table.unpack(layers))




------------------------------------
-------- Global elements -----------
------------------------------------


layers[1]:addElements( GUI.createElements(
  {
    name = "tabs",
    type = "Tabs",
    x = 0,
    y = 0,
    w = 64,
    h = 20,
    tabs = {
      {
        label = "Stuff",
        layers = {layers[3]}
      },
      {
        label = "Sliders",
        layers = {layers[4]}
      },
      {
        label = "Options",
        layers = {layers[5]}
      }
    },
    pad = 16
  },
  {
    name = "my_btn",
    type = "Button",
    x = 168,
    y = 28,
    w = 96,
    h = 20,
    caption = "Go!",
    func = btnClick
  },
  {
    name = "btn_frm",
    type = "Frame",
    x = 0,
    y = 56,
    w = window.w,
    h = 1,
  }
))

layers[2]:addElements( GUI.createElement(
  {
    name = "tab_bg",
    type = "Frame",
    x = 0,
    y = 0,
    w = 448,
    h = 20,
  }
))



------------------------------------
-------- Tab 1 Elements ------------
------------------------------------

layers[3]:addElements( GUI.createElements(
  {
    name = "my_lbl",
    type = "Label",
    x = 256,
    y = 96,
    caption = "Label!"
  },
  {
    name = "my_knob",
    type = "Knob",
    x = 64,
    y = 112,
    w = 48,
    caption = "Volume",
    vals = false,
  },
  {
    name = "my_mnu",
    type = "Menubox",
    x = 256,
    y = 176,
    w = 64,
    h = 20,
    caption = "Options:",
    options = {"1","2","3","4","5","6.12435213613"}
  },
  {
    name = "my_btn2",
    type = "Button",
    x = 256,
    y = 256,
    w = 64,
    h = 20,
    caption = "Click me!",
    func = fade_lbl,
  },
  {
    name = "my_txt",
    type = "Textbox",
    x = 96,
    y = 224,
    w = 96,
    h = 20,
    caption = "Text:",
  },
  {
    name = "my_frm",
    type = "Frame",
    x = 16,
    y = 288,
    w = 192,
    h = 128,
    bg = "elmBg",
    text = "this is a really long string of text with no carriage returns so hopefully "..
            "it will be wrapped correctly to fit inside this frame"
  },
  {
    name = "my_picker",
    type = "ColorPicker",
    x = 320,
    y = 300,
    w = 24,
    h = 24,
    caption = "Click me too! ->",
  }
))

fadeElm = GUI.findElementByName("my_lbl")
fadeLayer = fadeElm.layer

-- We have too many values to be legible if we draw them all; we'll disable them, and
-- have the knob's caption update itself to show the value instead.
local my_knob = GUI.findElementByName("my_knob")
function my_knob:redraw()

    getmetatable(self).redraw(self)
    self.caption = self.retval .. "dB"

end

-- Make sure it shows the value right away
my_knob:redraw()




------------------------------------
-------- Tab 2 Elements ------------
------------------------------------

layers[4]:addElements( GUI.createElements(
  {
    name = "my_rng",
    type = "Slider",
    x = 32,
    y = 128,
    w = 256,
    caption = "Sliders",
    min = 0,
    max = 30,
    defaults = {5, 10, 15, 20, 25}
  },
  {
    name = "my_pan",
    type = "Slider",
    x = 32,
    y = 192,
    w = 256,
    caption = "Pan",
    min = -100,
    max = 100,
    defaults = 100,
    -- Using a function to change the value label depending on the value
    output = function(val)
      val = tonumber(val)

      return (val == 0)
        and "0"
        or  (math.abs(val) .. (val < 0 and "L" or "R"))
    end
  },
  {
    name = "my_sldr",
    type = "Slider",
    x = 128,
    y = 256,
    w = 128,
    caption = "Slider",
    min = 0,
    max = 10,
    defaults = 20, 0.25,
    horizontal = false,
    output = "Value: %val%",
  },
  {
    name = "my_rng2",
    type = "Slider",
    x = 352,
    y = 96,
    w = 256,
    caption = "Vertical?",
    min = 0,
    max = 30,
    defaults = {5, 10, 15, 20, 25},
    horizontal = false,
  }
))



------------------------------------
-------- Tab 3 Elements ------------
------------------------------------


layers[5]:addElements( GUI.createElements(
  {
    name = "my_chk",
    type = "Checklist",
    x = 32,
    y = 96,
    w = 160,
    h = 160,
    caption = "Checklist:",
    options = {"Alice","Bob","Charlie","Denise","Edward","Francine"},
    dir = "v"
  },
  {
    name = "my_opt",
    type = "Radio",
    x = 200,
    y = 96,
    w = 160,
    h = 160,
    caption = "Options:",
    options = {"Apples","Bananas","_","Donuts","Eggplant"},
    dir = "v",
    swap = true,
    tooltip = "Well hey there!"
  },
  {
    name = "my_chk2",
    type = "Checklist",
    x = 32,
    y = 280,
    w = 384,
    h = 64,
    caption = "Whoa, another Checklist",
    options = {"A","B","C","_","E","F","G","_","I","J","K"},
    horizontal = true,
    swap = true
  },
  {
    name = "my_opt2",
    type = "Radio",
    x = 32,
    y = 364,
    w = 384,
    h = 64,
    caption = "Horizontal options",
    options = {"A","A#","B","C","C#","D","D#","E","F","F#","G","G#"},
    horizontal = true,
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
GUI.Init()
window:open()

-- Tell the GUI library to run Main on each update loop
-- Individual elements are updated first, then GUI.func is run, then the GUI is redrawn
GUI.func = Main

-- How often (in seconds) to run GUI.func. 0 = every loop.
GUI.funcTime = 0

-- Start the main loop
GUI.Main()
