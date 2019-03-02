-- NoIndex: true

--[[
	Lokasenna_GUI example

	- Getting user input before running an action; i.e. replacing GetUserInputs

]]--

-- The Core library must be loaded prior to anything else

local lib_path = reaper.GetExtState("Scythe", "lib_path_v3")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Set Scythe v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
local Scythe = loadfile(lib_path .. "scythe.lua")()
local GUI = require("gui.core")(Scythe)

-- GUI.req("gui/elements/Class - Slider.lua")()
-- GUI.req("gui/elements/Class - Button.lua")()
-- GUI.req("gui/elements/Class - Menubox.lua")()
-- GUI.req("gui/elements/Class - Options.lua")()

-- If any of the requested libraries weren't found, abort the script nicely.
if missing_lib then return 0 end


local Table = require("public.table")

------------------------------------
-------- Functions  ----------------
------------------------------------


local function btn_click()

	-- Grab all of the user's settings into local variables,
	-- just to make it less awkward to work with
	local mode, thresh = GUI.Val("mnu_mode"), GUI.Val("sldr_thresh")
	local opts = GUI.Val("chk_opts")
	local time_sel, sel_track, glue = opts[1], opts[2], opts[3]

	-- Be nice, give the user an Undo point
	reaper.Undo_BeginBlock()

	reaper.ShowMessageBox(
		"This is where we pretend to perform some sort of fancy operation with the user's settings.\n\n"
		.."Working in "..tostring(GUI.Layers["Layer1"].elements["mnu_mode"].options[mode])
		.." mode with a threshold of "..tostring(thresh).."db.\n\n"
		.."Apply only to time selection: "..tostring(time_sel).."\n"
		.."Apply only to selected track: "..tostring(sel_track).."\n"
		.."Glue the processed items together afterward: "..tostring(glue)
	, "Yay!", 0)


	reaper.Undo_EndBlock("Typical script options", 0)

	-- Exit the script on the next update
	GUI.quit = true

end




------------------------------------
-------- Window settings -----------
------------------------------------


GUI.name = "Example - Typical script options"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 400, 200
GUI.anchor, GUI.corner = "mouse", "C"




------------------------------------
-------- GUI Elements --------------
------------------------------------


--[[

	Button		z, 	x, 	y, 	w, 	h, caption, func[, ...]
	Checklist	z, 	x, 	y, 	w, 	h, caption, opts[, dir, pad]
	Menubox		z, 	x, 	y, 	w, 	h, caption, opts, pad, noarrow]
	Slider		z, 	x, 	y, 	w, 	caption, min, max, defaults[, inc, dir]

]]--



-- reaper.ShowConsoleMsg( Table.stringify(elements) )

local layer = GUI.createLayer("Layer1", 1)

layer:add(
  GUI.createElement({
    name = "mnu_mode",
    type =	"Menubox",
    x = 64,
    y = 32,
    w = 72,
    h = 20,
    caption = "Mode:",
    options = {"Auto","Punch","Step"}
  }),
  GUI.createElement({
    name = "chk_opts",
    type =	"Checklist",
    x = 192,
    y = 32,
    w = 192,
    h = 96,
    caption = "Options",
    options = {"Only in time selection", "Only on selected track", "Glue items when finished"},
    dir = "v",
    pad = 4
  }),
  GUI.createElement({
    name = "sldr_thresh",
    type = "Slider",
    x = 32,
    y = 96,
    w = 128,
    caption = "Threshold",
    min = -60,
    max = 0,
    defaults = 48,
    inc = nil,
    dir = "h"
  }),
  GUI.createElement({
    name = "btn_go",
    type =	"Button",
    x = 168,
    y = 152,
    w = 64,
    h = 24,
    caption = "Go!",
    func = btn_click
  })
)

GUI.Init()
GUI.Main()
