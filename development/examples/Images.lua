-- NoIndex: true

--[[
	Scythe example

  - The bare minimum required to display a window and some elements
  - Elements now have defaults defined for all of their parameters, in case
    you forget to include them or are happy with the defaults

]]--

-- The core library must be loaded prior to anything else

local libPath = reaper.GetExtState("Scythe", "libPath_v3")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Set Scythe v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(libPath .. "scythe.lua")()
local GUI = require("gui.core")
local Image = require("gui.image")

local ILabel = require("gui.element"):new()
ILabel.__index = ILabel

ILabel.defaultProps = {
  name = "ilabel",
  type = "ILabel",

  x = 0,
  y = 0,
}


function ILabel:new(props)
  local ilabel = self:addDefaultProps(props)

  return self:assignChild(ilabel)
end

function ILabel:init()
  self.buffer = Image.load(self.image)
  self.w, self.h = gfx.getimgdim(self.buffer)
  if not self.buffer then error("ILabel: The specified image was not found") end
end

function ILabel:draw()
  gfx.mode = 0
  gfx.blit(self.buffer, 1, 0, 0, 0, self.w, self.h, self.x, self.y, self.w, self.h)
end


GUI.elementClasses.ILabel = ILabel

------------------------------------
-------- Window settings -----------
------------------------------------


local window = GUI.createWindow({
  w = 400,
  h = 200,
})


------------------------------------
-------- GUI Elements --------------
------------------------------------


local layer = GUI.createLayer({name = "Layer1", z = 1})

layer:addElements( GUI.createElements(
  {
    name = "ilabel1",
    type =	"ILabel",
    x = 64,
    y = 0,
    image = Scythe.scriptPath .. "images/top_Main.png",
  }
))

window:addLayers(layer)

GUI.Init()
window:open()

GUI.Main()
