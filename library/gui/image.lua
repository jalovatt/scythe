-- NoIndex: true

local Buffer = require("gui.buffer")
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


Image.Sprite = {}
Image.Sprite.__index = Image.Sprite

function Image.Sprite:new(props)
  local sprite = Table.deepCopy(props)
  sprite.image = {}
  return setmetatable(sprite, self)
end

-- Accepts a path to load or an existing buffer number
function Image.Sprite:setImage(image)
  if type(image) == "string" then
    self.image = image
  else
    self.image = loadedImages:find(function(_, k) return (k == image) end)
  end

  self.imageWidth, self.imageHeight = gfx.getimgdim(loadedImages[self.image])
end

function Image.Sprite:draw(x, y, frameX, frameY)
  local buffer = loadedImages[self.image]
  --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs] )
  gfx.blit(buffer, 1, 0, (frameX or 0) * self.frameWidth, (frameY or 0) * self.frameHeight, self.frameWidth, self.frameHeight, x, y, self.frameWidth, self.frameHeight)
end

--[[
    Image.Sprite class

    Should accept:
      - image (buffer number or a path to load)
      - frame width/height

    - Should all sprites be stored in a table somewhere a la GUI.elms, maybe
      Image.sprites?

    Methods:
      - Draw:
        - frameX - Frame number, horizontally
        - frameY - Frame number, vertically
        - destX/Y
        - destW/H - if wanting to resize
        - rotation?
        - rotation origin?
      - Delete (free the buffer, remove sprite from the sprite registry if there is one

]]--

return Image
