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
  local basePath = libRoot .. "docs/"
  File.ensurePathExists(basePath)

  File.getFilesRecursive(libRoot, function(name, _, isFolder)
    if isFolder and name:match("^%.git") then return false end
    return isFolder or name:match("%.lua$")
  end)
    :forEach(function(file)
      local docSegments = Doc.fromFile(file.path)
      if not docSegments then return end

      local md = docSegments:orderedMap(function(segment)
        return Md.parseSegment(segment.name, segment.signature, segment.tags)
      end):concat("\n")
      if not md or md == "" then return end

      local subPath, filename = file.path
        :match(libRoot .. "(.+)%.lua")
        :match("^[^\\/]+[\\/]([^\\/]+)[\\/]([^\\/]+)$")

      local writePath = basePath..subPath.."/"..filename..".md"
      File.ensurePathExists(writePath)

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
