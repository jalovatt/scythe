# Scythe

This repository is the home of Scythe (formerly Lokasenna_GUI), a graphical framework and utility library for Lua scripts in the [Reaper](https://www.reaper.fm/) digital audio workstation.

## Installation

### ReaPack
- To use Scythe-based scripts:
  - Install _Scythe library v3_.
  - In Reaper's action list, run _Script: Scythe_Set v3 library path.lua_.
  - You should see a popup confirming that the path has been set.
- A separate package, _Scythe library v3 (developer tools)_, contains examples and tools for developing your own Scythe scripts.

### Manually
- Download or clone this repository to your machine
- In Reaper's Action List, select _ReaScript: Run reaScript (EEL, lua, or python)..._
- Browse to the repository folder, open `library`, and select `Scythe_Set v3 library path.lua`
- You should see a popup confirming that the path has been set.

### Using Scythe in a script

Nothing too complicated here, and largely the same as in v2. Paste the following at the top of your script, and you're off to the races:

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
  - `Scythe.libRoot`: The absolute path to the repository, in case a script needs to access other files directly.
  - `Scythe.version`: The library version, obtained from the ReaPack package info if available. For manual installations, this will simply be `v3.x`.
  - `Scythe.getContext()`: Returns a table wrapping the values from `reaper.get_action_context` as well as a couple of others.
    ```
    isNewValue, filename, sectionId, commandId, midiMode, midiResolution, midiValue, scriptPath, scriptName
    ```

    **Note:** `get_action_context` clears the MIDI values after returning, so any scripts that need access to those should either get them before calling
    this or simply call this once and rely on it. The initial values are stored internally, so they won't be lost for subsequent calls.
  - `Scythe.hasSWS`: _boolean_, whether the SWS extension is installed. Currently checks for SWS versions >= 2.9.7, since the GUI's text elements use its clipboard functionality.
  - `Scythe.scriptRestricted`: _boolean_, whether the script has been run in Reaper's restricted mode. Restricted scripts are unable to access the file system - the `io` and `os` libraries aren't even loaded. The library's error handler _will_ let the user know if a script crashes because of this.
- `Msg` is a wrapper for `reaper.ShowConsoleMsg`. It accepts multiple arguments, separating them with commas, and includes a line break at the end.
- `qMsg` is the same, but stores messages in an internal queue rather than printing them right away. To print them, call `printQMsg()`. When developing a script it's not unusual to use a large number of console messages, and printing them all immediately can easily slow down or even freeze Reaper. In contrast, queuing messages and printing them all at once doesn't cause any performance issues.

### Options

When loading `scythe.lua`, several options can be enabled:

```lua
loadfile(libPath .. "scythe.lua")({dev = true})
```

- `dev`: At the moment this flag simply adds `/development` to `package.path` so additional libraries such as the test framework and documentation parser can be `require`ed.
- `printErrors`: When an error occurs, automatically prints a crash report to Reaper's console without the "Would you like to print a crash report?" popup, since it can be rather annoying while debugging a script.
