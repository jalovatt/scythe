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
local Table, T = require("public.table"):unpack()
local Test = require("test.core")

local testFile = Scythe.scriptPath




------------------------------------
-------- Window settings -----------
------------------------------------


local window = GUI.createWindow({
  name = "Test Runner",
  w = 356,
  h = 96,
})



------------------------------------
-------- Logic ---------------------
------------------------------------


local recentFiles = T{}

local function loadRecentFiles()
  local fileStr = reaper.GetExtState("Scythe Test Runner", "recentFiles")
  if not fileStr or fileStr == "" then return end

  for file in fileStr:gmatch("[^|]+") do
    recentFiles[#recentFiles + 1] = file
  end
end

local function updateRecentFiles(file)
  local _, existsIdx = recentFiles:find(function(v) return v == file end)
  if existsIdx then
    recentFiles:insert(1, recentFiles:remove(existsIdx))
  else
    recentFiles:insert(1, file)
  end

  if #recentFiles > 10 then recentFiles[11] = nil end

  reaper.SetExtState("Scythe Test Runner", "recentFiles", recentFiles:concat("|"), true)
end

local function updateTestFile(file)
  testFile = file
  GUI.findElementByName("txt_file"):val(testFile)
end


local function showFilesMenu()
  gfx.x = window.state.mouse.x
  gfx.y = window.state.mouse.y

  return gfx.showmenu("Browse...||" .. recentFiles:concat("|"))
end

local function selectFile()
  local menu = showFilesMenu()

  if menu == 1 then
    local _, userFile = reaper.GetUserFileNameForRead(testFile, "Choose a test file", ".lua")
    if userFile then
      updateRecentFiles(userFile)
      if userFile ~= testFile then updateTestFile(userFile) end
      return
    end
  else
    local file = recentFiles[menu - 1]
    if file and file ~= testFile then updateTestFile(file) end
  end
end

local testEnv = Table.shallowCopy(Test)
testEnv.Table = Table
setmetatable(testEnv, {__index = _G})

local function runTests()
  local tests, ret, err

  reaper.ClearConsole()
  Msg("Running tests...\n")

  tests, err = loadfile(testFile, "bt", testEnv)
  if err then
    Msg("Failed to load file:\n\t" .. testFile .. "\n\nError: " .. tostring(err))
  end

  ret, err = pcall( function() tests() end)

  if not ret then
    Msg("Failed to test file:\n\t" .. testFile .. "\n\nError: " .. tostring(err))
  end

  Msg("\nDone!")
end




------------------------------------
-------- GUI Elements --------------
------------------------------------


local layer = GUI.createLayer({name = "Layer1", z = 1})

layer:addElements( GUI.createElements(
  {
    name = "txt_file",
    type = "Textbox",
    caption = "Test file:",
    x = 64,
    y = 8,
    w = 256,
  },
  {
    name = "btn_file",
    type = "Button",
    caption = "...",
    x = 324,
    y = 10,
    w = 24,
    h = 20,
    func = selectFile,
  },
  {
    name = "btn_go",
    type = "Button",
    caption = "Run Tests",
    x = 139,
    y = 48,
    w = 80,
    func = runTests

  }
))

window:addLayers(layer)

GUI.Init()
window:open()

loadRecentFiles()
if #recentFiles > 0 then
  updateTestFile(recentFiles[1])
end

GUI.Main()
