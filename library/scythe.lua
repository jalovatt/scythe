-- NoIndex: true

-- local info = debug.getinfo(1,'S');
-- local full_script_path = info.source
-- local script_path = full_script_path:sub(2,-5) -- remove "@" and "file extension" from file name
-- if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
--   package.path = package.path .. ";" .. script_path:match("(.*".."\\"..")") .. "..\\Functions\\?.lua"
-- else
--   package.path = package.path .. ";" .. script_path:match("(.*".."/"..")") .. "../Functions/?.lua"
-- end
-- require("X-Raym_Functions - console debug messages")


GUI = {}

------------------------------------
-------- Basic script info ---------
------------------------------------


GUI.script_path, GUI.script_name = ({reaper.get_action_context()})[2]:match("(.-)([^/\\]+).lua$")


GUI.lib_path = reaper.GetExtState("Scythe", "lib_path_v3")
if not GUI.lib_path or GUI.lib_path == "" then
    reaper.MB("Couldn't find the Scythe library. Please run 'Set Scythe library path' in your Action List.", "Whoops!", 0)
    return
end

package.path = package.path .. ";" .. GUI.lib_path:match("(.*".."/"..")") .. "?.lua"

local Table, T = require("public.table"):unpack()
local Layer = require("gui.layer")
local Element = require("gui.element")


GUI.get_version = function()

    local file = GUI.lib_path .. "/scythe.lua"
    if not reaper.ReaPack_GetOwner then
        return "(" .. "ReaPack not found" .. ")"
    else
        local package, err = reaper.ReaPack_GetOwner(file)
        if not package or package == "" then
            return "(" .. tostring(err) .. ")"
        else
            local ret, repo, cat, pkg, desc, type, ver, author, pinned, fileCount = reaper.ReaPack_GetEntryInfo(package)
            if ret then
                return "v" .. tostring(ver)
            else
                return "(version error)"
            end
        end
    end

end
GUI.version = GUI.get_version()


-- ReaPack version info
GUI.get_script_version = function()

  local package, err = reaper.ReaPack_GetOwner(({reaper.get_action_context()})[2])
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

    local ret = skipMsg and 6 or reaper.ShowMessageBox(name.." has crashed!\n\n"..
                                "Would you like to have a crash report printed "..
                                "to the Reaper console?",
                                "Oops", 4)

    if ret == 6 then
        reaper.ShowConsoleMsg(  "Error: "..err.."\n\n"..
                                (GUI.error_message and tostring(GUI.error_message).."\n\n" or "") ..
                                "Stack traceback:\n\t"..table.concat(stack, "\n\t", 2).."\n\n"..
                                "Scythe:\t".. GUI.version.."\n"..
                                "Reaper:       \t"..reaper.GetAppVersion().."\n"..
                                "Platform:     \t"..reaper.GetOS())
    end

    GUI.quit = true
    gfx.quit()
end




------------------------------------
-------- Module loading ------------
------------------------------------


-- I hate working with 'requires', so I've opted to do it this way.
-- This also works much more easily with my Script Compiler.
GUI.req = function(file)

    if missing_lib then return function () end end

    local file_path = ( (file:sub(2, 2) == ":" or file:sub(1, 1) == "/") and ""
                                                                          or  GUI.lib_path )
                        .. file

    local ret, err = loadfile(file_path)
    if not ret then
        local ret = reaper.ShowMessageBox(  "Couldn't load " .. file ..
                                "\n\n" ..
                                "Error message:\n" .. tostring(err) ..
                                "\n\n" ..
                                "Please make sure you have the newest version of Lokasenna_GUI. " ..
                                "If you're using ReaPack, select Extensions -> ReaPack -> Synchronize Packages. " ..
                                "\n\n" ..
                                "If this error persists, contact the script author." ..
                                "\n\n" ..
                                "Would you like to have a crash report printed "..
                                "to the Reaper console?"
                                , "Library error", 4
                            )
        GUI.error_message = tostring(err)
        if ret == 6 then GUI.crash(nil, true) end
        missing_lib = true
        return function () end

    else
        return ret
    end

end




------------------------------------
-------- Main functions ------------
------------------------------------

GUI.Layers = {}
GUI.Elements = {}

-- Loaded classes
GUI.elementClasses = {}

