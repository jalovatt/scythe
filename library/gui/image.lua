-- NoIndex: true

local Buffer = require("gui.buffer")

local Image = {}

local loadedImages = {}
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

Image.loadFolder = function(folderPath)
  -- Run through all images in a folder (include subfolders?)
  -- For each:
    -- - Load into a buffer
    -- - Store the buffer in loadedImages
    -- - Store the buffer in a local table keyed by the file path (relative to the
    --   source folder?):
    --[[
        local folderTable = {
          path = "C:/path/to/this/folder"
          ["image1.png"] = 4,
          ["image2.png"] = 5,
          ["images/image3.png"] = 6,
        }
    ]]--
  -- Return the table
end

Image.unloadFolder = function(folderTable) end


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
