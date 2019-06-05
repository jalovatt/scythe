local Table = require("public.table")

describe("Table.forEach", function()
  test("performs an operation on every element", function()
    local t = {2, 4, 6}
    local sum = 0
    Table.forEach(t, function(val)
      sum = sum + val
    end)
    expect(sum).toEqual(12)
  end)
end)

describe("Table.orderedForEach", function()
  test("performs an operation on every element", function()
    local t = {2, 4, 6}
    local sum = 0
    Table.forEach(t, function(val)
      sum = sum + val
    end)
    expect(sum).toEqual(12)
  end)

  test("accesses the elements in order", function()
    local t = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
    local out = {}
    Table.forEach(t, function(val)
      out[#out+1] = val
    end)
    expect(table.concat(t)).toEqual("abcdefghijklmnopqrstuvwxyz")
  end)
end)

describe("Table.map", function()
  test("returns a table", function()
    local out = Table.map({})
    expect(type(out)).toEqual("table")
  end)

  test("performs an operation on every element", function()
    local t = {2, 4, 6}
    local out = Table.map(t, function(val)
      return val * 2
    end)
    table.sort(out)
    expect(out[1]).toEqual(4)
    expect(out[2]).toEqual(8)
    expect(out[3]).toEqual(12)
  end)
end)

describe("Table.orderedMap", function()
  test("returns a table", function()
    local out = Table.orderedMap({})
    expect(type(out)).toEqual("table")
  end)

  test("accesses the elements in order", function()
    local t = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
    local out = Table.orderedMap(t, function(val)
      return val
    end)
    expect(table.concat(out)).toEqual("abcdefghijklmnopqrstuvwxyz")
  end)

  test("performs an operation on every element", function()
    local t = {2, 4, 6}
    local out = Table.orderedMap(t, function(val)
      return val * 2
    end)
    expect(out[1]).toEqual(4)
    expect(out[2]).toEqual(8)
    expect(out[3]).toEqual(12)
  end)
end)

xdescribe("Table.filter", function()
  test("returns a table", function()
    local out = Table.filter({})
    expect(type(out)).toEqual("table")
  end)

  test("filters elements based on a condition", function()
    local input = {1, 2, 3, 4, 5, 6, 7, 8}
    local out = Table.filter(input, function(val)
      return (val % 2 == 0)
    end)
    expect(#out).toEqual(4)
  end)

end)

xdescribe("Table.orderedFilter", function()
  test("returns a table", function()
    local out = Table.orderedFilter({})
    expect(type(out)).toEqual("table")
  end)

  test("filters elements based on a condition", function()
    local input = {1, 2, 3, 4, 5, 6, 7, 8}
    local out = Table.orderedFilter(input, function(val)
      return (val % 2 == 0)
    end)
    expect(#out).toEqual(4)
  end)

  test("accesses the elements in order", function()
    local input = {"a", "b", "c", "d", "e", "f", "g", "h", "i"}
    local out = Table.orderedFilter(input, function(val)
      return (string.match("bidding", val))
    end)
    expect(out[1]).toEqual("b")
    expect(out[2]).toEqual("d")
    expect(out[2]).toEqual("g")
    expect(out[3]).toEqual("i")
  end)
end)

describe("Table.reduce", function()
  test("passes and returns the given accumulator", function()
    local t = {1, 2, 3, 4, 5, 6, 7}
    local source = {}

    local out = Table.reduce(t, function(acc)
      return acc
    end, source)
    expect(out).toEqual(source)

  end)

  test("defaults the accumulator to 0", function()
    local t = {1, 2, 3, 4, 5, 6, 7}
    local out = Table.reduce(t, function(acc)
      return acc
    end)

    expect(out).toEqual(0)
  end)

  test("performs an operation on every element", function()
    local t = {1, 2, 3, 4, 5, 6, 7}
    local out = Table.reduce(t, function(acc, val)
      return acc + val
    end)

    expect(out).toEqual(28)
  end)
end)

describe("Table.orderedReduce", function()
  test("passes and returns the given accumulator", function()
    local t = {1, 2, 3, 4, 5, 6, 7}
    local source = {}

    local out = Table.reduce(t, function(acc)
      return acc
    end, source)
    expect(out).toEqual(source)

  end)

  test("defaults the accumulator to 0", function()
    local t = {1, 2, 3, 4, 5, 6, 7}
    local out = Table.reduce(t, function(acc)
      return acc
    end)

    expect(out).toEqual(0)
  end)

  test("performs an operation on every element", function()
    local t = {1, 2, 3, 4, 5, 6, 7}
    local out = Table.reduce(t, function(acc, val)
      return acc + val
    end)

    expect(out).toEqual(28)
  end)

  test("accesses the elements in order", function()
    local input = {"a", "b", "c", "d", "e", "f", "g", "h", "i"}
    local out = Table.orderedReduce(input, function(acc, val)
      acc[#acc + 1] = val
      return acc
    end, {})

    local outStr = Table.concat(out)
    expect(outStr).toEqual("abcdefghi")
  end)
end)

describe("Table.shallowCopy", function()
  test("returns a table", function()
    local out = Table.map({})
    expect(type(out)).toEqual("table")
  end)

  test("has the same content (primitives)", function()
    local tIn = {1, 2, 3, a = 4, b = 5}
    local tOut = Table.shallowCopy(tIn)
    expect(#tOut).toEqual(3)
    expect(tOut.a).toEqual(4)
    expect(tOut.b).toEqual(5)
  end)

  test("has the same content (table references)", function()
    local tIn = {a = {1, 2, 3}, b = 1, c = 2}
    local tOut = Table.shallowCopy(tIn)
    expect(tOut.a).toEqual(tIn.a)
  end)
end)

describe("Table.deepCopy", function()
  test("returns a new table", function()
    local tIn = {}
    local tOut = Table.deepCopy(tIn)
    expect(type(tOut)).toEqual("table")
    expect(tOut).toNotEqual(tIn);
  end)

  test("has the same content (primitives)", function()
    local tIn = {1, 2, 3, a = 4, b = 5}
    local tOut = Table.deepCopy(tIn)
    expect(#tOut).toEqual(3)
    expect(tOut.a).toEqual(4)
    expect(tOut.b).toEqual(5)
  end)

  test("does not have the same tables", function()
    local tIn = {a = {1, 2, 3}, b = 1, c = 2}
    local tOut = Table.deepCopy(tIn)
    expect(tOut.a).toNotEqual(tIn.a)
  end)

  test("Deep-copies tables recursively", function()
    local tIn = {a = {b = {c = "test"}}}
    local tOut = Table.deepCopy(tIn)
    expect(tOut.a).toNotEqual(tIn)
    expect(tOut.a.b).toNotEqual(tIn)
    expect(tOut.a.b.c).toEqual("test")
  end)
end)

xdescribe("Table.stringify", function()

end)

xdescribe("Table.shallowEquals", function()

end)

xdescribe("Table.deepEquals", function()

end)

xdescribe("Table.fullSort", function()

end)

xdescribe("Table.kpairs", function()

end)

xdescribe("Table.invert", function()

end)

xdescribe("Table.find", function()

end)

xdescribe("Table.any", function()

end)

xdescribe("Table.all", function()

end)

xdescribe("Table.none", function()

end)

xdescribe("Table.fullLength", function()

end)

xdescribe("Table.sortHashesByKey", function()

end)

xdescribe("Table.addMissingKeys", function()

end)

xdescribe("Table.chainableSort", function()

end)
