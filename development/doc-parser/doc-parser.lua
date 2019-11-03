local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

loadfile(libPath .. "scythe.lua")({ dev = true })
local Doc = require("doc-parser.Doc")
local Md = require("doc-parser.Md")
local Table, T = require("public.table"):unpack()

Scythe.wrapErrors(function()
  local libRoot = Scythe.libPath:match("(.*[/\\])".."[^/\\]+[/\\]")
  local file = libRoot .. "working/code-documentation/test-doc.lua"
  local segments = Doc.segmentsFromFile(libPath .. "public/table.lua")

  local mdSegments = segments:orderedReduce(function(acc, segment)
    acc:insert(Md.parseSegment(segment.signature, segment.tags))

    return acc
  end, T{})

  Msg(mdSegments:concat("\n"))
end)
