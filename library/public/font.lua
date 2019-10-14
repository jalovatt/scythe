-- NoIndex: true

local Font = {}


local osFonts = {

  Windows = {
    sans = "Calibri",
    mono = "Lucida Console"
  },

  OSX = {
    sans = "Helvetica Neue",
    mono = "Andale Mono"
  },

  Linux = {
    sans = "Liberation Sans",
    mono = "Liberation Mono"
  }

}

local getOsFonts = function()

  local os = reaper.GetOS()
  if os:match("Win") then
    return osFonts.Windows
  elseif os:match("OSX") then
    return osFonts.OSX
  else
    return osFonts.Linux
  end

end

local fonts = getOsFonts()
Font.fonts = {

              -- Font,    size, bold/italics/underline
              --                ^ One string: "b", "iu", etc.
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
            {"Arial", 10, "i"}

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

-- Sees if a font named 'font' exists on this system
-- Returns true/false
Font.exists = function (font)
	if type(font) ~= "string" then return false end

	gfx.setfont(1, font, 10)

	local _, ret_font = gfx.getfont()
	return font == ret_font
end

return Font
