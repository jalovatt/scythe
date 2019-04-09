-- NoIndex: true

local Scythe

-- luacheck: globals GUI
GUI = {}

local Table, T = require("public.table"):unpack()
local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local Layer = require("gui.layer")
local Window = require("gui.window")

-- ReaPack version info
GUI.get_script_version = function()

  local package = reaper.ReaPack_GetOwner(({reaper.get_action_context()})[2])
  if not package then return "(version error)" end

  --ret, repo, cat, pkg, desc, type, ver, author, pinned, fileCount = reaper.ReaPack_GetEntryInfo( entry )
  local package_info = {reaper.ReaPack_GetEntryInfo(package)}

  reaper.ReaPack_FreeEntry(package)
  return package_info[7]

end
GUI.script_version = GUI.get_script_version()



------------------------------------
-------- Error handling ------------
------------------------------------


-- A basic crash handler, just to add some helpful detail
-- to the Reaper error message.
GUI.crash = function (errObject, skipMsg)

    if GUI.oncrash then GUI.oncrash() end

    local by_line = "([^\r\n]*)\r?\n?"
    local trim_path = "[\\/]([^\\/]-:%d+:.+)$"
    local err = errObject   and string.match(errObject, trim_path)
                            or  "Couldn't get error message."

    local trace = debug.traceback()
    local stack = {}
    for line in string.gmatch(trace, by_line) do

        local str = string.match(line, trim_path) or line

        stack[#stack + 1] = str
    end

    local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)$")

    local ret = skipMsg
      and 6
      or reaper.ShowMessageBox(
        name.." has crashed!\n\n"..
        "Would you like to have a crash report printed "..
        "to the Reaper console?",
        "Oops",
        4
      )

    if ret == 6 then
      reaper.ShowConsoleMsg(
        "Error: "..err.."\n\n"..
        (GUI.error_message and tostring(GUI.error_message).."\n\n" or "") ..
        "Stack traceback:\n\t"..table.concat(stack, "\n\t", 2).."\n\n"..
        "Scythe:\t".. Scythe.version.."\n"..
        "Reaper:       \t"..reaper.GetAppVersion().."\n"..
        "Platform:     \t"..reaper.GetOS()
      )
    end

    GUI.quit = true
    gfx.quit()
end

-- Checks for Reaper's "restricted permissions" script mode
-- GUI.script_restricted will be true if restrictions are in place
-- Call GUI.error_restricted to display an error message about restricted permissions
-- and exit the script.
if not os then

    GUI.script_restricted = true

    GUI.error_restricted = function()

        -- luacheck: push ignore 631
        reaper.MB(  "This script tried to access a function that isn't available in Reaper's 'restricted permissions' mode." ..
                    "\n\nThe script was NOT necessarily doing something malicious - restricted scripts are unable " ..
                    "to execute many system-level tasks such as reading and writing files." ..
                    "\n\nPlease let the script's author know, or consider running the script without restrictions if you feel comfortable.",
                    "Script Error", 0)
        -- luacheck: pop

        GUI.quit = true
        GUI.error_message = "(Restricted permissions error)"

        return nil, "Error: Restricted permissions"

    end

    os = setmetatable({}, { __index = GUI.error_restricted }) -- luacheck: ignore 121
    io = setmetatable({}, { __index = GUI.error_restricted }) -- luacheck: ignore 121

end


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

    end, GUI.crash)
end

-- GUI.update_z_max = function ()
--   local maxes = {}

--   GUI.z_max = math.max(table.unpack(maxes))
-- end

GUI.update_windows = function()
  for _, window in pairs(GUI.Windows) do
    window:update()
  end
end

GUI.Main = function ()
    xpcall( function ()

        -- if GUI.Main_Update_State() == 0 then return end
        -- GUI.update_z_max()
        GUI.update_windows()

        if GUI.quit then return end

        -- GUI.Main_Update_Elms()

        -- If the user gave us a function to run, check to see if it needs to be
        -- run again, and do so.
        if GUI.func then

            local new_time = reaper.time_precise()
            if new_time - GUI.last_time >= (GUI.freq or 1) then
                GUI.func()
                GUI.last_time = new_time
            end
        end

        -- GUI.sortedLayers = GUI.Layers:sortHashesByKey("z")

        GUI.Main_Draw()

        reaper.defer(GUI.Main)

    end, GUI.crash)
end

GUI.Main_Draw = function ()
    for _, window in pairs(GUI.Windows) do
      window:redraw()
    end
end

-- Display the GUI version number
-- Set GUI.version = 0 to hide this
GUI.Draw_Version = function ()

    if not Scythe.version then return 0 end

    local str = "Scythe "..Scythe.version

    Font.set("version")
    Color.set("txt")

    local str_w, str_h = gfx.measurestr(str)

    --gfx.x = GUI.w - str_w - 4
    --gfx.y = GUI.h - str_h - 4
    gfx.x = gfx.w - str_w - 6
    gfx.y = gfx.h - str_h - 4

    gfx.drawstr(str)

end

