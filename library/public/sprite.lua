-- NoIndex: true

local Table = require("public.table")
local Image = require("public.image")
local Buffer = require("public.buffer")
local Color = require("public.color")

local sharedBuffer = Buffer.get()

local Sprite = {}
Sprite.__index = Sprite

local defaultProps = {
  translate = {x = 0, y = 0},
  scale = 1,
  rotate = {
    angle = 0,
    unit = "pct",
    -- Rotation origin is disabled until I can implement it properly
    -- Relative to the image's center (i.e. -w/2 = the top-left corner)
    -- origin = {x = 0, y = 0},
  },
  frame = {
    w = 0,
    h = 0,
  },
  image = {},
  drawBounds = false,
}

function Sprite:new(props)
  local sprite = Table.deepCopy(props)
  Table.addMissingKeys(sprite, defaultProps)
  if props.image then
    sprite.image = {}
    Sprite.setImage(sprite, props.image)
  end
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

  local rotX, rotY = 0, 0 -- Rotation origin; forcing to 0 until it can be properly implemented

  local halfW, halfH = 0.5 * srcW, 0.5 * srcH
  local doubleW, doubleH = 2 * srcW, 2 * srcH

  local dest = gfx.dest
  gfx.dest = sharedBuffer
  gfx.setimgdim(sharedBuffer, -1, -1)
  gfx.setimgdim(sharedBuffer, doubleW, doubleH)
  gfx.blit(
    self.image.buffer, 1, 0,
    srcX, srcY, srcW, srcH,
    halfW, halfH, srcW, srcH,
    0, 0
  )
  gfx.dest = dest

  -- For debugging purposes
  if self.drawBounds then
    Color.set("magenta")
    gfx.rect(destX, destY, srcW * self.scale, srcH * self.scale, false)
  end

  gfx.blit(
    sharedBuffer,                               -- source
    1,                                          -- scale
    -- TODO: 2*pi is necessary to avoid issues when crossing 0, I think? Find a better solution.
    rotate + 6.2831854,                         -- rotation
    0,                                          -- srcx
    0,                                          -- srcy
    doubleW,                                    -- srcw
    doubleH,                                    -- srch
    destX + ((rotX - halfW) * self.scale),      -- destx
    destY + ((rotY - halfH) * self.scale),      -- desty
    doubleW * self.scale,                       -- destw
    doubleH * self.scale,                       -- desth
    rotX,                                       -- rotxoffs
    rotY                                        -- rotyoffs
  )
end

-- Defaults to a horizontal set of frames. Override with a custom function for more
-- complex sprite behavior.
function Sprite:getFrame(state)
  return (state or 0) * self.frame.w, 0
end

return Sprite
