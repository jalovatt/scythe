# Scythe 3.x changelog

## June 22, 2019

- Adds Table functions:
  - `join`: Accepts any number of indexed tables, returning a new table with their values joined sequentially
  - `zip`: Accepts any number of indexed tables, returning a new table with their values joined alternately

## June 21, 2019

- Adds a public Menu module, which wraps gfx.showmenu to provide more useful output and work with menus in a table form. Replaces all uses of gfx.showmenu with the wrapped version.

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
