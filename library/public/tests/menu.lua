local Menu = require("public.menu")

describe("Menu.parseString", function()
  test("parses a basic set of options", function()
    local str = "1|2|3|4|5|6.12435213613"

    local strOut, sepsOut = Menu.parse.string(str)
    expect(strOut).toEqual(str)
    expect(#sepsOut).toEqual(0)
  end)

  test("parses a set of options with separators", function()
    local str = "1|2||3|4|5||6.12435213613"

    local strOut, sepsOut = Menu.parse.string(str)
    expect(strOut).toEqual(str)
    expect(#sepsOut).toEqual(2)
    expect(sepsOut[1]).toEqual(3)
    expect(sepsOut[2]).toEqual(7)
  end)

  test("parses a set of options with nesting", function()
    local str = "1|2|>3|3.1|3.2|<3.3|4|>5|5.1|5.2|5.3|5.4|5.5|5.6|<5.7|6.12435213613"

    local strOut, sepsOut = Menu.parse.string(str)
    expect(strOut).toEqual(str)
    expect(#sepsOut).toEqual(2)
    expect(sepsOut[1]).toEqual(3)
    expect(sepsOut[2]).toEqual(8)
  end)

  test("parses a set of options with nesting and separators", function()
    local str = "1||2|>3|3.1|3.2|<3.3||4||>5|5.1|5.2|5.3|5.4|5.5|5.6|<5.7|6.12435213613"

    local strOut, sepsOut = Menu.parse.string(str)
    expect(strOut).toEqual(str)
    expect(#sepsOut).toEqual(5)
    expect(sepsOut).toShallowEqual({2,4,8,10,11})
  end)
end)

describe("Menu.parseTable", function()
  test("parses a basic set of options", function()
    local arrIn = {1, 2, 3, 4, 5, 6.12435213613}
    local expected = "1|2|3|4|5|6.12435213613"

    local strOut, sepsOut = Menu.parse.table(arrIn)
    expect(strOut).toEqual(expected)
    expect(#sepsOut).toEqual(0)
  end)

  test("parses a set of options with separators", function()
    local arrIn = {1, 2, "", 3, 4, 5, "", 6.12435213613}
    local expected = "1|2||3|4|5||6.12435213613"

    local strOut, sepsOut = Menu.parse.table(arrIn)
    expect(strOut).toEqual(expected)
    expect(#sepsOut).toEqual(2)
    expect(sepsOut[1]).toEqual(3)
    expect(sepsOut[2]).toEqual(7)
  end)

  test("parses a set of options with nesting", function()
    local arrIn = {1, 2, ">3", 3.1, 3.2, "<3.3", 4, ">5", 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, "<5.7", 6.12435213613}
    local expected = "1|2|>3|3.1|3.2|<3.3|4|>5|5.1|5.2|5.3|5.4|5.5|5.6|<5.7|6.12435213613"

    local strOut, sepsOut = Menu.parse.table(arrIn)
    expect(strOut).toEqual(expected)
    expect(#sepsOut).toEqual(2)
    expect(sepsOut[1]).toEqual(3)
    expect(sepsOut[2]).toEqual(8)
  end)

  test("parses a set of options with nesting and separators", function()
    local arrIn = {1, "", 2, ">3", 3.1, 3.2, "<3.3", "", 4, "", ">5", 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, "<5.7", 6.12435213613}
    local expected = "1||2|>3|3.1|3.2|<3.3||4||>5|5.1|5.2|5.3|5.4|5.5|5.6|<5.7|6.12435213613"

    local strOut, sepsOut = Menu.parse.table(arrIn)
    expect(strOut).toEqual(expected)
    expect(#sepsOut).toEqual(5)
    expect(sepsOut).toShallowEqual({2,4,8,10,11})
  end)

  test("uses a parseKey to get the displayed value", function()
    local arrIn = {
      {caption = "a", value = 11},
      {caption = "b", value = 12},
      {caption = "c", value = 13},
      {caption = "d", value = 14},
      {caption = "e", value = 15},
      {caption = "f", value = 16},
    }

    local strOut, sepsOut = Menu.parse.table(arrIn, "caption")
    expect(strOut).toEqual("a|b|c|d|e|f")
    expect(#sepsOut).toEqual(0)
  end)
end)

describe("Menu.getValue", function()

end)