-- Returns a dense array of layers sorted in ascending z-order
GUI.sortLayers = function (layers)
    local sorted = T{}

    for _, layer in pairs(GUI.Layers) do
      sorted[#sorted + 1] = layer
    end

    sorted:sort( function(a, b) return a.z < b.z end )

    return sorted
end

GUI.Init = function ()
    xpcall( function()


        -- Create the window
        gfx.clear = reaper.ColorToNative(table.unpack(GUI.colors.wnd_bg))

        if not GUI.x then GUI.x = 0 end
        if not GUI.y then GUI.y = 0 end
        if not GUI.w then GUI.w = 640 end
        if not GUI.h then GUI.h = 480 end

        if GUI.anchor and GUI.corner then
            GUI.x, GUI.y = GUI.get_window_pos(  GUI.x, GUI.y, GUI.w, GUI.h,
                                                GUI.anchor, GUI.corner)
        end

        gfx.init(GUI.name, GUI.w, GUI.h, GUI.dock or 0, GUI.x, GUI.y)


        GUI.cur_w, GUI.cur_h = gfx.w, gfx.h

        -- Measure the window's title bar, in case we need it
        local __, __, wnd_y, __, __ = gfx.dock(-1, 0, 0, 0, 0)
        local __, gui_y = gfx.clienttoscreen(0, 0)
        GUI.title_height = gui_y - wnd_y


        -- Initialize a few values
        GUI.last_time = 0
        GUI.mouse = {

            x = 0,
            y = 0,
            cap = 0,
            down = false,
            wheel = 0,
            lwheel = 0

        }

        -- Store which element the mouse was clicked on.
        -- This is essential for allowing drag behaviour where dragging affects
        -- the element position.
        GUI.mouse_down_elm = nil
        GUI.rmouse_down_elm = nil
        GUI.mmouse_down_elm = nil


        -- Convert color presets from 0..255 to 0..1
        for i, col in pairs(GUI.colors) do
            col[1], col[2], col[3], col[4] =    col[1] / 255, col[2] / 255,
                                                col[3] / 255, col[4] / 255
        end

        if GUI.exit then reaper.atexit(GUI.exit) end

        GUI.gfx_open = true

        GUI.sortedLayers = GUI.sortLayers(GUI.Layers)
        for _, layer in pairs(GUI.Layers) do
          layer:init()
        end

    end, GUI.crash)
end

GUI.Main = function ()
    xpcall( function ()

        if GUI.Main_Update_State() == 0 then return end

        GUI.Main_Update_Elms()

        -- If the user gave us a function to run, check to see if it needs to be
        -- run again, and do so.
        if GUI.func then

            local new_time = reaper.time_precise()
            if new_time - GUI.last_time >= (GUI.freq or 1) then
                GUI.func()
                GUI.last_time = new_time

            end
        end


        -- Maintain a list of elms and zs in case any have been moved or deleted
        GUI.sortedLayers = GUI.sortLayers(GUI.Layers)

        GUI.Main_Draw()

    end, GUI.crash)
end


GUI.Main_Update_State = function()

    -- Update mouse and keyboard state, window dimensions
    if GUI.mouse.x ~= gfx.mouse_x or GUI.mouse.y ~= gfx.mouse_y then

        GUI.mouse.lx, GUI.mouse.ly = GUI.mouse.x, GUI.mouse.y
        GUI.mouse.x, GUI.mouse.y = gfx.mouse_x, gfx.mouse_y

        -- Hook for user code
        if GUI.onmousemove then GUI.onmousemove() end

    else

        GUI.mouse.lx, GUI.mouse.ly = GUI.mouse.x, GUI.mouse.y

    end
    GUI.mouse.wheel = gfx.mouse_wheel
    GUI.mouse.cap = gfx.mouse_cap
    GUI.char = gfx.getchar()

    if GUI.cur_w ~= gfx.w or GUI.cur_h ~= gfx.h then
        GUI.cur_w, GUI.cur_h = gfx.w, gfx.h

        GUI.resized = true

        -- Hook for user code
        if GUI.onresize then GUI.onresize() end

    else
        GUI.resized = false
    end

    --	(Escape key)	(Window closed)		(User function says to close)
    --if GUI.char == 27 or GUI.char == -1 or GUI.quit == true then
    if (GUI.char == 27 and not (	GUI.mouse.cap & 4 == 4
                                or 	GUI.mouse.cap & 8 == 8
                                or 	GUI.mouse.cap & 16 == 16
                                or  GUI.escape_bypass))
            or GUI.char == -1
            or GUI.quit == true then

        GUI.cleartooltip()
        return 0
    else
        if GUI.char == 27 and GUI.escape_bypass then GUI.escape_bypass = "close" end
        reaper.defer(GUI.Main)
    end

end


--[[
    Update each element's state, starting from the top down.

    This is very important, so that lower elements don't
    "steal" the mouse.


    This function will also delete any elements that have their z set to -1

    Handy for something like Label:fade if you just want to remove
    the faded element entirely

    ***Don't try to remove elements in the middle of the Update
    loop; use this instead to have them automatically cleaned up***

]]--
GUI.Main_Update_Elms = function ()

    -- Disabled May 2/2018 to see if it was actually necessary
    -- GUI.update_elms_list()

    -- We'll use this to shorten each elm's update loop if the user did something
    -- Slightly more efficient, and averts any bugs from false positives
    GUI.elm_updated = false

    -- Check for the dev mode toggle before we get too excited about updating elms
    if  GUI.char == 282         and GUI.mouse.cap & 4 ~= 0
    and GUI.mouse.cap & 8 ~= 0  and GUI.mouse.cap & 16 ~= 0 then

        GUI.dev_mode = not GUI.dev_mode
        GUI.elm_updated = true
        GUI.redraw_z[0] = true

    end


    -- Mouse was moved? Clear the tooltip
    if GUI.tooltip and (GUI.mouse.x - GUI.mouse.lx > 0 or GUI.mouse.y - GUI.mouse.ly > 0) then

        GUI.mouseover_elm = nil
        GUI.cleartooltip()

    end


    -- Bypass for some skip logic to allow tabbing between elements (GUI.tab_to_next)
    if GUI.newfocus then
        GUI.newfocus.focus = true
        GUI.newfocus = nil
    end


    for i = 1, #GUI.sortedLayers do
      GUI.sortedLayers[i]:update(GUI)
    end

    -- Just in case any user functions want to know...
    GUI.mouse.last_down = GUI.mouse.down
    GUI.mouse.last_r_down = GUI.mouse.r_down

end


GUI.Main_Draw = function ()

    -- Redraw all of the elements, starting from the bottom up.
    local w, h = GUI.cur_w, GUI.cur_h

    local need_redraw, global_redraw
    -- if GUI.redraw_z[0] then
    --     global_redraw = true
    --     GUI.redraw_z[0] = false
    -- else
    need_redraw = Table.any(GUI.Layers, function(l) return l.needsRedraw end)

    if need_redraw or global_redraw then

        -- All of the layers will be drawn to their own buffer (dest = z), then
        -- composited in buffer 0. This allows buffer 0 to be blitted as a whole
        -- when none of the layers need to be redrawn.

        gfx.dest = 0
        gfx.setimgdim(0, -1, -1)
        gfx.setimgdim(0, w, h)

        GUI.color("wnd_bg")
        gfx.rect(0, 0, w, h, 1)

        for i = #GUI.sortedLayers, 1, -1 do
          local layer = GUI.sortedLayers[i]
            if  (layer.elementCount > 0 and not layer.hidden) then
                if global_redraw or layer.needsRedraw then
                  layer:redraw(GUI)
                end

                gfx.blit(layer.z, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
            end
        end

        -- Draw developer hints if necessary
        if GUI.dev_mode then
            GUI.Draw_Dev()
        else
            GUI.Draw_Version()
        end

    end


    -- Reset them again, to be extra sure
    gfx.mode = 0
    gfx.set(0, 0, 0, 1)

    gfx.dest = -1
    gfx.blit(0, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)

    gfx.update()

end

GUI.Draw_Z = function(z)

  -- Set this before we redraw, so that elms can call a redraw
  -- from their own :draw method. e.g. Labels fading out
  GUI.redraw_z[z] = false

  gfx.setimgdim(z, -1, -1)
  gfx.setimgdim(z, GUI.cur_w, GUI.cur_h)
  gfx.dest = z

  for __, elm in pairs(GUI.elms_list[z]) do
      if not GUI.Elements[elm] then
          reaper.MB(  "Error: Tried to update a GUI element that doesn't exist:"..
                      "\nGUI.Elements." .. tostring(elm), "Whoops!", 0)
      end

      -- Reset these just in case an element or some user code forgot to,
      -- otherwise we get things like the whole buffer being blitted with a=0.2
      gfx.mode = 0
      gfx.set(0, 0, 0, 1)

      GUI.Elements[elm]:draw()
  end

  gfx.dest = 0

end

-- Display the GUI version number
-- Set GUI.version = 0 to hide this
GUI.Draw_Version = function ()

    if not GUI.version then return 0 end

    local str = "Lokasenna_GUI "..GUI.version

    GUI.font("version")
    GUI.color("txt")

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
    GUI.color("magenta")
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

    local str = "Mouse: "..math.modf(GUI.mouse.x)..", "..math.modf(GUI.mouse.y).." "
    local str_w, str_h = gfx.measurestr(str)
    gfx.x, gfx.y = GUI.w - str_w - 2, GUI.h - 2*str_h - 2

    GUI.color("black")
    gfx.rect(gfx.x - 2, gfx.y - 2, str_w + 4, 2*str_h + 4, true)

    GUI.color("white")
    gfx.drawstr(str)

    local snap_x, snap_y = GUI.nearestmultiple(GUI.mouse.x, GUI.dev.grid_b),
                            GUI.nearestmultiple(GUI.mouse.y, GUI.dev.grid_b)

    gfx.x, gfx.y = GUI.w - str_w - 2, GUI.h - str_h - 2
    gfx.drawstr(" Snap: "..snap_x..", "..snap_y)

    gfx.a = 1

    GUI.redraw_z[0] = true

end





------------------------------------
-------- Buffer functions ----------
------------------------------------


--[[
    We'll use this to let elements have their own graphics buffers
    to do whatever they want in.

    num	=	How many buffers you want, or 1 if not specified.

    Returns a table of buffers, or just a buffer number if num = 1

    i.e.

    -- Assign this element's buffer
    function GUI.my_element:new(.......)

        ...new stuff...

        my_element.buffers = GUI.GetBuffer(4)
        -- or
        my_element.buffer = GUI.GetBuffer()

    end

    -- Draw to the buffer
    function GUI.my_element:init()

        gfx.dest = self.buffers[1]
        -- or
        gfx.dest = self.buffer
        ...draw stuff...

    end

    -- Copy from the buffer
    function GUI.my_element:draw()
        gfx.blit(self.buffers[1], 1, 0)
        -- or
        gfx.blit(self.buffer, 1, 0)
    end

]]--

-- Any used buffers will be marked as True here
GUI.buffers = {}

-- When deleting elements, their buffer numbers
-- will be added here for easy access.
GUI.freed_buffers = {}

GUI.GetBuffer = function (num)
    local ret = {}
    --local prev

    for i = 1, (num or 1) do

        if #GUI.freed_buffers > 0 then

            ret[i] = table.remove(GUI.freed_buffers)

        else
            local z_max = GUI.sortedLayers[#GUI.sortedLayers - 1].z
            for j = 1023, z_max, -1 do
            --for j = (not prev and 1023 or prev - 1), 0, -1 do

                if not GUI.buffers[j] then
                    ret[i] = j

                    GUI.buffers[j] = true
                    goto skip
                end

            end

            -- Something bad happened, probably my fault
            GUI.error_message = "Couldn't get a new graphics buffer - buffer would overlap element space. z = " .. z_max

            ::skip::
        end

    end

    return (#ret == 1) and ret[1] or ret

end

-- Elements should pass their buffer (or buffer table) to this
-- when being deleted
GUI.FreeBuffer = function (num)

    if type(num) == "number" then
        table.insert(GUI.freed_buffers, num)
    else
        for k, v in pairs(num) do
            table.insert(GUI.freed_buffers, v)
        end
    end

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
    local class = GUI.elementClasses[props.type] or GUI.addElementClass(props.type)
    if not class then return nil end

    local elm = class:new(props)

    -- If we're overwriting a previous elm, make sure it frees its buffers, etc
    if GUI.Elements[props.name] then GUI.Elements[props.name]:delete() end

    GUI.Elements[props.name] = elm

    if GUI.gfx_open then elm:init() end

    return elm
end


GUI.createLayer = function (name, z)
  local layer = Layer:new(name, z)
  GUI.Layers[name] = layer

  return layer
end


GUI.findElementByName = function (name, layers)
  layers = layers or GUI.Layers

  for _, layer in pairs(layers) do
    if layer.elements[name] then return layer.elements[name] end
  end
end

--[[	Return or change an element's value

    For use with external user functions. Returns the given element's current
    value or, if specified, sets a new one.	Changing values with this is often
    preferable to setting them directly, as most :val methods will also update
    some internal parameters and redraw the element when called.
]]--
GUI.Val = function (elm, newval)

    if not GUI.Elements[elm] then return nil end

    if newval then
        GUI.Elements[elm]:val(newval)
    else
        return GUI.Elements[elm]:val()
    end

end


-- Returns the x,y that would center elm1 within elm2.
-- Axis can be "x", "y", or "xy".
GUI.center = function (elm1, elm2)

    local elm2 = elm2   and elm2
                        or  {x = 0, y = 0, w = GUI.cur_w, h = GUI.cur_h}

    if not (    elm2.x and elm2.y and elm2.w and elm2.h
            and elm1.x and elm1.y and elm1.w and elm1.h) then return end

    return (elm2.x + (elm2.w - elm1.w) / 2), (elm2.y + (elm2.h - elm1.h) / 2)


end



------------------------------------
-------- Developer stuff -----------
------------------------------------


-- Print a string to the Reaper console.
GUI.Msg = function (str)
    reaper.ShowConsoleMsg(tostring(str).."\n")
end

-- Returns the specified parameters for a given element.
-- If nothing is specified, returns all of the element's properties.
-- ex. local str = GUI.Elements.my_element:Msg("x", "y", "caption", "col_txt")
function Element:Msg(...)

    local arg = {...}

    if #arg == 0 then
        arg = {}
        for k in Table.kpairs(self, "full") do
            arg[#arg+1] = k
        end
    end

    if not self or not self.type then return end
    local pre = tostring(self.name) .. "."
    local strs = {}

    for i = 1, #arg do

        strs[#strs + 1] = pre .. tostring(arg[i]) .. " = "

        if type(self[arg[i]]) == "table" then
            strs[#strs] = strs[#strs] .. "table:"
            strs[#strs + 1] = Table.stringify(self[arg[i]], nil, 1)
        else
            strs[#strs] = strs[#strs] .. tostring(self[arg[i]])
        end

    end

    --reaper.ShowConsoleMsg( "\n" .. table.concat(strs, "\n") .. "\n")
    return table.concat(strs, "\n")

end


-- Developer mode settings
GUI.dev = {

    -- grid_a must be a multiple of grid_b, or it will
    -- probably never be drawn
    grid_a = 128,
    grid_b = 16

}





------------------------------------
-------- Constants/presets ---------
------------------------------------


GUI.chars = {

    ESCAPE		= 27,
    SPACE		= 32,
    BACKSPACE	= 8,
    TAB			= 9,
    HOME		= 1752132965,
    END			= 6647396,
    INSERT		= 6909555,
    DELETE		= 6579564,
    PGUP		= 1885828464,
    PGDN		= 1885824110,
    RETURN		= 13,
    UP			= 30064,
    DOWN		= 1685026670,
    LEFT		= 1818584692,
    RIGHT		= 1919379572,

    F1			= 26161,
    F2			= 26162,
    F3			= 26163,
    F4			= 26164,
    F5			= 26165,
    F6			= 26166,
    F7			= 26167,
    F8			= 26168,
    F9			= 26169,
    F10			= 6697264,
    F11			= 6697265,
    F12			= 6697266

}


--[[	Font and color presets

    Can be set using the accompanying functions GUI.font
    and GUI.color. i.e.

    GUI.font(2)				applies the Header preset
    GUI.color("elm_fill")	applies the Element Fill color preset

    Colors are converted from 0-255 to 0-1 when GUI.Init() runs,
    so if you need to access the values directly at any point be
    aware of which format you're getting in return.

]]--

GUI.OS_fonts = {

    Windows = {
        sans = "Calibri",
        mono = "Lucida Console"
    },

    OSX = {
        sans = "Helvetica Neue",
        mono = "Andale Mono"
    },

    Linux = {
        sans = "Arial",
        mono = "DejaVuSansMono"
    }

}

GUI.get_OS_fonts = function()

    local os = reaper.GetOS()
    if os:match("Win") then
        return GUI.OS_fonts.Windows
    elseif os:match("OSX") then
        return GUI.OS_fonts.OSX
    else
        return GUI.OS_fonts.Linux
    end

end

local fonts = GUI.get_OS_fonts()
GUI.fonts = {

                -- Font, size, bold/italics/underline
                -- 				^ One string: "b", "iu", etc.
                {fonts.sans, 32},	-- 1. Title
                {fonts.sans, 20},	-- 2. Header
                {fonts.sans, 16},	-- 3. Label
                {fonts.sans, 16},	-- 4. Value
    monospace = {fonts.mono, 14},
    version = 	{fonts.sans, 12, "i"},

}



GUI.colors = T{

    -- Element colors
    wnd_bg = {64, 64, 64, 255},			-- Window BG
    tab_bg = {56, 56, 56, 255},			-- Tabs BG
    elm_bg = {48, 48, 48, 255},			-- Element BG
    elm_frame = {96, 96, 96, 255},		-- Element Frame
    elm_fill = {64, 192, 64, 255},		-- Element Fill
    elm_outline = {32, 32, 32, 255},	-- Element Outline
    txt = {192, 192, 192, 255},			-- Text

    shadow = {0, 0, 0, 48},				-- Element Shadows
    faded = {0, 0, 0, 64},

    -- Standard 16 colors
    black = {0, 0, 0, 255},
    white = {255, 255, 255, 255},
    red = {255, 0, 0, 255},
    lime = {0, 255, 0, 255},
    blue =  {0, 0, 255, 255},
    yellow = {255, 255, 0, 255},
    cyan = {0, 255, 255, 255},
    magenta = {255, 0, 255, 255},
    silver = {192, 192, 192, 255},
    gray = {128, 128, 128, 255},
    maroon = {128, 0, 0, 255},
    olive = {128, 128, 0, 255},
    green = {0, 128, 0, 255},
    purple = {128, 0, 128, 255},
    teal = {0, 128, 128, 255},
    navy = {0, 0, 128, 255},

    none = {0, 0, 0, 0},


}


-- Global shadow size, in pixels
GUI.shadow_dist = 2


--[[
    How fast the caret in textboxes should blink, measured in GUI update loops.

    '16' looks like a fairly typical textbox caret.

    Because each On and Off redraws the textbox's Z layer, this can cause CPU
    issues in scripts with lots of drawing to do. In that case, raising it to
    24 or 32 will still look alright but require less redrawing.
]]--
GUI.txt_blink_rate = 16


-- Odds are you don't need too much precision here
-- If you do, just specify GUI.pi = math.pi() in your code
GUI.pi = 3.14159


-- Delay time when hovering over an element before displaying a tooltip
GUI.tooltip_time = 0.8



------------------------------------
-------- Text functions ------------
------------------------------------


--[[	Apply a font preset

    fnt			Font preset number
                or
                A preset table -> GUI.font({"Arial", 10, "i"})

]]--
GUI.font = function (fnt)

    local font, size, str = table.unpack( type(fnt) == "table"
                                            and fnt
                                            or  GUI.fonts[fnt])

    -- Different OSes use different font sizes, for some reason
    -- This should give a similar size on Mac/Linux as on Windows
    if not string.match( reaper.GetOS(), "Win") then
        size = math.floor(size * 0.8)
    end

    -- Cheers to Justin and Schwa for this
    local flags = 0
    if str then
        for i = 1, str:len() do
            flags = flags * 256 + string.byte(str, i)
        end
    end

    gfx.setfont(1, font, size, flags)

end


--[[	Prepares a table of character widths

    Iterates through all of the GUI.fonts[] presets, storing the widths
    of every printable ASCII character in a table.

    Accessable via:		GUI.txt_width[font_num][char_num]

    - Requires a window to have been opened in Reaper

    - 'get_txt_width' and 'word_wrap' will automatically run this
      if it hasn't been run already; it may be rather clunky to use
      on demand depending on what your script is doing, so it's
      probably better to run this immediately after initiliazing
      the window and then have the width table ready to use.
]]--

GUI.init_txt_width = function ()

    GUI.txt_width = {}
    local arr
    for k in pairs(GUI.fonts) do

        GUI.font(k)
        GUI.txt_width[k] = {}
        arr = {}

        for i = 1, 255 do

            arr[i] = gfx.measurechar(i)

        end

        GUI.txt_width[k] = arr

    end

end


-- Returns the total width (in pixels) for a given string and font
-- (as a GUI.fonts[] preset number or name)
-- Most of the time it's simpler to use gfx.measurestr(), but scripts
-- with a lot of text should use this instead - it's 10-12x faster.
GUI.get_txt_width = function (str, font)

    if not GUI.txt_width then GUI.init_txt_width() end

    local widths = GUI.txt_width[font]
    local w = 0
    for i = 1, string.len(str) do

        w = w + widths[		string.byte(	string.sub(str, i, i)	) ]

    end

    return w

end


-- Measures a string to see how much of it will it in the given width,
-- then returns both the trimmed string and the excess
GUI.fit_txt_width = function (str, font, w)

    local len = string.len(str)

    -- Assuming 'i' is the narrowest character, get an upper limit
    local max_end = math.floor( w / GUI.txt_width[font][string.byte("i")] )

    for i = max_end, 1, -1 do

        if GUI.get_txt_width( string.sub(str, 1, i), font ) < w then

            return string.sub(str, 1, i), string.sub(str, i + 1)

        end

    end

    -- Worst case: not even one character will fit
    -- If this actually happens you should probably rethink your choices in life.
    return "", str

end


--[[	Returns 'str' wrapped to fit a given pixel width

    str		String. Can include line breaks/paragraphs; they should be preserved.
    font	Font preset number
    w		Pixel width
    indent	Number of spaces to indent the first line of each paragraph
            (The algorithm skips tab characters and leading spaces, so
            use this parameter instead)

    i.e.	Blah blah blah blah		-> indent = 2 ->	  Blah blah blah blah
            blah blah blah blah							blah blah blah blah


    pad		Indent wrapped lines by the first __ characters of the paragraph
            (For use with bullet points, etc)

    i.e.	- Blah blah blah blah	-> pad = 2 ->	- Blah blah blah blah
            blah blah blah blah				  	 	  blah blah blah blah


    This function expands on the "greedy" algorithm found here:
    https://en.wikipedia.org/wiki/Line_wrap_and_word_wrap#Algorithm

]]--
GUI.word_wrap = function (str, font, w, indent, pad)

    if not GUI.txt_width then GUI.init_txt_width() end

    local ret_str = {}

    local w_left, w_word
    local space = GUI.txt_width[font][string.byte(" ")]

    local new_para = indent and string.rep(" ", indent) or 0

    local w_pad = pad   and GUI.get_txt_width( string.sub(str, 1, pad), font )
                        or 0
    local new_line = "\n"..string.rep(" ", math.floor(w_pad / space)	)


    for line in string.gmatch(str, "([^\n\r]*)[\n\r]*") do

        table.insert(ret_str, new_para)

        -- Check for leading spaces and tabs
        local leading, line = string.match(line, "^([%s\t]*)(.*)$")
        if leading then table.insert(ret_str, leading) end

        w_left = w
        for word in string.gmatch(line,  "([^%s]+)") do

            w_word = GUI.get_txt_width(word, font)
            if (w_word + space) > w_left then

                table.insert(ret_str, new_line)
                w_left = w - w_word

            else

                w_left = w_left - (w_word + space)

            end

            table.insert(ret_str, word)
            table.insert(ret_str, " ")

        end

        table.insert(ret_str, "\n")

    end

    table.remove(ret_str, #ret_str)
    ret_str = table.concat(ret_str)

    return ret_str

end


-- Draw the given string of the first color with a shadow
-- of the second color (at 45' to the bottom-right)
GUI.shadow = function (str, col1, col2)

    local x, y = gfx.x, gfx.y

    GUI.color(col2 or "shadow")
    for i = 1, GUI.shadow_dist do
        gfx.x, gfx.y = x + i, y + i
        gfx.drawstr(str)
    end

    GUI.color(col1)
    gfx.x, gfx.y = x, y
    gfx.drawstr(str)

end


-- Draws a string using the given text and outline color presets
GUI.outline = function (str, col1, col2)

    local x, y = gfx.x, gfx.y

    GUI.color(col2)

    gfx.x, gfx.y = x + 1, y + 1
    gfx.drawstr(str)
    gfx.x, gfx.y = x - 1, y + 1
    gfx.drawstr(str)
    gfx.x, gfx.y = x - 1, y - 1
    gfx.drawstr(str)
    gfx.x, gfx.y = x + 1, y - 1
    gfx.drawstr(str)

    GUI.color(col1)
    gfx.x, gfx.y = x, y
    gfx.drawstr(str)

end


--[[	Draw a background rectangle for the given string

    A solid background is necessary for blitting z layers
    on their own; antialiased text with a transparent background
    looks like complete shit. This function draws a rectangle 2px
    larger than your text on all sides.

    Call with your position, font, and color already set:

    gfx.x, gfx.y = self.x, self.y
    GUI.font(self.font)
    GUI.color(self.col)

    GUI.text_bg(self.text)

    gfx.drawstr(self.text)

    Also accepts an optional background color:
    GUI.text_bg(self.text, "elm_bg")

]]--
GUI.text_bg = function (str, col, align)

    local x, y = gfx.x, gfx.y
    local r, g, b, a = gfx.r, gfx.g, gfx.b, gfx.a

    col = col or "wnd_bg"

    GUI.color(col)

    local w, h = gfx.measurestr(str)
    w, h = w + 4, h + 4

    if align then

      if align & 1 == 1 then
        gfx.x = gfx.x - w/2
      elseif align & 4 == 4 then
        gfx.y = gfx.y - h/2
      end

    end

    gfx.rect(gfx.x - 2, gfx.y - 2, w, h, true)

    gfx.x, gfx.y = x, y

    gfx.set(r, g, b, a)

end




------------------------------------
-------- Color functions -----------
------------------------------------


--[[	Apply a color preset

    col			Color preset string -> "elm_fill"
                or
                Color table -> {1, 0.5, 0.5[, 1]}
                                R  G    B  [  A]
]]--
GUI.color = function (col)

    -- If we're given a table of color values, just pass it right along
    if type(col) == "table" then

        gfx.set(col[1], col[2], col[3], col[4] or 1)
    else
        gfx.set(table.unpack(GUI.colors[col]))
    end

end


-- Convert a hex color RRGGBB to 8-bit values R, G, B
GUI.hex2rgb = function (num)

    if string.sub(num, 1, 2) == "0x" then
        num = string.sub(num, 3)
    end

    local red = string.sub(num, 1, 2)
    local green = string.sub(num, 3, 4)
    local blue = string.sub(num, 5, 6)


    red = tonumber(red, 16) or 0
    green = tonumber(green, 16) or 0
    blue = tonumber(blue, 16) or 0

    return red, green, blue

end


-- Convert rgb[a] to hsv[a]; useful for gradients
-- Arguments/returns are given as 0-1
GUI.rgb2hsv = function (r, g, b, a)

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local chroma = max - min

    -- Dividing by zero is never a good idea
    if chroma == 0 then
        return 0, 0, max, (a or 1)
    end

    local hue
    if max == r then
        hue = ((g - b) / chroma) % 6
    elseif max == g then
        hue = ((b - r) / chroma) + 2
    elseif max == b then
        hue = ((r - g) / chroma) + 4
    else
        hue = -1
    end

    if hue ~= -1 then hue = hue / 6 end

    local sat = (max ~= 0) 	and	((max - min) / max)
                            or	0

    return hue, sat, max, (a or 1)


end


-- ...and back the other way
GUI.hsv2rgb = function (h, s, v, a)

    local chroma = v * s

    local hp = h * 6
    local x = chroma * (1 - math.abs(hp % 2 - 1))

    local r, g, b
    if hp <= 1 then
        r, g, b = chroma, x, 0
    elseif hp <= 2 then
        r, g, b = x, chroma, 0
    elseif hp <= 3 then
        r, g, b = 0, chroma, x
    elseif hp <= 4 then
        r, g, b = 0, x, chroma
    elseif hp <= 5 then
        r, g, b = x, 0, chroma
    elseif hp <= 6 then
        r, g, b = chroma, 0, x
    else
        r, g, b = 0, 0, 0
    end

    local min = v - chroma

    return r + min, g + min, b + min, (a or 1)

end


--[[
    Returns the color for a given position on an HSV gradient
    between two color presets

    col_a		Tables of {R, G, B[, A]}, values from 0-1
    col_b

    pos			Position along the gradient, 0 = col_a, 1 = col_b

    returns		r, g, b, a

]]--
GUI.gradient = function (col_a, col_b, pos)

    local col_a = {GUI.rgb2hsv( table.unpack( type(col_a) == "table"
                                                and col_a
                                                or  GUI.colors(col_a) )) }
    local col_b = {GUI.rgb2hsv( table.unpack( type(col_b) == "table"
                                                and col_b
                                                or  GUI.colors(col_b) )) }

    local h = math.abs(col_a[1] + (pos * (col_b[1] - col_a[1])))
    local s = math.abs(col_a[2] + (pos * (col_b[2] - col_a[2])))
    local v = math.abs(col_a[3] + (pos * (col_b[3] - col_a[3])))

    local a = (#col_a == 4)
        and  (math.abs(col_a[4] + (pos * (col_b[4] - col_a[4]))))
        or  1

    return GUI.hsv2rgb(h, s, v, a)

end




------------------------------------
-------- Math/trig functions -------
------------------------------------


-- Round a number to the nearest integer (or optional decimal places)
GUI.round = function (num, places)

    if not places then
        return num > 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
    else
        places = 10^places
        return num > 0 and math.floor(num * places + 0.5)
                        or math.ceil(num * places - 0.5) / places
    end

end


-- Returns 'val', rounded to the nearest multiple of 'snap'
GUI.nearestmultiple = function (val, snap)

    local int, frac = math.modf(val / snap)
    return (math.floor( frac + 0.5 ) == 1 and int + 1 or int) * snap

end



-- Make sure num is between min and max
-- I think it will return the correct value regardless of what
-- order you provide the values in.
GUI.clamp = function (num, min, max)

    if min > max then min, max = max, min end
    return math.min(math.max(num, min), max)

end


-- Returns an ordinal string (i.e. 30 --> 30th)
GUI.ordinal = function (num)

    rem = num % 10
    num = GUI.round(num)
    if num == 1 then
        str = num.."st"
    elseif rem == 2 then
        str = num.."nd"
    elseif num == 13 then
        str = num.."th"
    elseif rem == 3 then
        str = num.."rd"
    else
        str = num.."th"
    end

    return str

end


--[[
    Takes an angle in radians (omit Pi) and a radius, returns x, y
    Will return coordinates relative to an origin of (0,0), or absolute
    coordinates if an origin point is specified
]]--
GUI.polar2cart = function (angle, radius, ox, oy)

    local angle = angle * GUI.pi
    local x = radius * math.cos(angle)
    local y = radius * math.sin(angle)


    if ox and oy then x, y = x + ox, y + oy end

    return x, y

end


--[[
    Takes cartesian coords, with optional origin coords, and returns
    an angle (in radians) and radius. The angle is given without reference
    to Pi; that is, pi/4 rads would return as simply 0.25
]]--
GUI.cart2polar = function (x, y, ox, oy)

    local dx, dy = x - (ox or 0), y - (oy or 0)

    local angle = math.atan(dy, dx) / GUI.pi
    local r = math.sqrt(dx * dx + dy * dy)

    return angle, r

end




------------------------------------
-------- Drawing functions ---------
------------------------------------


-- Improved roundrect() function with fill, adapted from mwe's EEL example.
GUI.roundrect = function (x, y, w, h, r, antialias, fill)

    local aa = antialias or 1
    fill = fill or 0

    if fill == 0 or false then
        gfx.roundrect(x, y, w, h, r, aa)
    else

        if h >= 2 * r then

            -- Corners
            gfx.circle(x + r, y + r, r, 1, aa)			-- top-left
            gfx.circle(x + w - r, y + r, r, 1, aa)		-- top-right
            gfx.circle(x + w - r, y + h - r, r , 1, aa)	-- bottom-right
            gfx.circle(x + r, y + h - r, r, 1, aa)		-- bottom-left

            -- Ends
            gfx.rect(x, y + r, r, h - r * 2)
            gfx.rect(x + w - r, y + r, r + 1, h - r * 2)

            -- Body + sides
            gfx.rect(x + r, y, w - r * 2, h + 1)

        else

            r = (h / 2 - 1)

            -- Ends
            gfx.circle(x + r, y + r, r, 1, aa)
            gfx.circle(x + w - r, y + r, r, 1, aa)

            -- Body
            gfx.rect(x + r, y, w - (r * 2), h)

        end

    end

end


-- Improved triangle() function with optional non-fill
GUI.triangle = function (fill, ...)

    -- Pass any calls for a filled triangle on to the original function
    if fill then

        gfx.triangle(...)

    else

        -- Store all of the provided coordinates into an array
        local coords = {...}

        -- Duplicate the first pair at the end, so the last line will
        -- be drawn back to the starting point.
        table.insert(coords, coords[1])
        table.insert(coords, coords[2])

        -- Draw a line from each pair of coords to the next pair.
        for i = 1, #coords - 2, 2 do

            gfx.line(coords[i], coords[i+1], coords[i+2], coords[i+3])

        end

    end

end




------------------------------------
-------- File/Storage functions ----
------------------------------------


-- DEPRECATED: All operating systems seem to be fine with "/"
-- Use when working with file paths if you need to add your own /s
--    (Borrowed from X-Raym)
GUI.file_sep = string.match(reaper.GetOS(), "Win") and "\\" or "/"


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

    local dock, x, y, w, h = string.match(str, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
    if not (dock and x and y and w and h) then return end
    GUI.dock, GUI.x, GUI.y, GUI.w, GUI.h = dock, x, y, w, h

    -- Probably don't want these messing up where the user put the window
    GUI.anchor, GUI.corner = nil, nil

    return dock, x, y, w, h

end




------------------------------------
-------- Reaper functions ----------
------------------------------------


-- Checks for Reaper's "restricted permissions" script mode
-- GUI.script_restricted will be true if restrictions are in place
-- Call GUI.error_restricted to display an error message about restricted permissions
-- and exit the script.
if not os then

    GUI.script_restricted = true

    GUI.error_restricted = function()

        reaper.MB(  "This script tried to access a function that isn't available in Reaper's 'restricted permissions' mode." ..
                    "\n\nThe script was NOT necessarily doing something malicious - restricted scripts are unable " ..
                    "to access a number of basic functions such as reading and writing files." ..
                    "\n\nPlease let the script's author know, or consider running the script without restrictions if you feel comfortable.",
                    "Script Error", 0)

        GUI.quit = true
        GUI.error_message = "(Restricted permissions error)"

        return nil, "Error: Restricted permissions"

    end

    os = setmetatable({}, { __index = GUI.error_restricted })
    io = setmetatable({}, { __index = GUI.error_restricted })

end


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
GUI.get_window_pos = function (x, y, w, h, anchor, corner)

    local ax, ay, aw, ah = 0, 0, 0 ,0

    local __, __, scr_w, scr_h = reaper.my_getViewport(x, y, x + w, y + h,
                                                        x, y, x + w, y + h, 1)

    if anchor == "screen" then
        aw, ah = scr_w, scr_h
    elseif anchor =="mouse" then
        ax, ay = reaper.GetMousePosition()
    end

    local cx, cy = 0, 0
    if corner then
        local corners = {
            TL = 	{0, 				0},
            T =		{(aw - w) / 2, 		0},
            TR = 	{(aw - w) - 16,		0},
            R =		{(aw - w) - 16,		(ah - h) / 2},
            BR = 	{(aw - w) - 16,		(ah - h) - 40},
            B =		{(aw - w) / 2, 		(ah - h) - 40},
            BL = 	{0, 				(ah - h) - 40},
            L =	 	{0, 				(ah - h) / 2},
            C =	 	{(aw - w) / 2,		(ah - h) / 2},
        }

        cx, cy = table.unpack(corners[corner])
    end

    x = x + ax + cx
    y = y + ay + cy

--[[

    Disabled until I can figure out the multi-monitor issue

    -- Make sure the window is entirely on-screen
    local l, t, r, b = x, y, x + w, y + h

    if l < 0 then x = 0 end
    if r > scr_w then x = (scr_w - w - 16) end
    if t < 0 then y = 0 end
    if b > scr_h then y = (scr_h - h - 40) end
]]--

    return x, y

end




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

    reaper.TrackCtl_SetToolTip(str, x + GUI.mouse.x + 16, y + GUI.mouse.y + 16, true)
    GUI.tooltip = str


end


-- Clear the tooltip
GUI.cleartooltip = function()

    reaper.TrackCtl_SetToolTip("", 0, 0, true)
    GUI.tooltip = nil

end


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
