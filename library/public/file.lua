local File = {}

File.filesInPath = function(path)
  local addSeparator = path:match("[\\/]$") and "" or "/"
  local files = {}
  -- reaper.EnumerateFiles( path, fileindex )
  local idx = 0
  local name
  while true do
    name = reaper.EnumerateFiles(path, idx)
    if not name then break end

    files[#files+1] = { name = name, path = path..addSeparator..name }
    idx = idx + 1
  end

  return files
end

File.foldersInPath = function(path)
  local addSeparator = path:match("[\\/]$") and "" or "/"
  local folders = {}
  local idx = 0
  local name
  while true do
    name = reaper.EnumerateSubdirectories(path, idx)
    if not name then break end

    folders[#folders+1] = { name = name, path = path..addSeparator..name }
    idx = idx + 1
  end

  return folders
end

File.traversePath = function(path)
  local contents = {}
  for _, file in pairs(File.filesInPath(path)) do
    contents[#contents+1] = file
  end

  for _, folder in pairs(File.foldersInPath(path)) do
    folder.children = File.traversePath(folder.path)
    contents[#contents+1] = folder
  end

  return contents
end

return File
