local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end

loadfile(libPath .. "scythe.lua")({ dev = true })
local Doc = require("doc-parser.Doc")
local Md = require("doc-parser.Md")
local Table, T = require("public.table"):unpack()

local File = require("public.file")

local libRoot = Scythe.libPath:match("(.*[/\\])".."[^/\\]+[/\\]")

Scythe.wrapErrors(function()
  local pathOut = libRoot .. "docs/modules/"
  File.ensurePathExists(pathOut)

  File.getFilesRecursive(libRoot, function(name, _, isFolder)
    if isFolder and name:match("^%.git") then return false end
    return isFolder or name:match("%.lua$")
  end)
    :forEach(function(file)
      local doc = Doc.fromFile(file.path)
      if not doc then return end

      local subPath = file.path:match(libRoot .. "(.+)%.lua"):match("[\\/](.+)")
      local filename = subPath:gsub("/", ".")

      local md = doc:orderedMap(function(segment)
        return Md.parseSegment(segment.name, segment.signature, segment.tags)
      end):concat("\n")

      local writePath = pathOut.."/"..filename..".md"
      local fileOut, err = io.open(writePath, "w+")
      if not fileOut then
        Msg("Error opening " .. writePath .. ": " .. err)
        return
      end

      fileOut:write(md)
      fileOut:close()

      Msg("wrote: " .. writePath)
    end)
end)
