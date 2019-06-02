-- NoIndex: true

Scythe = {}

Scythe.libPath = reaper.GetExtState("Scythe", "libPath_v3")
if not Scythe.libPath or Scythe.libPath == "" then
    reaper.MB("Couldn't find the Scythe library. Please run 'Set Scythe library path' in your Action List.", "Whoops!", 0) -- luacheck: ignore 631
    return
end

local trimmedPath = Scythe.libPath:match("(.*".."/"..")")

package.path = package.path .. ";" ..
  trimmedPath .. "?.lua"


if not os then Scythe.scriptRestricted = true end

Error = require("gui.error")
local Table = require("public.table")


Scythe.scriptPath, Scythe.scriptName = ({reaper.get_action_context()})[2]
  :match("(.-)([^/\\]+).lua$")

Scythe.version = (function()

  local file = Scythe.libPath .. "/scythe.lua"
  if not reaper.ReaPack_GetOwner then
    return "(" .. "ReaPack not found" .. ")"
  else
    local package, err = reaper.ReaPack_GetOwner(file)
    if not package or package == "" then
      return "(" .. tostring(err) .. ")"
    else
      -- ret, repo, cat, pkg, desc, type, ver, author, pinned, fileCount = reaper.ReaPack_GetEntryInfo(package)
      local ret, _, _, _, _, _, ver, _, _, _ =
        reaper.ReaPack_GetEntryInfo(package)

      return ret and ("v" .. tostring(ver)) or "(version error)"
    end
  end

end)()

-- Also might need to know this
Scythe.hasSWS = reaper.APIExists("CF_GetClipboardBig")

-- Print arguments to the Reaper console.
Scythe.Msg = function (...)
  local out = Table.map({...},
    function (str) return tostring(str) end
  )
  reaper.ShowConsoleMsg(out:concat(", ").."\n")
end

if not Msg then Msg = Scythe.Msg end

-- return Scythe
