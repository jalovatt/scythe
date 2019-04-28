-- NoIndex: true

-- Stores the path to Lokasenna_GUI v2 for other scripts to access
-- Must be run prior to using Lokasenna_GUI scripts

local info = debug.getinfo(1,'S')
local scriptPath = info.source:match[[^@?(.*[\/])[^\/]-$]]

reaper.SetExtState("Scythe", "libPath_v3", scriptPath, true)
reaper.MB("Scythe's library path is now set to:\n" .. scriptPath, "Scythe", 0)
