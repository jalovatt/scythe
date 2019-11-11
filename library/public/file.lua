local T = require("public.table")[2]
local File = {}

File.files = function(path, idx)
  if not path then return end
  if not idx then return File.files, path, -1 end

  idx = idx + 1
  local file = reaper.EnumerateFiles(path, idx)

  if file then return idx, file end
end

File.folders = function(path, idx)
  if not path then return end
  if not idx then return File.folders, path, -1 end

  idx = idx + 1
  local folder = reaper.EnumerateSubdirectories(path, idx)

  if folder then return idx, folder end
end

File.getFiles = function(path, filter)
  local addSeparator = path:match("[\\/]$") and "" or "/"
  local files = T{}

  for _, file in File.files(path) do
    if not filter or filter(file) then
      files[#files+1] = { name = file, path = path..addSeparator..file }
    end
  end

  return files
end

File.getFolders = function(path, filter)
  local addSeparator = path:match("[\\/]$") and "" or "/"
  local folders = T{}

  for _, folder in File.folders(path) do
    if not filter or filter(folder) then
      folders[#folders+1] = { name = folder, path = path..addSeparator..folder }
    end
  end

  return folders
end

File.getFilesRecursive = function(path, filter, acc)
  if not acc then acc = T{} end

  local addSeparator = path:match("[\\/]$") and "" or "/"

  for _, file in File.files(path) do
    if not filter or filter(file, path) then
      acc[#acc+1] = { name = file, path = path..addSeparator..file }
    end
  end

  for _, folder in File.folders(path) do
    File.getFilesRecursive(path..addSeparator..folder, filter, acc)
  end

  return acc
end

return File
