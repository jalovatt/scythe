-- NoIndex: true

--[[
	Scythe example

	- Demonstration of the Listbox, Menubar, and TextEditor classes

]]--

-- The core library must be loaded prior to anything else

local libPath = reaper.GetExtState("Scythe", "libPath_v3")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Set Scythe v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(libPath .. "scythe.lua")()
local GUI = require("gui.core")

local _, T = require("public.table"):unpack()
require("public.string")

local function preventDefault(self, state) state.preventDefault = true end

------------------------------------
-------- Menu functions ------------
------------------------------------


local mnu_file = {
  new = function() GUI.Val("txted_text", "file: new") end,
  open = function() GUI.Val("txted_text", "file: open") end,
  recent_blah = function() GUI.Val("txted_text", "file:\trecent files: blah.txt") end,
  recent_stuff = function() GUI.Val("txted_text", "file:\trecent files: stuff.txt") end,
  recent_readme = function() GUI.Val("txted_text", "file:\trecent files: readme.md") end,
  save = function() GUI.Val("txted_text", "file: save") end,
  save_as = function() GUI.Val("txted_text", "file: save as") end,
  print = function() GUI.Val("txted_text", "file: print") end,
  print_preview = function() GUI.Val("txted_text", "file: print preview") end,
  exit = function() GUI.quit = true end
}

local mnu_edit = {
  cut = function() GUI.Val("txted_text", "edit: cut") end,
  copy = function() GUI.Val("txted_text", "edit: copy") end,
  copy_path = function() GUI.Val("txted_text", "edit:\tcopy current path") end,
  copy_file = function() GUI.Val("txted_text", "edit:\tcopy current filename") end,
  copy_dir = function() GUI.Val("txted_text", "edit:\tcopy current directory path") end,
  paste = function() GUI.Val("txted_text", "edit: paste") end,
  delete = function() GUI.Val("txted_text", "edit: delete") end,
  select_all = function() GUI.Val("txted_text", "edit: select all") end
}

local mnu_view = {
  always_on_top = function() GUI.Val("txted_text", "view: always on top") end,
  toggle_full_screen = function() GUI.Val("txted_text", "view: toggle full-screen") end,
  hide_menu = function() GUI.Val("txted_text", "view: hide menu") end
}

local mnu_help = {
  help = function() GUI.Val("txted_text", "help: help") end,
  open_website = function() GUI.Val("txted_text", "help: open website") end,
  check_for_updates = function() GUI.Val("txted_text", "help: check for updates") end,
  about = function() GUI.Val("txted_text", "help: about") end
}

local mnu_params_func = function(label, param)
  GUI.Val("txted_text", "Parameter " .. label .. " was: " .. param)
end



------------------------------------
-------- Menu contents -------------
------------------------------------


-- This table is passed to the Menubar
-- Must be structured like this (.title, .options, etc)
local menus = {

  {title = "File", options = {
    {caption = "New",                       func = mnu_file.new},
    {caption = ""},
    {caption = "Open",                      func = mnu_file.open},
    {caption = ">Recent Files"},
      {caption = "blah.txt",                func = mnu_file.recent_blah},
      {caption = "stuff.txt",               func = mnu_file.recent_stuff},
      {caption = "<readme.md",              func = mnu_file.recent_readme},
    {caption = "Save",                      func = mnu_file.save},
    {caption = "Save As",                   func = mnu_file.save_as},
    {caption = ""},
    {caption = "#Print",                    func = mnu_file.print},
    {caption = "#Print Preview",            func = mnu_file.print_preview},
    {caption = ""},
    {caption = "Exit",                      func = mnu_file.exit}
  }},

  {title = "Edit", options = {
    {caption = "Cut",                       func = mnu_edit.cut},
    {caption = "Copy",                      func = mnu_edit.copy},
    {caption = ">Copy to Clipboard"},
      {caption = "Current full file path",  func = mnu_edit.copy_path},
      {caption = "Current filename",        func = mnu_edit.copy_file},
      {caption = "<Current directory path", func = mnu_edit.copy_dir},
    {caption = "Paste",                     func = mnu_edit.paste},
    {caption = "Delete",                    func = mnu_edit.delete},
    {caption = ""},
    {caption = "Select All",                func = mnu_edit.select_all}
  }},

  {title = "View", options = {
    {caption = "!Always On Top",            func = mnu_view.always_on_top},
    {caption = "Toggle Full-Screen",        func = mnu_view.toggle_full_screen},
    {caption = "Hide Menu",                 func = mnu_view.hide_menu}
  }},

  {title = "Help", options = {
    {caption = "Help",                      func = mnu_help.help},
    {caption = "#Open Website",             func = mnu_help.open_website},
    {caption = ""},
    {caption = "#Check For Updates",        func = mnu_help.check_for_updates},
    {caption = "About",                     func = mnu_help.about},
  }},

  {title = "Parameters", options = {
    {caption = "Parameter A",               func = mnu_params_func,    params = {"A", "hello!"}},
    {caption = "Parameter B",               func = mnu_params_func,    params = {"B", "bonjour!"}},
    {caption = "Parameter C",               func = mnu_params_func,    params = {"C", "g'day!"}},
    {caption = "Parameter D",               func = mnu_params_func,    params = {"D", "guten tag!"}},
  }},
}




------------------------------------
-------- Listbox contents ----------
------------------------------------


local titles1 = ("prevents MouseDown -- and -- MouseUp -- events"):split(" ")
local titles2 = ("prevents Wheel -- and -- Drag -- events"):split(" ")




------------------------------------
-------- Window settings -----------
------------------------------------


local window = GUI.createWindow({
  name = "PreventDefault testing",
  x = 0,
  y = 0,
  w = 800,
  h = 272,
  anchor = "mouse",
  corner = "C",
})


window:addLayers(
  GUI.createLayer({name = "Layer1", z = 1})
    :addElements(
      GUI.createElements(
        {
          name = "mnu_menu",
          type = "Menubar",
          x = 0,
          y = 0,
          w = window.currentW,
          menus = menus,
        },
        {
          name = "lst1",
          type = "Listbox",
          x = 16,
          y = 40,
          w = 300,
          h = 80,
          caption = "",
          multi = true,
          list = titles1,
          afterDoubleClick = function(self) GUI.Val("txted_text", "DoubleClicked the first Listbox at " .. reaper.time_precise()) end,
          beforeMouseDown = preventDefault,
          beforeMouseUp = preventDefault,
        },
        {
          name = "lst2",
          type = "Listbox",
          x = 16,
          y = 128,
          w = 300,
          h = 80,
          caption = "",
          multi = true,
          list = titles2,
          beforeWheel = preventDefault,
          beforeDrag = preventDefault,
        },
        {
          name = "txted_text",
          type = "TextEditor",
          x = 364,
          y = 40,
          w = 420,
          h = 208,
          retval = "Select an item\n  or two\n    or three\n      or everything in the list\n\nand click the button!",
        }
      )
    )
)


window:open()
GUI.Main()
