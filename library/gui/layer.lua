local _, T = require("public.table"):unpack()
local Buffer = require("gui.buffer")

local Layer = T{}
function Layer:new(props)
  local layer = props

  layer.elementCount = 0
  layer.elements = {}

  layer.hidden = false
  layer.frozen = false

  layer.needsRedraw = false

  setmetatable(layer, self)
  self.__index = self

  return layer
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
  self.buff = Buffer.get()

  for _, elm in pairs(self.elements) do
    elm:init()
  end
end

function Layer:delete()
  self:removeElements(table.unpack(self.elements))
  Buffer.release(self.buff)
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

  gfx.setimgdim(self.buff, -1, -1)
  gfx.setimgdim(self.buff, self.window.cur_w, self.window.cur_h)

  gfx.dest = self.buff

  for _, elm in pairs(self.elements) do
      -- if not GUI.Elements[elm] then
      --     reaper.MB(  "Error: Tried to update a GUI element that doesn't exist:"..
      --                 "\nGUI.Elements." .. tostring(elm), "Whoops!", 0)
      -- end

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
