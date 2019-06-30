local Table = require("public.table")[1]
local Image = require("gui.image")

local Sprite = {}
Sprite.__index = Sprite

local defaultProps = {
  translate = {x = 0, y = 0},
  scale = 1,
  rotate = {
    angle = 0,
    unit = "rad",
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
  deg = 0,
  rad = 0,
  pct = 0,
}
function Sprite:getAngle()

end
function Sprite:draw(x, y, state)
  if not self.image.buffer then
    error("Unable to draw sprite - no image has been assigned to it")
  end

  local rotate = self.rotate.angle * angleUnits[self.rotate.unit]

  local srcX, srcY = self:getFrame(state)
  local srcW, srcH = self.frame.w, self.frame.h

  local destX, destY = x + self.translate.x, y + self.translate.y
  local destW, destH = self.frame.w * self.scale, self.frame.h * self.scale

  local rotX, rotY = self.rotate.origin.x, self.rotate.origin.y

  gfx.blit(
    self.image.buffer, self.scale, rotate,
    srcX, srcY, srcW, srcH,
    destX, destY, destW, destH,
    rotX, rotY
  )
end

-- Defaults to a horizontal set of frames. Override with a custom function for more
-- complex sprite behavior.
function Sprite:getFrame(state)
  return (state or 0) * self.frame.w, 0
end

return Sprite
