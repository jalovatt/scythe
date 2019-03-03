
--[[	Font and color presets

    Can be set using the accompanying functions GUI.font
    and Color.set. i.e.

    Font.set(2)				applies the Header preset
    Color.set("elm_fill")	applies the Element Fill color preset

    Colors are converted from 0-255 to 0-1 when GUI.Init() runs,
    so if you need to access the values directly at any point be
    aware of which format you're getting in return.

]]--
local Font = {}


local OS_fonts = {

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

local get_OS_fonts = function()

    local os = reaper.GetOS()
    if os:match("Win") then
        return OS_fonts.Windows
    elseif os:match("OSX") then
        return OS_fonts.OSX
    else
        return OS_fonts.Linux
    end

end

local fonts = get_OS_fonts()
Font.fonts = {

                -- Font, size, bold/italics/underline
                -- 				^ One string: "b", "iu", etc.
                {fonts.sans, 32},	-- 1. Title
                {fonts.sans, 20},	-- 2. Header
                {fonts.sans, 16},	-- 3. Label
                {fonts.sans, 16},	-- 4. Value
    monospace = {fonts.mono, 14},
    version = 	{fonts.sans, 12, "i"},

}


--[[	Apply a font preset

    fnt			Font preset number
                or
            A preset table -> Font.set({"Arial", 10, "i"})

]]--
Font.set = function (fontIn)

    local font, size, str = table.unpack( type(fontIn) == "table"
                                            and fontIn
                                            or  Font.fonts[fontIn])

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


return Font
