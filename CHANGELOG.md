# Scythe 3.x changelog

## June 08, 2019

- **Breaking:** Restructure the library to keep dev stuff in its own folder
- Scripts can load the library with `loadfile(libPath .. "scythe.lua")({dev = true})` to have the development folder added to _package.path_.
- Add tests for most public modules

## June 01, 2019

- Add a basic test framework and GUI
- Add tests for all functions in `public.color`

## May 25, 2019

- First release for public development
- Add ColorPicker class
- Use 0-1 internally for all colors
