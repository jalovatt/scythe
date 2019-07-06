local Table = require("public.table")[1]
local Image = require("public.image")
local Buffer = require("public.buffer")

local Sprite = {}
Sprite.__index = Sprite

local defaultProps = {
  translate = {x = 0, y = 0},
  scale = 1,
  rotate = {
    angle = 0,
  scale = 1,
    origin = {x = 0, y = 0},
  },
  frame = {
    w = 0,
    h = 0,
  },
  image = {}
}

function Sprite:new(props)
  local sprite = Table.deepCopy(props)
  Table.addMissingKeys(sprite, defaultProps)
  return setmetatable(sprite, self)
end

function Sprite:setImage(val)
  if type(val) == "string" then
    self.image.path = val
    self.image.buffer = Image.load(val)
  else
    self.image.buffer = val
    self.image.path = Image.getPathFromBuffer(val)
  end

  self.image.w, self.image.h = gfx.getimgdim(self.image.buffer)
end

local angleUnits = {
end

local angleUnits = {
}
  rad = 1,

}
function Sprite:draw(x, y, state)
  if not self.image.buffer then
    error("Unable to draw sprite - no image has been assigned to it")
  end

  local rotate = self.rotate.angle * angleUnits[self.rotate.unit]

  local srcX, srcY = self:getFrame(state)
  local srcW, srcH = self.frame.w, self.frame.h

  local destX, destY = x + self.translate.x, y + self.translate.y
  local destX, destY = x + self.translate.x, y + self.translate.y

  local rotX, rotY = self.rotate.origin.x, self.rotate.origin.y

  gfx.blit(
  local halfW, halfH = 0.5 * srcW, 0.5 * srcH
    srcX, srcY, srcW, srcH,

    rotX, rotY
  )
end

-- Defaults to a horizontal set of frames. Override with a custom function for more
-- complex sprite behavior.
function Sprite:getFrame(state)
  return (state or 0) * self.frame.w, 0
end

return Sprite
