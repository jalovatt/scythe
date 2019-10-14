-- NoIndex: true

local Font = {}

Font.fonts = {}

-- Accepts a table of font presets
Font.addFonts = function(fonts)
  for k, v in pairs(fonts) do
    Font.fonts[k] = v
  end
end


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
