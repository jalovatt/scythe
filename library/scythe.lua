local Scythe = {}

Scythe.lib_path = reaper.GetExtState("Scythe", "lib_path_v3")
if not Scythe.lib_path or Scythe.lib_path == "" then
    reaper.MB("Couldn't find the Scythe library. Please run 'Set Scythe library path' in your Action List.", "Whoops!", 0) -- luacheck: ignore 631
    return
end

local trimmedPath = Scythe.lib_path:match("(.*".."/"..")")

package.path = package.path .. ";" ..
  trimmedPath .. "?.lua"

Scythe.script_path, Scythe.script_name = ({reaper.get_action_context()})[2]
  :match("(.-)([^/\\]+).lua$")

Scythe.version = (function()

    local file = Scythe.lib_path .. "/scythe.lua"
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

return Scythe
