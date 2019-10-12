# Scythe 3.x changelog

## October 12, 2019

- Added a way to bypass elements' input events. To use it, add a `before` event handler that sets `preventDefault = true` on its input state, i.e:

  ```lua
  function my_btn:beforeMouseUp(state) state.preventDefault = true end
  ```

  Note that preventing some events may cause unexpected behavior, for instance if a MouseUp event makes use of data stored by the preceding MouseDown.

## October 1, 2019

- Replaced an automatic call to `reaper.get_action_context()` with a dedicated function that wraps and memoizes the returned values. This was necessary to avoid messing user scripts that require access to the initial MIDI context.

## September 3, 2019

- Added a UI test script for user events and hooks

## July 21, 2019

- Moved `Element:update()` up to the Window class, eliminating a whole bunch of redundant processing. Shouldn't break anything.

## July 13, 2019

- Added functions for queueing messages so that Reaper isn't choked by constantly updating the console:
  - `qMsg(...)`: Stores all arguments in an internal table
  - `printQMsg`: Concatenates and prints the table contents

  In the event of a script error, any remaining messages in the queue are printed out.

- Added `requireWithMocks(requirePath, mocks)` for test suites that need to override `reaper`/`gfx`/etc. functions.

## June 30, 2019

- Slider and Knob use real values for their _default_ props rather than steps.

## June 29, 2019

- Added before + after event hooks for all input events:
  `myElement:beforeMouseUp = function() Msg("before mouse up") end`

## June 22, 2019

- Added Table functions:
  - `join`: Accepts any number of indexed tables, returning a new table with their values joined sequentially
  - `zip`: Accepts any number of indexed tables, returning a new table with their values joined alternately

## June 21, 2019

- Added a public Menu module, which wraps gfx.showmenu to provide more useful output and work with menus in a table form. Replaces all uses of gfx.showmenu with the wrapped version.

## June 12, 2019

- **Breaking:** _GUI.Init_ has been removed, since it wasn't doing anything anymore now that we have the window class. Starting a script just requires:

  ```lua
  myWindow:open()
  GUI.Main()
  ```

- Moved `error.lua` to the public folder so non-GUI scripts can make use of it
- Replaced all instances of `gfx.mouse_cap & number == number` with state flags: `if (state.kb.shift) then`
- In dev mode (press `Ctrl+Shift+Alt+Z`), right-clicking an element allows its current properties to be listed in the console

## June 09, 2019

- If `Element.output` is given a string, any occurrences of `%val%` will be replaced with the element's value
- **Breaking:** Menubar items use named parameters rather than an indexed table.
- Menubar items can now have a table of `params` that will be unpacked as arguments to `func`.

  ```lua
  {caption = "Menu Item", func = mnu_item, params = {"hello", "world!"}},
  ```

## June 08, 2019

- **Breaking:** Restructured the library to keep dev stuff in its own folder
- Scripts can load the library with `loadfile(libPath .. "scythe.lua")({dev = true})` to have the development folder added to _package.path_.
- Added tests for most public modules

## June 01, 2019

- Added a basic test framework and GUI
- Added tests for all functions in `public.color`

## May 25, 2019

- First release for public development
- Added ColorPicker class
- Uses 0-1 internally for all colors
