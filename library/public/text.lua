-- NoIndex: true

local Font = require("public.font")
local Color = require("public.color")
local Config = require("gui.config")
require("public.string")
local Table, T = require("public.table"):unpack()

local Text = {}


--[[
  Iterates through all of the font prese+ts, storing the widths
  of every printable ASCII character in a table.

  Accessable via:		Text.textWidth[font_num][char_num]

  - Requires a window to have been opened in Reaper

  - 'get_txt_width' and 'wrapText' will automatically run this
    if it hasn't been run already; it may be rather clunky to use
    on demand depending on what your script is doing, so it's
    probably better to run this immediately after initializing
    the window and then have the width table ready to use later.
]]--

Text.initTextWidth = function ()

  Text.textWidth = {}
  local arr
  for k in pairs(Font.fonts) do

    Font.set(k)
    Text.textWidth[k] = {}
    arr = {}

    for i = 1, 255 do

      arr[i] = gfx.measurechar(i)

    end

    Text.textWidth[k] = arr

  end

end


-- Returns the total width (in pixels) for a given string and font
-- (as a preset number or name)
-- Most of the time it's simpler to use gfx.measurestr(), but scripts
-- with a lot of text should use this instead - it's 10-12x faster.
Text.getTextWidth = function (str, font)

  if not Text.textWidth then Text.initTextWidth() end

  local widths = Text.textWidth[font]

  return Table.reduce(str:split("."),
    function(acc, cur)
      return acc + widths[ string.byte(cur) ]
    end,
    0
  )
end


-- Measures a string to see how much of it will it in the given width,
-- then returns both the trimmed string and the excess
Text.fitTextWidth = function (str, font, w)
  -- Assuming 'i' is the narrowest character, get an upper limit to save time
  local maxEnd = math.floor( w / Text.textWidth[font][string.byte("i")] )

  for i = maxEnd, 1, -1 do

    if Text.getTextWidth( string.sub(str, 1, i), font ) < w then

      return string.sub(str, 1, i), string.sub(str, i + 1)

    end

  end

  -- Worst case: not even one character will fit
  -- If this actually happens you should probably rethink your choices in life.
  return "", str

end


--[[
  Returns 'str' wrapped to fit a given pixel width

  str		String. Can include line breaks/paragraphs; they should be preserved.
  font	Font preset number
  w		Pixel width
  indent	Number of spaces to indent the first line of each paragraph
          (The algorithm skips tab characters and leading spaces, so
          use this parameter instead)

  i.e.	Blah blah blah blah		-> indent = 2 ->   Blah blah blah blah
        blah blah blah blah						       	 blah blah blah blah


  pad		Indent wrapped lines by the first __ characters of the paragraph
        (For use with bullet points, etc)

  i.e.	- Blah blah blah blah	-> pad = 2 ->	Blah blah blah blah
          blah blah blah blah				  	 	    blah blah blah blah

  This function expands on the "greedy" algorithm found here:
  https://en.wikipedia.org/wiki/Line_wrap_and_wrapText#Algorithm

]]--
Text.wrapText = function (str, font, w, indent, pad)

  if not Text.textWidth then Text.initTextWidth() end

  local ret = T{}

  local widthLeft, widthWord
  local space = Text.textWidth[font][string.byte(" ")]

  local newParagraph = indent and string.rep(" ", indent) or 0

  local widthPad = pad   and Text.getTextWidth( string.sub(str, 1, pad), font )
                      or 0
  local newLine = "\n"..string.rep(" ", math.floor(widthPad / space)	)

  str:splitLines():forEach(function(line)

    ret:insert(newParagraph)

    -- Check for leading spaces and tabs
    local leading, rest = string.match(line, "^([%s\t]*)(.*)$")
    if leading then ret:insert(leading) end

    widthLeft = w
    rest:split("%s"):forEach(function(word)
      widthWord = Text.getTextWidth(word, font)
      if (widthWord + space) > widthLeft then

        ret:insert(newLine)
        widthLeft = w - widthWord

      else

        widthLeft = widthLeft - (widthWord + space)

      end

      ret:insert(word)
      ret:insert(" ")

    end)

    ret:insert("\n")

  end)

  ret:remove(#ret)

  return table.concat(ret)

end


-- Draw the given string of the first color with a shadow
-- of the second color (at 45' to the bottom-right)
Text.drawWithShadow = function (str, col1, col2)

  local x, y = gfx.x, gfx.y

  Color.set(col2 or "shadow")
  for i = 1, Config.shadowSize do
      gfx.x, gfx.y = x + i, y + i
      gfx.drawstr(str)
  end

  Color.set(col1)
  gfx.x, gfx.y = x, y
  gfx.drawstr(str)

end


-- Draws a string using the given text and outline color presets
Text.drawWithOutline = function (str, col1, col2)

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

    A solid background is necessary for blitting some elements
    on their own; antialiased text with a transparent background
    looks like complete shit. This function draws a rectangle 2px
    larger than your text on all sides.

    Call with your position, font, and color already set:

    gfx.x, gfx.y = self.x, self.y
    Font.set(self.font)
    Color.set(self.col)

    Text.drawBackground(self.text)

    gfx.drawstr(self.text)

    Also accepts an optional background color:
    Text.drawBackground(self.text, "elmBg")

]]--
Text.drawBackground = function (str, col, align)

  local x, y = gfx.x, gfx.y
  local r, g, b, a = gfx.r, gfx.g, gfx.b, gfx.a

  col = col or "windowBg"

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

return Text
