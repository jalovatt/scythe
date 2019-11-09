local T = require("public.table")[2]
local File = {}

-- filter: function(name, path, isFolder)

File.filesInPath = function(path, filter)
  local addSeparator = path:match("[\\/]$") and "" or "/"
  local files = T{}
  local idx = 0

  while true do
    local name = reaper.EnumerateFiles(path, idx)
    if not name then break end

    if not filter or filter(name, path) then
      files[#files+1] = { name = name, path = path..addSeparator..name }
    end

    idx = idx + 1
  end

  return files
end

File.foldersInPath = function(path, filter)
  local addSeparator = path:match("[\\/]$") and "" or "/"
  local folders = T{}
  local idx = 0

  while true do
    local name = reaper.EnumerateSubdirectories(path, idx)
    if not name then break end

    if not filter or filter(name, path, true) then
      folders[#folders+1] = { name = name, path = path..addSeparator..name }
    end

    idx = idx + 1
  end

  return folders
end

File.recursivePathContents = function(path, filter)
  local contents = T{}

  local files = File.filesInPath(path, filter)
  if files then
    for _, file in pairs(files) do
      contents[#contents+1] = file
    end
  end

  local folders = File.foldersInPath(path, filter)
  if folders then
    for _, folder in pairs(folders) do
      local children = File.recursivePathContents(folder.path, filter)
      if children and #children > 0 then folder.children = children end
      contents[#contents+1] = folder
    end
  end

  return (#contents > 0) and contents
end

return File
