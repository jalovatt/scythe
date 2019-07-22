-- NoIndex: true
local _, T = require("public.table"):unpack()
local Element = require("gui.element")

local Composite = Element:new()
Composite.__index = Composite
Composite.defaultProps = {
  name = "composite",
  type = "Composite",

  x = 0,
  y = 0,

  children = T{},
  childCount = 0,
}

function Composite:new(props)
  local composite = self:addDefaultProps(props)

  return setmetatable(composite, self)
end

function Composite:redraw()
  if self.layer then self.layer.needsRedraw = true end
end

function Composite:init()
  self.children:forEach(function(child) child:init() end)
end

function Composite:Update(state, last)
  self.children:forEach(function(child) child:Update(state, last) end)
  if self.needsRedraw then
    self:redraw()
    self.needsRedraw = false
  end
end

function Composite:onDelete()
  self.children:forEach(function(child) child:onDelete() end)
end

function Composite:draw()
  self.children:forEach(function(child) child:draw() end)
end

function Composite:addChildren(...)
  for _, elm in pairs({...}) do
    if elm.layer then elm.layer:removeChildren(elm) end

    self.children[elm.name] = elm
    elm.layer = self
    self.childCount = self.childCount + 1
  end

  self:redraw()
  return self
end

function Composite:removeChildren(...)
  for _, elm in pairs({...}) do
    self.children[elm.name] = nil
    elm.layer = nil
    self.childCount = self.childCount - 1
  end

  self:redraw()
  return self
end

function Composite:containsPoint(x, y)
  for _, elm in pairs(self.children) do
    if elm:containsPoint(x, y) then return elm end
  end
end

return Composite
