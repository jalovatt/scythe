local Table = require("public.table")[1]
local Image = require("public.image")
local Buffer = require("public.buffer")

local sharedBuffer = Buffer.get()

local Sprite = {}
Sprite.__index = Sprite

local defaultProps = {
  translate = {x = 0, y = 0},
  scale = 1,
  rotate = {
    angle = 0,
    unit = "pct",
    -- Relative to the image's center (i.e. -w/2 = the top-left corner)
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
  deg = 1,
  rad = 1,
  pct = 2 * math.pi,
}

function Sprite:draw(x, y, state)
  if not self.image.buffer then
    error("Unable to draw sprite - no image has been assigned to it")
  end

  local rotate = self.rotate.angle * angleUnits[self.rotate.unit]

  local srcX, srcY = self:getFrame(state)
  local srcW, srcH = self.frame.w, self.frame.h

  local destX, destY = x + self.translate.x, y + self.translate.y

  local rotX, rotY = self.rotate.origin.x, self.rotate.origin.y

  local halfW, halfH = 0.5 * srcW, 0.5 * srcH
  local doubleW, doubleH = 2 * srcW, 2 * srcH

  local dest = gfx.dest
  gfx.dest = sharedBuffer
  gfx.setimgdim(sharedBuffer, 0, 0)
  gfx.setimgdim(sharedBuffer, doubleW, doubleH)
  gfx.blit(
    self.image.buffer, 1, 0,
    srcX, srcY, srcW, srcH,
    halfW, halfH, srcW, srcH,
    0, 0
  )
  gfx.dest = dest

  -- Just for debugging
  gfx.set(1, 0, 1, 1)
  gfx.rect(destX, destY, srcW * self.scale, srcH * self.scale, false)
  gfx.blit(
    sharedBuffer, 1, rotate + 6.2831854,
    0, 0, doubleW, doubleH,
    destX + ((rotX - halfW) * self.scale), destY + ((rotY - halfH) * self.scale), doubleW * self.scale, doubleH * self.scale,
    rotX, rotY
  )
end

-- Defaults to a horizontal set of frames. Override with a custom function for more
-- complex sprite behavior.
function Sprite:getFrame(state)
  return (state or 0) * self.frame.w, 0
end

return Sprite
