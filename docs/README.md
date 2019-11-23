# Scythe 3.0 Documentation

#### _Under Construction_

I'm still in the process of documenting everything, sorting out a script to generate docs from the library rather than writing them separately, standardizing things, etc.

The structure of this folder will change a fair bit as I add more content, and this folder will hopefully be replaced by an actual web page.

## Installation

#### TODO: Add ReaPack instructions
- Clone this repository
- In Reaper's Action List, select _ReaScript: Run reaScript (EEL, lua, or python)..._
- Browse to the repository folder, open `library`, and select `Scythe_Set v3 library path.lua`
- You should see a popup confirming that the path has been set

As a test, select _ReaScript: Run reaScript (EEL, lua, or python)..._, browse to the repository folder again, open `development/examples`, and select one of the scripts there. If it runs, Scythe is correctly installed.

## Loading Scythe

Nothing too complicated here, and it's largely the same as in v2.

```lua
local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

loadfile(libPath .. "scythe.lua")()
```

`scythe.lua` adds the library to Lua's `package.path`, so all subsequent modules can be loaded via `require`. It also adds a number of globals:

- `Scythe` contains path information and some flags that scripts may want to check:
  - `Scythe.libPath`: The absolute path to the library.
  - `Scythe.version`: The library version, obtained from the ReaPack package info if available.
  - `Scythe.getContext()`: Returns a table wrapping the values from `reaper.get_action_context` as well as a couple of others.
    ```
    isNewValue, filename, sectionId, commandId, midiMode, midiResolution, midiValue, scriptPath, scriptName
    ```

    **Note:** `get_action_context` clears the MIDI values after returning, so any scripts that need access to those should either get them before calling
    this or simply call this once and rely on it. The initial values are stored internally, so they won't be lost for subsequent calls.
  - `Scythe.hasSWS`: _boolean_, whether the SWS extension is installed. Currently checks for SWS versions >= 2.9.7, since the GUI's text elements use its clipboard functionality.
  - `Scythe.scriptRestricted`: _boolean_, whether the script has been run in Reaper's restricted mode. Restricted scripts are unable to access the file system - the `io` and `os` libraries aren't even loaded. The library's error handler _will_ let the user know if a script crashes because of this.
- `Msg` is a wrapper for `reaper.ShowConsoleMsg`. It accepts multiple arguments, separating them with commas, and includes a line break at the end.

### Options

When loading `scythe.lua`, development mode can be specified:

```lua
loadfile(libPath .. "scythe.lua")({dev = true})
```

At the moment this flag simply adds `/development` to `package.path` so additional libraries such as the test framework and documentation parser can be `require`ed.
