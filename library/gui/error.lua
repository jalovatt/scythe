-- luacheck: globals Scythe
local Error = {}

-- A basic crash handler, just to add some helpful detail
-- to the Reaper error message.
Error.crash = function (errObject, skipMsg)

  if Error.oncrash then Error.oncrash() end

  local by_line = "([^\r\n]*)\r?\n?"
  local trim_path = "[\\/]([^\\/]-:%d+:.+)$"
  local err = errObject   and string.match(errObject, trim_path)
                          or  "Couldn't get error message."

  local trace = debug.traceback()
  local stack = {}
  for line in string.gmatch(trace, by_line) do

    local str = string.match(line, trim_path) or line

    stack[#stack + 1] = str
  end

  local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)$")

  local ret = skipMsg
    and 6
    or reaper.ShowMessageBox(
      name.." has crashed!\n\n"..
      "Would you like to have a crash report printed "..
      "to the Reaper console?",
      "Oops",
      4
    )

  if ret == 6 then
    reaper.ShowConsoleMsg(
      "Error: "..err.."\n\n"..
      "Stack traceback:\n\t"..table.concat(stack, "\n\t", 2).."\n\n"..
      "Scythe:\t".. Scythe.version.."\n"..
      "Reaper:       \t"..reaper.GetAppVersion().."\n"..
      "Platform:     \t"..reaper.GetOS()
    )
  end

  Scythe.quit = true
end

-- Checks for Reaper's "restricted permissions" script mode
-- Scythe.script_restricted will be true if restrictions are in place
-- Call Error.error_restricted to display an error message about restricted permissions
-- and exit the script.

if Scythe.script_restricted then

  Error.error_restricted = function()

      -- luacheck: push ignore 631
      reaper.MB(  "This script tried to access a function that isn't available in Reaper's 'restricted permissions' mode." ..
                  "\n\nThe script was NOT necessarily doing something malicious - restricted scripts are unable " ..
                  "to execute many system-level tasks such as reading and writing files." ..
                  "\n\nPlease let the script's author know, or consider running the script without restrictions if you feel comfortable.",
                  "Script Error", 0)
      -- luacheck: pop

      Error.pushErrorMessage = "(Script was run in restricted mode)"
      error("Restricted permissions")

  end

  os = setmetatable({}, { __index = Error.error_restricted }) -- luacheck: ignore 121
  io = setmetatable({}, { __index = Error.error_restricted }) -- luacheck: ignore 121

end


return Error
