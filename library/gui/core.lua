-- NoIndex: true

local Scythe

-- luacheck: globals GUI
GUI = {}

local Table, T = require("public.table"):unpack()
local Font = require("public.font")
local Color = require("public.color")
local Math = require("public.math")
local Layer = require("gui.layer")
-- local Element = require("gui.element")

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




------------------------------------
-------- Module loading ------------
------------------------------------


-- -- I hate working with 'requires', so I've opted to do it this way.
-- -- This also works much more easily with my Script Compiler.
-- GUI.req = function(file)

--     if missing_lib then return function () end end

--     local file_path = ( (file:sub(2, 2) == ":" or file:sub(1, 1) == "/") and ""
--                                                                           or  Scythe.lib_path )
--                         .. file

--     local ret, err = loadfile(file_path)
--     if not ret then
--         local ret = reaper.ShowMessageBox(  "Couldn't load " .. file ..
--                                 "\n\n" ..
--                                 "Error message:\n" .. tostring(err) ..
--                                 "\n\n" ..
--                                 "Please make sure you have the newest version of Lokasenna_GUI. " ..
--                                 "If you're using ReaPack, select Extensions -> ReaPack -> Synchronize Packages. " ..
--                                 "\n\n" ..
--                                 "If this error persists, contact the script author." ..
--                                 "\n\n" ..
--                                 "Would you like to have a crash report printed "..
--                                 "to the Reaper console?"
--                                 , "Library error", 4
--                             )
--         GUI.error_message = tostring(err)
--         if ret == 6 then GUI.crash(nil, true) end
--         missing_lib = true
--         return function () end

--     else
--         return ret
--     end

-- end




------------------------------------
-------- Main functions ------------
------------------------------------

GUI.Layers = T{}
-- GUI.Elements = T{}

-- Loaded classes
GUI.elementClasses = {}

-- Returns a dense array of layers sorted in ascending z-order
GUI.sortLayers = function (layers)
    local sorted = T{}

    for _, layer in pairs(layers) do
      sorted[#sorted + 1] = layer
    end

    sorted:sort( function(a, b) return a.z < b.z end )

    return sorted
end

GUI.Init = function ()
    xpcall( function()


        -- Create the window
        gfx.clear = reaper.ColorToNative(table.unpack(Color.colors.wnd_bg))

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
        local _, _, wnd_y, _, _ = gfx.dock(-1, 0, 0, 0, 0)
        local _, gui_y = gfx.clienttoscreen(0, 0)
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
        for _, col in pairs(Color.colors) do
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
        if GUI.char == 27 and GUI.escape_bypass then
          GUI.escape_bypass = "close"
        end
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
    if GUI.tooltip
      and (   GUI.mouse.x - GUI.mouse.lx > 0
           or GUI.mouse.y - GUI.mouse.ly > 0) then

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

    local need_redraw, global_redraw -- luacheck: ignore 221
    -- if GUI.redraw_z[0] then
    --     global_redraw = true
    --     GUI.redraw_z[0] = false
    -- else
    need_redraw = GUI.Layers:any(function(l) return l.needsRedraw end)

    if need_redraw or global_redraw then

        -- All of the layers will be drawn to their own buffer (dest = z), then
        -- composited in buffer 0. This allows buffer 0 to be blitted as a whole
        -- when none of the layers need to be redrawn.

        gfx.dest = 0
        gfx.setimgdim(0, -1, -1)
        gfx.setimgdim(0, w, h)

        Color.set("wnd_bg")
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

-- GUI.Draw_Z = function(z)

--   -- Set this before we redraw, so that elms can call a redraw
--   -- from their own :draw method. e.g. Labels fading out
--   GUI.redraw_z[z] = false

--   gfx.setimgdim(z, -1, -1)
--   gfx.setimgdim(z, GUI.cur_w, GUI.cur_h)
--   gfx.dest = z

--   for __, elm in pairs(GUI.elms_list[z]) do
--       if not GUI.Elements[elm] then
--           reaper.MB(  "Error: Tried to update a GUI element that doesn't exist:"..
--                       "\nGUI.Elements." .. tostring(elm), "Whoops!", 0)
--       end

--       -- Reset these just in case an element or some user code forgot to,
--       -- otherwise we get things like the whole buffer being blitted with a=0.2
--       gfx.mode = 0
--       gfx.set(0, 0, 0, 1)

--       GUI.Elements[elm]:draw()
--   end

--   gfx.dest = 0

-- end

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
            local z_max = GUI.sortedLayers[#GUI.sortedLayers].z
            for j = 1023, z_max, -1 do
            --for j = (not prev and 1023 or prev - 1), 0, -1 do

                if not GUI.buffers[j] then
                    ret[i] = j

                    GUI.buffers[j] = true
                    goto skip
                end

            end

            -- Something bad happened, probably my fault
            GUI.error_message = "Couldn't get a new graphics buffer - " ..
              "buffer would overlap element space. z = " .. z_max

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
        for _, v in pairs(num) do
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
GUI.Msg = function (str)
    reaper.ShowConsoleMsg(tostring(str).."\n")
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


-- Delay time when hovering over an element before displaying a tooltip
GUI.tooltip_time = 0.8



------------------------------------
-------- Text functions ------------
------------------------------------



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
    for k in pairs(Font.fonts) do

        Font.set(k)
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

    -- local len = string.len(str)

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
        local leading, rest = string.match(line, "^([%s\t]*)(.*)$")
        if leading then table.insert(ret_str, leading) end

        w_left = w
        for word in string.gmatch(rest,  "([^%s]+)") do

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

    Color.set(col2 or "shadow")
    for i = 1, GUI.shadow_dist do
        gfx.x, gfx.y = x + i, y + i
        gfx.drawstr(str)
    end

    Color.set(col1)
    gfx.x, gfx.y = x, y
    gfx.drawstr(str)

end


-- Draws a string using the given text and outline color presets
GUI.outline = function (str, col1, col2)

    local x, y = gfx.x, gfx.y

    Color.set(col2)

    gfx.x, gfx.y = x + 1, y + 1
    gfx.drawstr(str)
    gfx.x, gfx.y = x - 1, y + 1
    gfx.drawstr(str)
    gfx.x, gfx.y = x - 1, y - 1
    gfx.drawstr(str)
    gfx.x, gfx.y = x + 1, y - 1
    gfx.drawstr(str)

    Color.set(col1)
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
    Font.set(self.font)
    Color.set(self.col)

    GUI.text_bg(self.text)

    gfx.drawstr(self.text)

    Also accepts an optional background color:
    GUI.text_bg(self.text, "elm_bg")

]]--
GUI.text_bg = function (str, col, align)

    local x, y = gfx.x, gfx.y
    local r, g, b, a = gfx.r, gfx.g, gfx.b, gfx.a

    col = col or "wnd_bg"

    Color.set(col)

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
                    "to execute system-level tasks such as reading and writing files." ..
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

    local _, _, scr_w, scr_h = reaper.my_getViewport( x, y, x + w, y + h,
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

-- THIS NEEDS TO MOVED TO THE ELEMENT OR LAYER MODULES SOMEHOW
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
