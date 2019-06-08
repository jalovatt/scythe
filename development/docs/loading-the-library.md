# Loading Scythe in a script

Nothing too complicated here, and it's largely the same as in v2 of the GUI:

```lua
local libPath = reaper.GetExtState("Scythe", "libPath_v3")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Set Scythe v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

loadfile(libPath .. "scythe.lua")()
local GUI = require("gui.core")
```

`scythe.lua` adds the library to Lua's `package.path`, so all subsequent modules can be loaded via `require`. It also exposes a number of globals:

- `Scythe` contains path information and some flags that scripts may want to check:
  - `Scythe.libPath`: The absolute path to the library.
  - `Scythe.scriptPath`
  - `Scythe.scriptName`: The absolute path and filename (minus `.lua`) of the script being run.
  - `Scythe.version`: The library version, obtained from the ReaPack package info if available.
  - `Scythe.hasSWS`: _boolean_, whether the SWS extension is installed. Currently checks for SWS versions >= 2.9.7, since the GUI's text elements use its clipboard functionality.
  - `Scythe.scriptRestricted`: _boolean_, whether the script has been run in Reaper's restricted mode. Restricted scripts are unable to access the file system - the `io` and `os` libraries aren't even loaded. The library's error handler _will_ let the user know if a script crashes because of this.
- `Msg` is a wrapper for `reaper.ShowConsoleMsg`. It accepts multiple arguments, separating them with commas, and includes a line break at the end.

## Options

When loading `scythe.lua`, development mode can be specified:

```lua
loadfile(libPath .. "scythe.lua")({dev = true})
```

At the moment, this flag simply adds `/development` to `package.path` so additional libraries such as the test framework can be `require`ed.
