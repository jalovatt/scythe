local Scythe = {}

Scythe.lib_path = reaper.GetExtState("Scythe", "lib_path_v3")
if not Scythe.lib_path or Scythe.lib_path == "" then
    reaper.MB("Couldn't find the Scythe library. Please run 'Set Scythe library path' in your Action List.", "Whoops!", 0)
    return
end

package.path = package.path .. ";" .. Scythe.lib_path:match("(.*".."/"..")") .. "?.lua"

Scythe.script_path, Scythe.script_name = ({reaper.get_action_context()})[2]:match("(.-)([^/\\]+).lua$")

Scythe.version = (function()

    local file = Scythe.lib_path .. "/scythe.lua"
    if not reaper.ReaPack_GetOwner then
        return "(" .. "ReaPack not found" .. ")"
    else
        local package, err = reaper.ReaPack_GetOwner(file)
        if not package or package == "" then
            return "(" .. tostring(err) .. ")"
        else
            local ret, repo, cat, pkg, desc, type, ver, author, pinned, fileCount = reaper.ReaPack_GetEntryInfo(package)
            if ret then
                return "v" .. tostring(ver)
            else
                return "(version error)"
            end
        end
    end

end)()

return Scythe
