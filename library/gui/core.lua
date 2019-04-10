-- NoIndex: true

-- luacheck: globals Scythe
if not Scythe then
  error("Couldn't find Scythe. Please make sure the Scythe library has been loaded.")
  return
end

-- luacheck: globals GUI
local GUI = {}

local Table, T = require("public.table"):unpack()
-- local Font = require("public.font")
local Color = require("public.color")
-- local Math = require("public.math")
local Layer = require("gui.layer")
local Window = require("gui.window")
-- local Config = require("gui.config")

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
-- luacheck: globals Msg
Msg = function (...)
    local out = Table.map({...},
      function (str) return tostring(str) end
    )
    reaper.ShowConsoleMsg(out:concat(", ").."\n")
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

return GUI
