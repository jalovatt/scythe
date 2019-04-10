-- NoIndex: true

--[[
    Lokasenna_GUI example

    - General demonstration
  - Tabs and layer sets
    - Subwindows
  - Accessing elements' parameters

]]--

-- The Core library must be loaded prior to anything else

local lib_path = reaper.GetExtState("Scythe", "lib_path_v3")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Set Scythe v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
-- local Scythe = loadfile(lib_path .. "scythe.lua")()
loadfile(lib_path .. "scythe.lua")()
local GUI = require("gui.core")

local Table, T = require("public.table"):unpack()

------------------------------------
-------- Functions -----------------
------------------------------------
local layers


local fade_elm, fade_layer
local function fade_lbl()

  if fade_elm.layer then
    fade_elm:fade(1, nil, 6)
  else
    fade_elm:fade(1, fade_layer, -6)
  end

end



-- Returns a list of every element on the specified z-layer and
-- a second list of each element's values
local function get_values_for_tab(tab_num)

  -- The '+ 2' here is just to translate from a tab number to its'
  -- associated z layer. More complicated scripts would have to
  -- actually access GUI.elms.tabs.z_sets[tab_num] and iterate over
  -- the table's contents (see the call to GUI.elms.tabs:update_sets
  -- below)

  local layer = layers[tab_num + 2]

  local values = {}
  for key, elm in pairs(layer.elements) do

    local val
    if elm.val then
      val = elm:val()
    else
      val = "n/a"
    end
    values[#values + 1] = key .. ": " .. tostring(val)
  end

  return layer.name .. ":\n" .. table.concat(values, "\n")

end


local function btn_click()

    -- Open the Window element
    -- Disabled until Window can be rewritten
  -- GUI.elms.wnd_test:open()
  local tab_num = GUI.findElementByName("tabs"):val()

  local msg = get_values_for_tab(tab_num)
  reaper.ShowMessageBox(msg, "Yay!", 0)

end


-- local function wnd_OK()

--     -- Close the Window element
--     GUI.elms.wnd_test:close()

-- end


------------------------------------
-------- Window settings -----------
------------------------------------


-- GUI.name = "New Window"
-- GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 432, 500
-- GUI.anchor, GUI.corner = "mouse", "C"

local window = GUI.createWindow({
  name = "General Demonstration",
  x = 0,
  y = 0,
  w = 432,
  h = 500,
  anchor = "mouse",
  corner = "C",
  onClose = function() GUI.quit = true end,
})

layers = table.pack( GUI.createLayers(
  {name = "Layer1", z = 1},
  {name = "Layer2", z = 2},
  {name = "Layer3", z = 3},
  {name = "Layer4", z = 4},
  {name = "Layer5", z = 5}
))

window:addLayers(table.unpack(layers))

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
    func = btn_click
  },
  {
    name = "btn_frm",
    type = "Frame",
    x = 0,
    y = 56,
    w = GUI.w,
    h = 4,
  }
))

layers[2]:addElements( GUI.createElement(
  {
    name = "tab_bg",
    type = "Frame",
    x = 0,
    y = 0,
    w = 448,
    h = 20, -- false, true, "elm_bg", 0)
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
    func = fade_lbl
  },
  {
    name = "my_txt",
    type = "Textbox",
    x = 96,
    y = 224,
    w = 96,
    h = 20,
    caption = "Text:"
  },
  {
    name = "my_frm",
    type = "Frame",
    x = 16,
    y = 288,
    w = 192,
    h = 128,
    bg = "elm_bg",
    text = "this is a really long string of text with no carriage returns so hopefully "..
            "it will be wrapped correctly to fit inside this frame"
  }
))

fade_elm = GUI.findElementByName("my_lbl")
fade_layer = fade_elm.layer

-- We have too many values to be legible if we draw them all; we'll disable them, and
-- have the knob's caption update itself to show the value instead.
local my_knob = GUI.findElementByName("my_knob")
-- my_knob.vals = false
function my_knob:redraw()

    self.prototype.redraw(self)

    self.caption = self.retval .. "dB"

end

-- Make sure it shows the value right away
my_knob:redraw()

-- local my_frm = GUI.findElementByName("my_frm")
-- my_frm:val( "this is a really long string of text with no carriage returns so hopefully "..
--             "it will be wrapped correctly to fit inside this frame"
--           )
-- my_frm.bg = "elm_bg"


-- ------------------------------------
-- -------- Tab 2 Elements ------------
-- ------------------------------------

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
    dir = "v"
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
    dir = "v"
  }
))



-- ------------------------------------
-- -------- Tab 3 Elements ------------
-- ------------------------------------

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
    dir = "h",
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
    dir = "h"
  }
))

-- ------------------------------------
-- -------- Subwindow and -------------
-- -------- its elements  -------------
-- ------------------------------------


-- GUI.New("wnd_test", "Window", 10, 0, 0, 312, 244, "Dialog Box", {9, 10})
-- GUI.New("lbl_elms", "Label", 9, 16, 16, "", false, 4)
-- GUI.New("lbl_vals", "Label", 9, 96, 16, "", false, 4, nil, elm_bg)
-- GUI.New("btn_close", "Button", 9, 0, 184, 48, 24, "OK", wnd_OK)

-- -- We want these elements out of the way until the window is opened
-- GUI.elms_hide[9] = true
-- GUI.elms_hide[10] = true


-- :onopen is a hook provided by the Window class. This function will be run
-- every time the window opens.
-- function GUI.elms.wnd_test:onopen()

--     -- :adjustelm places the element's specified x,y coordinates relative to
--     -- the Window. i.e. creating an element at 0,0 and adjusting it will put
--     -- the element in the Window's top-left corner.
--     self:adjustelm(GUI.elms.btn_close)

--     -- Buttons look nice when they're centered.
--     GUI.elms.btn_close.x, _ = GUI.center(GUI.elms.btn_close, self)

--     self:adjustelm(GUI.elms.lbl_elms)
--     self:adjustelm(GUI.elms.lbl_vals)

--     -- Set the Window's title
--  local tab_num = GUI.Val("tabs")
--     self.caption = "Element values for Tab " .. tab_num

--     -- This Window provides a readout of the values for every element
--     -- on the current tab.
--     local strs_v, strs_val = get_values_for_tab(tab_num)

--     GUI.Val("lbl_elms", table.concat(strs_v, "\n"))
--     GUI.Val("lbl_vals", table.concat(strs_val, "\n"))

-- end




------------------------------------
-------- Main functions ------------
------------------------------------


-- This will be run on every update loop of the GUI script; anything you would put
-- inside a reaper.defer() loop should go here. (The function name doesn't matter)
local function Main()

  -- Prevent the user from resizing the window
  if GUI.resized then

    -- If the window's size has been changed, reopen it
    -- at the current position with the size we specified
    local _,x,y,_,_ = gfx.dock(-1,0,0,0,0)
    gfx.quit()
    gfx.init(GUI.name, GUI.w, GUI.h, 0, x, y)
    GUI.redraw_z[0] = true
  end

end

-- Open the script window and initialize a few things
GUI.Init()
window:open()

-- Tell the GUI library to run Main on each update loop
-- Individual elements are updated first, then GUI.func is run, then the GUI is redrawn
GUI.func = Main

-- How often (in seconds) to run GUI.func. 0 = every loop.
GUI.freq = 0

-- Start the main loop
GUI.Main()
