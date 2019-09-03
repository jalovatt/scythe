-- NoIndex: true

--[[
  Test script to make sure user events and hooks are being fired correctly
]]--

-- The core library must be loaded prior to anything else

local libPath = reaper.GetExtState("Scythe", "libPath_v3")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Set Scythe v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(libPath .. "scythe.lua")()
local GUI = require("gui.core")
local Table = require("public.table")
local Color = require("public.color")
local Font = require("public.font")

local events = {
  "MouseEnter",
  "MouseLeave",
  "MouseOver",
  "MouseDown",
  "MouseUp",
  "DoubleClick",
  "Drag",
  "RightMouseDown",
  "RightMouseUp",
  "RightDoubleClick",
  "RightDrag",
  "MiddleMouseDown",
  "MiddleMouseUp",
  "MiddleDoubleClick",
  "MiddleDrag",
  "Wheel",
  "Type",
}

local eventGrid = Table.reduce(events, function(grid, event)
  grid[event] = {0, 0}
  return grid
end, {})

local function fillCell(event, idx)
  eventGrid[event][idx] = 1
end

local function updateCell(event, idx)
  if eventGrid[event][idx] == 0 then return end

  eventGrid[event][idx] = eventGrid[event][idx] - 0.03
  return true
end

local function updateCells()
  local ret

  for _, event in pairs(events) do
    local updated = updateCell(event, 1)
    updated = updateCell(event, 2) or updated
    if updated then ret = true end
  end

  return ret
end

local frm_grid = GUI.createElement({
  name = "frm_grid",
  type =	"Frame",
  x = 64,
  y = 200,
  w = 400,
  h = 600,
})

function frm_grid:afterUpdate()
  if updateCells() then self:redraw() end
end

function frm_grid:draw()
  local labelWidth = 150
  local labelHeight = 32

  Color.set("elmBg")
  gfx.rect(self.x, self.y, self.w, self.h, true)

  Font.set(4)

  local cellSize = {
    w = (self.w - labelWidth) / 2,
    h = (self.h - labelHeight) / (2 * #events)
  }

  Color.set("txt")

  gfx.x = self.x + labelWidth
  gfx.y = self.y
  gfx.drawstr("before")

  gfx.x = self.x + labelWidth + cellSize.w
  gfx.drawstr("after")

  local cell

  for i, event in ipairs(events) do
    cell = eventGrid[event]

    gfx.x = self.x
    gfx.y = self.y + labelHeight + (i - 1) * cellSize.h
    Color.set("txt")
    gfx.drawstr(event)
    Color.set("elmFill")
    if cell[1] > 0 then
      gfx.a = cell[1]
      gfx.rect(
        self.x + labelWidth,
        self.y + (i - 1) * cellSize.h + labelHeight,
        cellSize.w,
        cellSize.h,
        true
      )
    end

    if cell[2] > 0 then
      gfx.a = cell[2]
      gfx.rect(
        self.x + labelWidth + cellSize.w,
        self.y + (i - 1) * cellSize.h + labelHeight,
        cellSize.w,
        cellSize.h,
        true
      )
    end

    gfx.a = 1
  end
end

local txt_box = GUI.createElement({
  name = "txt_box",
  type = "Textbox",
  x = 64,
  y = 8,
  w = 128,
  h = 20,
  caption = "Do stuff:",
})


for _, event in pairs(events) do
  txt_box["before"..event] = function(self)
    fillCell(event, 1)
    self:redraw()
  end
  txt_box["after"..event] = function(self)
    fillCell(event, 2)
    self:redraw()
  end
end

------------------------------------
-------- Window settings -----------
------------------------------------


local window = GUI.createWindow({
  w = 700,
  h = 700,
})


------------------------------------
-------- GUI Elements --------------
------------------------------------


local layer = GUI.createLayer({name = "Layer1", z = 1})

layer:addElements(frm_grid, txt_box)

window:addLayers(layer)
window:open()

GUI.Main()
