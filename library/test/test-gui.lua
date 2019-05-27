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
local test = require("test.core")

local testFile = Scythe.scriptPath

local function updateTestFile(file)
  testFile = file
  GUI.findElementByName("txt_file"):val(testFile)
end

local function selectFile()
  local retval, userFile = reaper.GetUserFileNameForRead(testFile, "Choose a test file", ".lua")
  if retval then
    updateTestFile(userFile)
  end
end


local testEnv = {
  describe = test.describe,
  it = test.it,
  expect = test.expect,
}
setmetatable(testEnv, {__index = _G})

local function runTests()
  local tests, ret, err

  tests, err = loadfile(testFile, "bt", testEnv)
  if err then
    Msg("Failed to load file:\n\t" .. testFile .. "\n\nError: " .. tostring(err))
  end

  ret, err = pcall( function() tests() end)

  if not ret then
    Msg("Failed to test file:\n\t" .. testFile .. "\n\nError: " .. tostring(err))
  end
end


------------------------------------
-------- Window settings -----------
------------------------------------


local window = GUI.createWindow({
  name = "Test Runner",
  w = 400,
  h = 200,
})




------------------------------------
-------- GUI Elements --------------
------------------------------------


local layer = GUI.createLayer({name = "Layer1", z = 1})

layer:addElements( GUI.createElements(
  {
    name = "txt_file",
    type = "Textbox",
    caption = "File:",
    x = 64,
    y = 8,
    w = 256,
  },
  {
    name = "btn_file",
    type = "Button",
    caption = "...",
    x = 324,
    y = 8,
    func = selectFile,
  },
  {
    name = "btn_go",
    type = "Button",
    caption = "Run Tests",
    x = 128,
    y = 64,
    func = runTests

  }
))

window:addLayers(layer)

GUI.Init()
window:open()

GUI.Main()
