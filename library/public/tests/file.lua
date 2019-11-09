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
      "ten",
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

describe("File.recursivePathContents", function()
  describe("without a filter", function()
    local returnedContents = File.recursivePathContents("/test")

    local things, stuff, two, six
    test("should find a root-level folder with children", function()
      things = Table.find(returnedContents, function(t) return t.name == "things" end)
      expect(things).toNotEqual(nil)
      expect(things.children).toNotEqual(nil)
    end)

    test("should find a root-level folder without children", function()
      stuff = Table.find(returnedContents, function(t) return t.name == "stuff" end)
      expect(stuff).toNotEqual(nil)
      expect(stuff.children).toEqual(nil)
    end)

    test("should find a child folder", function()
      two = Table.find(things.children, function(t) return t.name == "two" end)
      expect(two).toNotEqual(nil)
    end)

    test("should find a file in the child folder", function()
      six = Table.find(two.children, function(t) return t.name == "six" end)
      expect(six).toNotEqual(nil)
      expect(six.path).toEqual("/test/things/two/six")
    end)
  end)

  describe("with a filter", function()
    local returnedContents = File.recursivePathContents(
      "/test",
      function(name) return name:match("^t") end
    )

    local things, stuff, two, six, ten

    test("should find filter matches at the root level", function()
      things = Table.find(returnedContents, function(t) return t.name == "things" end)
      expect(things).toNotEqual(nil)
      expect(things.children).toNotEqual(nil)
    end)

    test("should not return child items that don't match", function()
      stuff = Table.find(returnedContents, function(t) return t.name == "stuff" end)
      expect(stuff).toEqual(nil)
    end)

    test("should return child items that match", function()
      two = Table.find(things.children, function(t) return t.name == "two" end)
      expect(two).toNotEqual(nil)
    end)

    test("should not return grandchildren that don't match", function()
      six = Table.find(two.children, function(t) return t.name == "six" end)
      expect(six).toEqual(nil)
    end)

    test("should return grandchildren that match", function()
      ten = Table.find(two.children, function(t) return t.name == "ten" end)
      expect(ten).toNotEqual(nil)
    end)
  end)
end)
