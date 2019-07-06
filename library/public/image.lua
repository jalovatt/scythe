-- NoIndex: true

local Buffer = require("public.buffer")
local Table, T = require("public.table"):unpack()

local validExtensions = {
  png = true,
  jpg = true,
}

local Image = {}

local loadedImages = T{}
Image.load = function(imagePath)
  if loadedImages[imagePath] then return loadedImages[imagePath] end

  local buffer = Buffer.get()
  local ret = gfx.loadimg(buffer, imagePath)

  if ret > -1 then
    loadedImages[imagePath] = buffer
    return buffer
  else
    Buffer.release(buffer)
  end

  return false
end


-- TODO: Should free the buffer associated with a given image
Image.unload = function(imagePath)
  local buffer = loadedImages[imagePath]
  if buffer then
    Buffer.release(buffer)
    loadedImages[imagePath] = nil
  end

end

Image.hasValidImageExtension = function(file)
  local ext = file:match("%.(.-)$")
  return validExtensions[ext]
end

Image.loadFolder = function(folderPath)
  local fileIndex = 0
  local folderImages = {path = folderPath, images = T{}}
  local file
  while true do
    file = reaper.EnumerateFiles(folderPath, fileIndex)
    if (not file or file == "") then break end

    if Image.hasValidImageExtension(file) then
      local buffer = Image.load(folderPath.."/"..file)
      if buffer then
        folderImages.images[file] = buffer
      end
    end

    fileIndex = fileIndex + 1
  end

  return folderImages
end

Image.unloadFolder = function(folderTable)
  for k in pairs(folderTable.images) do
    Image.unload(folderTable.path.."/"..k)
  end
end

Image.getPathFromBuffer = function(buffer)
  return loadedImages:find(function(v, k) return (v == buffer) and k end)
end


return Image
