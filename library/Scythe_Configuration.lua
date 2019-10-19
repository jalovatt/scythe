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
local Theme = require("gui.theme")

local Color = require("public.color")
-- Color.addColorsFromRgba(Theme.colors)

local Font = require("public.font")
-- Font.addFonts(Theme.fonts)

local window = GUI.createWindow({
  name = "Scythe Configuration",
  w = 640,
  h = 480,
  anchor = "mouse",
  corner = "C"
})

local function initLayers()
  for _, layer in pairs(window.layers) do
    layer:init()
    layer:redraw()
  end
end

local function updateLiveConfig(k, v)
  Config[k] = tonumber(v)
  initLayers()
end

local function updateLiveColors(k, v)
  Theme.colors[k] = Table.map(v, function(val) return val * 255 end)
  Color.addColorsFromRgba(Theme.colors)
  initLayers()
end

local layers = {
  GUI.createLayer({name = "Static", z = 1}),
  GUI.createLayer({name = "General", z = 2}),
  GUI.createLayer({name = "Appearance", z = 3}),
  GUI.createLayer({name = "Examples", z = 4}),
}

local function centeredPosition(a, b)
  return (a - b) / 2
end

local function saveSettings()

end

local staticHeightOffset = 68
layers[1]:addElements( GUI.createElements(
  {
    name = "tabs",
    type = "Tabs",
    x = 0,
    y = 0,
    tabs = {
      {
        label = "General",
        layers = {layers[2]}
      },
      {
        label = "Appearance",
        layers = {layers[3]}
      },
    },
    tabW = 96
  },
  {
    name = "separator",
    type = "Frame",
    x = 0,
    y = staticHeightOffset - 8,
    w = window.w,
    h = 2,
    fill = true,
    shadow = true,
  },
  {
    name = "save",
    type = "Button",
    x = centeredPosition(window.w, 96),
    y = staticHeightOffset - 40,
    w = 96,
    caption = "Save Settings",
    func = saveSettings,
  }
))

local yOffset = 0
for k, v in Table.kpairs(Config) do
  layers[2]:addElements( GUI.createElement({
    name = "txt_"..k,
    type = "Textbox",
    caption = k,
    x = 128,
    y = 32 + 24 * yOffset + staticHeightOffset,
    w = 96,
    h = 20,
    retval = tostring(v),
    afterLostFocus = function(self) updateLiveConfig(k, self.retval) end
  }))

  yOffset = yOffset + 1
end

yOffset = 0
for k, v in Table.kpairs(Theme.colors) do
  layers[3]:addElements( GUI.createElement({
    name= "col_"..k,
    type = "ColorPicker",
    caption = k,
    x = 128,
    y = 32 + 24 * yOffset + staticHeightOffset,
    color = Table.map(v, function(val) return val / 255 end),
    afterMouseUp = function(self) updateLiveColors(k, self.color) end
  }))

  yOffset = yOffset + 1
end

-- yOffset = yOffset + 1
-- for k, v in Table.kpairs(Theme.fonts) do
--   layers[




window:addLayers(table.unpack(layers))
window:open()

GUI.Main()
