-- NoIndex: true

local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(libPath .. "scythe.lua")()
local GUI = require("gui.core")
local Table = require("public.table")

local Config = require("gui.config")

local function updateConfig(k, v)
  Config[k] = tonumber(v)
end

local window = GUI.createWindow({
  name = "Scythe - Configure",
  w = 400,
  h = 400,
})

local layer = GUI.createLayer({name = "Layer1", z = 1})

local yOffset = 0
for k, v in Table.kpairs(Config) do
  layer:addElements( GUI.createElement({
    name = "txt_"..k,
    type = "Textbox",
    caption = k,
    x = 128,
    y = 16 + 22 * yOffset,
    w = 96,
    h = 20,
    retval = tostring(v),
    afterLostFocus = function(self) updateConfig(self.caption, self.retval) end
  }))

  yOffset = yOffset + 1
end

window:addLayers(layer)
window:open()

GUI.Main()
