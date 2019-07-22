-- NoIndex: true

local args = {...}
local scytheOptions = args and args[1] or {}

Scythe = {}

Scythe.libPath = reaper.GetExtState("Scythe", "libPath_v3")
if not Scythe.libPath or Scythe.libPath == "" then
    reaper.MB("Couldn't find the Scythe library. Please run 'Set Scythe library path' in your Action List.", "Whoops!", 0) -- luacheck: ignore 631
    return
end

local function addPaths()
  local paths = {
    Scythe.libPath:match("(.*[/\\])")
  }

  if scytheOptions.dev then
    paths[#paths + 1] = Scythe.libPath:match("(.*[/\\])".."[^/\\]+[/\\]") .. "development/"
  end

  for i, path in pairs(paths) do
    paths[i] = ";" .. path .. "?.lua"
  end

  package.path = package.path .. table.concat(paths, "")
end
addPaths()

local Message = require("public.message")
Msg = Msg or Message.Msg
qMsg = qMsg or Message.queueMsg
printQMsg = printQMsg or Message.printQueue

if not os then Scythe.scriptRestricted = true end

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

Scythe.hasSWS = reaper.APIExists("CF_GetClipboardBig")

-- return Scythe
