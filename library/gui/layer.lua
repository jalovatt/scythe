-- NoIndex: true
local Table, T = require("public.table"):unpack()
local Buffer = require("gui.buffer")

local Layer = T{}
Layer.__index = Layer
Layer.__noCopy = true

function Layer:new(props)
  local layer = Table.deepCopy(props)

  layer.elementCount = 0
  layer.elements = T{}

  layer.hidden = false
  layer.frozen = false

  layer.needsRedraw = false

  return setmetatable(layer, self)
end

function Layer:hide()
  self.hidden = true
  self.needsRedraw = true
end

function Layer:show()
  self.hidden = false
  self.needsRedraw = true
end

function Layer:addElements(...)
  for _, elm in pairs({...}) do
    if elm.layer then elm.layer:removeElements(elm) end

    self.elements[elm.name] = elm
    elm.layer = self
    self.elementCount = self.elementCount + 1
  end

  self.needsRedraw = true
  return self
end

function Layer:removeElements(...)
  for _, elm in pairs({...}) do
    self.elements[elm.name] = nil
    elm.layer = nil
    self.elementCount = self.elementCount - 1
  end

  self.needsRedraw = true
  return self
end


function Layer:init()
  self.buffer = Buffer.get()

  for _, elm in pairs(self.elements) do
    elm:init()
  end
end

function Layer:delete()
  self:removeElements(table.unpack(self.elements))
  Buffer.release(self.buffer)
  self.window.needsRedraw = true
end


function Layer:update(state, last)
  if self.elementCount > 0 and not (self.hidden or self.frozen) then
    for _, elm in pairs(self.elements) do
      elm:Update(state, last)
    end
  end
end

function Layer:redraw()

  -- Set this before we redraw, so that elms can call a redraw
  -- from their own :draw method. e.g. Labels fading out
  self.needsRedraw = false

  gfx.setimgdim(self.buffer, -1, -1)
  gfx.setimgdim(self.buffer, self.window.currentW, self.window.currentH)

  gfx.dest = self.buffer

  for _, elm in pairs(self.elements) do
    -- Reset these just in case an element or some user code forgot to,
    -- otherwise we get things like the whole buffer being blitted with a=0.2
    gfx.mode = 0
    gfx.set(0, 0, 0, 1)

    elm:draw()
  end

  gfx.dest = 0

end

function Layer:findElementByName(name)
  if self.elements[name] then return self.elements[name] end
end

return Layer
