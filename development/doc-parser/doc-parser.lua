local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

loadfile(libPath .. "scythe.lua")({ dev = true })
local Doc = require("doc-parser.Doc")
local Table, T = require("public.table"):unpack()

local rawDocs = Doc.segmentsFromFile(libPath .. "public/table.lua")
rawDocs:forEach(function(doc)
  Msg(Table.stringify(doc.content, 4))
end)
