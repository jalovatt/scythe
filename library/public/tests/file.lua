-- NoIndex: true
local testFiles = {
  ["/test"] = {
    files = {
      "it.exe",
      "was.bat",
      "the.txt",
      "best.cpp",
      "of.bmp",
      "times.dll",
    },
    folders = {
      "things",
      "stuff",
      "other-stuff",
    }
  },
  ["/test/things"] = {
    files = {
      "apples",
      "bananas",
      "cherries",
    },
    folders = {
      "one",
      "two",
      "three",
    },
  },
  ["/test/things/two"] = {
    files = {
      "four",
      "six",
      "eight",
    },
    folders = {},
  },
}

local Table = require("public.table")[1]

local File = requireWithMocks("public.file", {
  reaper = {
    EnumerateFiles = function(path, idx) return testFiles[path] and testFiles[path].files and testFiles[path].files[idx + 1] end,
    EnumerateSubdirectories = function(path, idx) return testFiles[path] and testFiles[path].folders and testFiles[path].folders[idx + 1] end,
  },
})

describe("File.filesInPath", function()
  test("", function()
    local returnedFiles = File.filesInPath("/test")

    expect(returnedFiles[1]).toShallowEqual({ name = "it.exe", path = "/test/it.exe" })
    expect(returnedFiles[4]).toShallowEqual({ name = "best.cpp", path = "/test/best.cpp" })
  end)
end)

describe("File.foldersInPath", function()
  test("", function()
    local returnedFolders = File.foldersInPath("/test")

    expect(returnedFolders[1]).toShallowEqual({ name = "things", path = "/test/things" })
    expect(returnedFolders[3]).toShallowEqual({ name = "other-stuff", path = "/test/other-stuff" })
  end)
end)

describe("File.traversePath", function()
  test("", function()
    local returnedContents = File.traversePath("/test")

    local things = Table.find(returnedContents, function(t) return t.name == "things" end)
    expect(things).toNotEqual(nil)
    expect(things.children).toNotEqual(nil)

    local two = Table.find(things.children, function(t) return t.name == "two" end)
    expect(two).toNotEqual(nil)

    local six = Table.find(two.children, function(t) return t.name == "six" end)
    expect(six).toNotEqual(nil)
    expect(six.path).toEqual("/test/things/two/six")
  end)
end)
