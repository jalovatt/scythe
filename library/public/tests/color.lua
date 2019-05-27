local Color = require("public.color")

describe("Color.fromRgba", function()
  test("red", function()
    expect(Color.fromRgba(255, 0, 0)).toDeepEqual(Color.colors.red)
  end)
  test("blue", function()
    expect(Color.fromRgba(0, 0, 255)).toDeepEqual(Color.colors.blue)
  end)
  test("maroon", function()
    expect(Color.fromRgba(128, 0, 0)).toDeepEqual(Color.colors.maroon)
  end)
  test("gray", function()
    expect(Color.fromRgba(128, 128, 128, 255)).toDeepEqual(Color.colors.gray)
  end)
  test("not lime", function()
    expect(Color.fromRgba(0, 255, 0, 0.99)).toNotDeepEqual(Color.colors.lime)
  end)
  test("not purple", function()
    expect(Color.fromRgba(128, 0, 128, 0)).toNotDeepEqual(Color.colors.purple)
  end)
end)

describe("Color.toRgba", function()
  test("red", function()
    expect(Color.toRgba(Color.colors.red)).toDeepEqual({255, 0, 0, 255})
  end)
  test("blue", function()
    expect(Color.toRgba(Color.colors.blue)).toDeepEqual({0, 0, 255, 255})
  end)
  test("maroon", function()
    expect(Color.toRgba(Color.colors.maroon)).toDeepEqual({128, 0, 0, 255})
  end)
  test("gray", function()
    expect(Color.toRgba(Color.colors.gray)).toDeepEqual({128, 128, 128, 255})
  end)
  test("not lime", function()
    expect(Color.toRgba(Color.colors.lime)).toNotDeepEqual({0, 255, 0, 200})
  end)
  test("not purple", function()
    expect(Color.toRgba(Color.colors.purple)).toNotDeepEqual({128, 0, 128, 0})
  end)
end)

describe("Color.fromHex", function()

end)

describe("Color.toHex", function()

end)

describe("Color.fromHsv", function()

end)

describe("Color.toHsv", function()

end)

describe("Color.set", function()

end)
