local Font = require("public.font")
local Color = require("public.color")
local Config = require("gui.config")
require("public.string")
local Table, T = require("public.table"):unpack()

local Text = {}





--[[	Prepares a table of character widths

    Iterates through all of the GUI.fonts[] presets, storing the widths
    of every printable ASCII character in a table.

    Accessable via:		Text.text_width[font_num][char_num]

    - Requires a window to have been opened in Reaper

    - 'get_txt_width' and 'word_wrap' will automatically run this
      if it hasn't been run already; it may be rather clunky to use
      on demand depending on what your script is doing, so it's
      probably better to run this immediately after initiliazing
      the window and then have the width table ready to use.
]]--

Text.init_txt_width = function ()

  Text.text_width = {}
  local arr
  for k in pairs(Font.fonts) do

    Font.set(k)
    Text.text_width[k] = {}
    arr = {}

    for i = 1, 255 do

      arr[i] = gfx.measurechar(i)

    end

    Text.text_width[k] = arr

  end

end


-- Returns the total width (in pixels) for a given string and font
-- (as a GUI.fonts[] preset number or name)
-- Most of the time it's simpler to use gfx.measurestr(), but scripts
-- with a lot of text should use this instead - it's 10-12x faster.
Text.get_text_width = function (str, font)

  if not Text.text_width then Text.init_txt_width() end

  local widths = Text.text_width[font]

  return Table.reduce(str:split("."),
    function(acc, cur)
      return acc + widths[ string.byte(cur) ]
    end,
    0
  )
end


-- Measures a string to see how much of it will it in the given width,
-- then returns both the trimmed string and the excess
Text.fit_text_width = function (str, font, w)
  -- Assuming 'i' is the narrowest character, get an upper limit
  local max_end = math.floor( w / Text.text_width[font][string.byte("i")] )

  for i = max_end, 1, -1 do

    if Text.get_text_width( string.sub(str, 1, i), font ) < w then

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
Text.word_wrap = function (str, font, w, indent, pad)

  if not Text.text_width then Text.init_txt_width() end

  local ret_str = T{}

  local w_left, w_word
  local space = Text.text_width[font][string.byte(" ")]

  local new_para = indent and string.rep(" ", indent) or 0

  local w_pad = pad   and Text.get_text_width( string.sub(str, 1, pad), font )
                      or 0
  local new_line = "\n"..string.rep(" ", math.floor(w_pad / space)	)

  str:splitLines():forEach(function(line)

    ret_str:insert(new_para)

    -- Check for leading spaces and tabs
    local leading, rest = string.match(line, "^([%s\t]*)(.*)$")
    if leading then ret_str:insert(leading) end

    w_left = w
    rest:split("%s"):forEach(function(word)
      w_word = Text.get_text_width(word, font)
      if (w_word + space) > w_left then

        ret_str:insert(new_line)
        w_left = w - w_word

      else

        w_left = w_left - (w_word + space)

      end

      ret_str:insert(word)
      ret_str:insert(" ")

    end)

    ret_str:insert("\n")

  end)

  ret_str:remove(#ret_str)

  return table.concat(ret_str)

end


-- Draw the given string of the first color with a shadow
-- of the second color (at 45' to the bottom-right)
Text.drawWithShadow = function (str, col1, col2)

  local x, y = gfx.x, gfx.y

  Color.set(col2 or "shadow")
  for i = 1, Config.shadow_size do
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

    A solid background is necessary for blitting z layers
    on their own; antialiased text with a transparent background
    looks like complete shit. This function draws a rectangle 2px
    larger than your text on all sides.

    Call with your position, font, and color already set:

    gfx.x, gfx.y = self.x, self.y
    Font.set(self.font)
    Color.set(self.col)

    Text.text_bg(self.text)

    gfx.drawstr(self.text)

    Also accepts an optional background color:
    Text.text_bg(self.text, "elm_bg")

]]--
Text.text_bg = function (str, col, align)

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

return Text
