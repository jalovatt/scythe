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
  name = "Scythe Configuration",
  w = 400,
  h = 400,
})

local layers = {
  GUI.createLayer({name = "Static", z = 1}),
  GUI.createLayer({name = "General", z = 2}),
  GUI.createLayer({name = "Appearance", z = 3}),
}

local yOffset = 0
for k, v in Table.kpairs(Config) do
  layers[1]:addElements( GUI.createElement({
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

window:addLayers(table.unpack(layers))
window:open()

GUI.Main()