-- Draws a grid overlay and some developer hints
-- Toggled via Ctrl+Shift+Alt+Z, or by setting GUI.dev_mode = true
GUI.Draw_Dev = function ()

    -- Draw a grid for placing elements
    Color.set("magenta")
    gfx.setfont("Courier New", 10)

    for i = 0, GUI.w, GUI.dev.grid_b do

        local a = (i == 0) or (i % GUI.dev.grid_a == 0)
        gfx.a = a and 1 or 0.3
        gfx.line(i, 0, i, GUI.h)
        gfx.line(0, i, GUI.w, i)
        if a then
            gfx.x, gfx.y = i + 4, 4
            gfx.drawstr(i)
            gfx.x, gfx.y = 4, i + 4
            gfx.drawstr(i)
        end

    end

    local str = "Mouse: "..
      math.modf(GUI.mouse.x)..", "..
      math.modf(GUI.mouse.y).." "

    local str_w, str_h = gfx.measurestr(str)
    gfx.x, gfx.y = GUI.w - str_w - 2, GUI.h - 2*str_h - 2

    Color.set("black")
    gfx.rect(gfx.x - 2, gfx.y - 2, str_w + 4, 2*str_h + 4, true)

    Color.set("white")
    gfx.drawstr(str)

    local snap_x, snap_y = Math.nearestmultiple(GUI.mouse.x, GUI.dev.grid_b),
                            Math.nearestmultiple(GUI.mouse.y, GUI.dev.grid_b)

    gfx.x, gfx.y = GUI.w - str_w - 2, GUI.h - str_h - 2
    gfx.drawstr(" Snap: "..snap_x..", "..snap_y)

    gfx.a = 1

    GUI.redraw_z[0] = true

end


------------------------------------
-------- Element functions ---------
------------------------------------

GUI.addElementClass = function(type)
  local class = require("gui.elements."..type)

  if not class then
    reaper.ShowMessageBox("Couldn't load element class: " .. type, "Oops", 4)
    return nil
  end

  GUI.elementClasses[type] = class
  return class
end

GUI.createElement = function (props)
  local class = GUI.elementClasses[props.type]
             or GUI.addElementClass(props.type)

  if not class then return nil end

  local elm = class:new(props)

  -- If we're overwriting a previous elm, make sure it frees its buffers, etc
  -- if GUI.Elements[props.name] then GUI.Elements[props.name]:delete() end

  -- GUI.Elements[props.name] = elm

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
-------- Developer stuff -----------
------------------------------------


-- Print a string to the Reaper console.
GUI.Msg = function (...)
    local out = Table.map({...},
      function (str) return tostring(str) end
    )
    reaper.ShowConsoleMsg(out:concat(", ").."\n")
end

-- Developer mode settings
GUI.dev = {

    -- grid_a must be a multiple of grid_b, or it will
    -- probably never be drawn
    grid_a = 128,
    grid_b = 16

}


--[[
    How fast the caret in textboxes should blink, measured in GUI update loops.

    '16' looks like a fairly typical textbox caret.

    Because each On and Off redraws the textbox's Z layer, this can cause CPU
    issues in scripts with lots of drawing to do. In that case, raising it to
    24 or 32 will still look alright but require less redrawing.
]]--
GUI.txt_blink_rate = 16


-- Delay time when hovering over an element before displaying a tooltip
GUI.tooltip_time = 0.8


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


-- Saves the current script window parameters to an ExtState under the given section name
-- Returns dock, x, y, w, h
GUI.save_window_state = function (name, title)

    if not name then return end
    local state = {gfx.dock(-1, 0, 0, 0, 0)}
    reaper.SetExtState(name, title or "window", table.concat(state, ","), true)

    return table.unpack(state)

end


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




------------------------------------
-------- Reaper functions ----------
------------------------------------





-- Also might need to know this
GUI.SWS_exists = reaper.APIExists("CF_GetClipboardBig")



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





------------------------------------
-------- Misc. functions -----------
------------------------------------


-- Why does Lua not have an operator for this?
GUI.xor = function(a, b)

    return (a or b) and not (a and b)

end


-- Display a tooltip
GUI.settooltip = function(str)

    if not str or str == "" then return end

    --Lua: reaper.TrackCtl_SetToolTip(string fmt, integer xpos, integer ypos, boolean topmost)
    --displays tooltip at location, or removes if empty string
    local x, y = gfx.clienttoscreen(0, 0)

    reaper.TrackCtl_SetToolTip(
      str,
      x + GUI.mouse.x + 16,
      y + GUI.mouse.y + 16,
      true
    )
    GUI.tooltip = str


end


-- Clear the tooltip
GUI.cleartooltip = function()

    reaper.TrackCtl_SetToolTip("", 0, 0, true)
    GUI.tooltip = nil

end

-- THIS NEEDS TO BE MOVED TO THE ELEMENT OR LAYER MODULES SOMEHOW
-- Tab forward (or backward, if Shift is down) to the next element with .tab_idx = number.
-- Removes focus from the given element, and gives it to the new element.
function GUI.tab_to_next(elm)

    if not elm.tab_idx then return end

    local inc = (GUI.mouse.cap & 8 == 8) and -1 or 1

    -- Get a list of all tab_idx elements, and a list of tab_idxs
    local indices, elms = {}, {}
    for _, element in pairs(GUI.elms) do
        if element.tab_idx then
            elms[element.tab_idx] = element
            indices[#indices+1] = element.tab_idx
        end
    end

    -- This is the only element with a tab index
    if #indices == 1 then return end

    -- Find the next element in the appropriate direction
    table.sort(indices)

    local new
    local cur = Table.find(indices, elm.tab_idx)

    if cur == 1 and inc == -1 then
        new = #indices
    elseif cur == #indices and inc == 1 then
        new = 1
    else
        new = cur + inc
    end

    -- Move the focus
    elm.focus = false
    elm:lostfocus()
    elm:redraw()

    -- Can't set focus until the next GUI loop or Update will have problems
    GUI.newfocus = elms[indices[new]]
    elms[indices[new]]:redraw()

end

return function (scythe)
  Scythe = scythe

  return GUI
end
