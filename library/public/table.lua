-- NoIndex: true

local Table = {}
setmetatable(Table, {__index = table})

---
-- @desc        Sets a table's metatable to allow it to access both the Table
--              module and Lua's native table functions via : syntax. i.e.:
--              local myTable = T{}
--              myTable:sort():map():stringify()
-- @param t     table
-- @return      table   The original table reference
local T = function(t) return setmetatable(t, {__index = Table}) end

---
-- @desc        Iterates over a given table, passing each entry to the callback.
--              Important: The order of entries is not guaranteed.
-- @param t     table       A table
-- @param cb    function    Will be called for each entry in the table and passed
--                          the arguments [value, key, t]. Any return value will
--                          be ignored.
Table.forEach = function(t, cb)
  for k, v in pairs(t) do
    cb(v, k, t)
  end
end

---
-- @desc        Identical to Table.forEach, but guaranteed to run in numerical
--              order on only the array portion of the given table.
-- @param t     table       A table
-- @param cb    function    Will be called for each entry in the array portion of
--                          the table and passed the arguments [value, index, t].
--                          Any returned value will be ignored.
Table.orderedForEach = function(t, cb)
  local l = #t

  for i = 1, l do
    cb(t[i], i, t)
  end
end

---
-- @desc        Iterates over the given table, calling cb(value, key, t) for each
--              element and collecting the returned values into a new table with
--              the original keys.
-- @param t     table       A table
-- @param cb    function    Will be called for each entry in the table and passed
--                          the arguments [value, key, t]. Should return a value.
-- @return      table
Table.map = function(t, cb)
  local mapped = T{}

  for k, v in pairs(t) do
    mapped[k] = cb(v, k, t)
  end

  return mapped
end

---
-- @desc        Iterates over the given table, calling cb(value, key, t) for each
--              element and collecting the returned values into a new table with
--              the original keys. Only operates on the array portion of the table,
--              but is guaranteed to run in order.
-- @param t     table       A table
-- @param cb    function    Will be called for each entry in the table and passed
--              the arguments [value, key, t]. Should return a value.
-- @return      table
Table.orderedMap = function(t, cb)
  local mapped = T{}
  local l = #t

  for i = 1, l do
    mapped[i] = cb(t[i], i, t)
  end

  return mapped
end

---
-- @desc        Creates a new table containing only those elements of the given
--              table for which cb(value, key, t) returns true. Not guaranteed to
--              return elements in their original order.
-- @param t     table       A table
-- @param cb    function    Will be called for each entry in the table and passed
--              the arguments [value, key, t]. Should return a boolean.
-- @return      table
Table.filter = function(t, cb)
  local filtered, l = T{}, 1

  for k, v in pairs(t) do
    if cb(v, k, t) then
      filtered[l] = v
      l = l + 1
    end
  end

  return filtered
end

---
-- @desc        Creates a new table containing only those elements of the given
--              table for which cb(value, key, t) returns true. Only operates on
--              the array portion of the table, but is guaranteed to run in order.
-- @param t     table       A table
-- @param cb    function    Will be called for each entry in the table and passed
--              the arguments [value, key, t]. Should return a boolean.
-- @return      table
Table.orderedFilter = function(t, cb)
  local filtered, fl = T{}, 1
  local l = #t

  for i = 1, l do
    if cb(t[i], i, t) then
      filtered[fl] = t[i]
      fl = fl + 1
    end
  end

  return filtered
end

---
-- @desc        Iterates over a given table with the given accumulator (or 0, if
--              not provided) and callback, using the returned value as the
--              accumulator for the next iteration. Not guaranteed to run in order.
-- @param t     table       A table
-- @param cb    function    Will be called for each entry in the table and passed
--              the arguments [accumulator, value, key, t]. Must return an accumulator.
-- @param acc   any         An accumulator, defaulting to 0 if not specified.
-- @return      any         Returns the final accumulator
Table.reduce = function(t, cb, acc)
  if acc == nil then acc = 0 end

  for k, v in pairs(t) do
    acc = cb(acc, v, k, t)
  end

  return acc
end

---
-- @desc        Iterates over a given table with the given accumulator (or 0, if
--              not provided) and callback, using the returned value as the
--              accumulator for the next iteration. Guaranteed to run in order on
--              only the array portion of the table.
-- @param t     table       A table
-- @param cb    function    Will be called for each entry in the table and passed
--              the arguments [accumulator, value, key, t]. Must return an accumulator.
-- @param acc   any         An accumulator, defaulting to 0 if not specified.
-- @return      any         Returns the final accumulator
Table.orderedReduce = function(t, cb, acc)
  if acc == nil then acc = 0 end

  local l = #t
  for i = 1, l do
    acc = cb(acc, t[i], i, t)
  end

  return acc
end

---
-- @desc        Performs a shallow copy of the given table - that is, only the
--              "top" level of elements is considered. Any tables or functions are
--              copied by reference to the new table. Taken from: http://lua-users.org/wiki/CopyTable
-- @param t     table       A table
-- @return      table
Table.shallowCopy = function(t)
  local copy
  if type(t) == "table" then
    copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
  else -- number, string, boolean, etc
    copy = t
  end
  return copy
end


---
-- @desc        Performs a deep copy of the given table - any tables are recursively
--              deep-copied to the new table. To keep items from being deep-copied
--              and/or prevent circular references from causing a stack overflow,
--              tables with .__noRecursion will be copied by reference. Adapted
--              from: http://lua-users.org/wiki/CopyTable
-- @param t     table       A table
-- @return      table
Table.deepCopy = function(t, copies)
  copies = copies or {}

  local copy
  if type(t) == "table" then
    if copies[t] then
        copy = copies[t]

    else
      -- Override so we don't end up working through circular references for
      -- elements, layers, etc
      if t.__noRecursion then
        copy = t
      else
        copy = {}
        for k, v in next, t, nil do
          copy[Table.deepCopy(k, copies)] = Table.deepCopy(v, copies)
        end
      end

      copies[t] = copy
      setmetatable(copy, Table.deepCopy(getmetatable(t), copies))
    end
  else -- number, string, boolean, etc
    copy = t
  end
  return copy
end

---
-- @desc        Returns a string of the table's contents, indented to show nested
--              tables. If t contains classes, or a lot of nested tables, etc, be
--              wary of using larger values for maxDepth; this function will happily
--              freeze Reaper for ten minutes. Do **not** use this with recursive
--              tables.
-- @param t     table     A table
-- @param maxDepth  integer  Maximum depth of nested tables to process. Defaults to 2.
-- @return      string
Table.stringify = function (t, maxDepth, currentDepth)
  local ret = {}
  maxDepth = maxDepth or 2
  currentDepth = currentDepth or 0

  for n,v in pairs(t) do
    ret[#ret+1] = string.rep("  ", currentDepth) .. tostring(n) .. " = "

    if type(v) == "table" then
      ret[#ret] = ret[#ret] .. "table:"

      if (not maxDepth or currentDepth < maxDepth) and not v.__noRecursion then
        ret[#ret+1] = Table.stringify(v, maxDepth, currentDepth + 1)
      end
    else
      ret[#ret] = ret[#ret] .. tostring(v)
    end
  end

  return table.concat(ret, "\n")
end

---
-- @desc        Performs a shallow comparison of two tables. Only "top-level"
--              elements are considered; functions and tables are compared by
--              reference.
-- @param a     table
-- @param b     table
-- @return      boolean
Table.shallowEquals = function (a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return false end

  local seenKeys = {}
  for k1, v1 in pairs(a) do
    if b[k1] ~= v1 then return false end
    seenKeys[k1] = true
  end
  for k2 in pairs(b) do
    if not seenKeys[k2] then return false end
  end

  return true
end

---
-- @desc        Recursively compares the contents of two tables, since Lua doesn't
--              offer it returns true if all of table a's keys and values match
--              all of table b's.
-- @param a     table
-- @param b     table
-- @return      boolean
Table.deepEquals = function (a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  if a == b then return true end

  local seenKeys = {}
  for k1, v1 in pairs(a) do
    local v2 = b[k1]

    if v2 == nil then return false end
    if type(v1) ~= "table" then
      if v1 ~= v2 then return false end
    else
      if v1 ~= v2 and not Table.deepEquals(v1, v2) then return false end
    end

    seenKeys[k1] = true
  end
  for k2 in pairs(b) do
    if not seenKeys[k2] then return false end
  end

  return true
end

local fullSortTypes = {
  boolean = {number = true, string = true, ["function"] = true, table = true},
  number = {boolean = false, string = true, ["function"] = true, table = true},
  string = {boolean = false, number = false, ["function"] = true, table = true},
  ["function"] = {boolean = false, number = false, string = false, table = true},
  table = {boolean = false, number = false, string = false, ["function"] = false},
}

---
-- @desc        Sorts values of different types (bool < num < string < reference),
--              for use with table.sort or anything else that takes a sorter.
--              Use as a callback for table.sort:
--                local t = {"a", 1, {}, 5}
--                table.sort(t, Table.fullSort)
--                --> t == {1, 5, "a", {}}
--              Adapted from: http://lua-users.org/wiki/SortedIteration
-- @param a     boolean|num|string|reference
-- @param b     boolean|num|string|reference
-- @return      boolean
Table.fullSort = function (a, b)
  -- Sort strings that begin with a number as if they were numbers,
  -- i.e. so that 12 > "6 apples"
  if type(a) == "string" and string.match(a, "^(%-?%d+)") then
    a = tonumber( string.match(a, "^(%-?%d+)") )
  end
  if type(b) == "string" and string.match(b, "^(%-?%d+)") then
    b = tonumber( string.match(b, "^(%-?%d+)") )
  end

  local typeA, typeB = type(a), type(b)
  if typeA ~= typeB then --cmp by type
    return fullSortTypes[typeA][typeB]
  elseif typeA == "number" and typeB == "number"
      or typeA == "string" and typeB == "string" then
    return a < b --comp by default
  elseif typeA == "boolean" and typeB == "boolean" then
    return a == true
  else
    return tostring(a) < tostring(b) --cmp by address
  end

end

---
-- @desc        Sorts all table values in alphanumeric order. Adapted from
--              Programming In Lua, chapter 19.3. Usage: for k, v in kpairs(t) do
-- @param t     table   A table
-- @return      iterator
Table.kpairs = function (t)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end

  table.sort(a, Table.fullSort)

  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function

    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end

  end

  return iter
end

---
-- @desc        Swaps the keys and values in a given table, i.e.
--              {a = 1, b = 2, c = 3} --> {1 = "a", 2 = "b", 3 = "c"}
--              This will behave unpredictably if given a table where the same
--              value exists in multiple keys (booleans, for instance)
-- @param t     table
-- @return      table
Table.invert = function(t)
  local inv = T{}

  for k, v in pairs(t) do
    inv[v] = k
  end

  return inv
end

---
-- @desc        Searches a table (using ipairs by default), returning the first
--              value and index for which cb(value, key, t) is truthy.
-- @param t     table
-- @param cb    function
-- @option iter iterator
-- @return      value, key | boolean
Table.find = function(t, cb, iter)
  iter = iter or ipairs

  local result
  for k, v in iter(t) do
    result = cb(v, k, t)

    if result then return result, k end
  end

  return false
end

---
-- @desc        Searches a table and returns 'true' if cb(value, key, t) is
--              truthy for any element
-- @param t     table
-- @param cb    function    A function. Should return a boolean.
-- @return      boolean
Table.any = function(t, cb)
  for k, v in pairs(t) do
    if cb(v, k, t) then return true end
  end

  return false
end

---
-- @desc        Searches a table and returns 'true' if cb(value, key, t) is
--              truthy for all elements
-- @param t     table
-- @param cb    function    A function. Should return a boolean.
-- @return      boolean
Table.all = function(t, cb)
  for k, v in pairs(t) do
    if not cb(v, k, t) then return false end
  end

  return true
end

---
-- @desc        Searches a table and returns 'true' if cb(value, key, t) is
--              falsy for all elements
-- @param t     table
-- @param cb    function    A function. Should return a boolean.
-- @return      boolean
Table.none = function(t, cb)
  for k, v in pairs(t) do
    if cb(v, k, t) then return false end
  end

  return true
end

---
-- @desc        Returns the number of elements in a table, counting both indexed
--              and keyed elements
-- @param t     table
-- @return      integer
Table.fullLength = function(t)
  local len = 0
  for _ in pairs(t) do
    len = len + 1
  end

  return len
end

---
-- @desc        Sorts a set of nested tables using a given key, returning the
--              sorted values as a dense table. i.e.:
--              Table.sortByKey({ a = { val = 3 }, b = { val = 1 }, c = { val = 2 } }, "a")
--              --> { { val = 1 }, { val = 2 }, { val = 3 } }
-- @param t     table   A table of tables
-- @param key   any     A key present in all of the tables
-- @return      table
Table.sortByKey = function(t, key)
  local sorted = T{}

  for _, child in pairs(t) do
    sorted[#sorted + 1] = child
  end

  sorted:sort( function(a, b) return a[key] < b[key] end )

  return sorted
end

---
-- @desc        Using 'source' as a base, adds any key/value pairs to t for which
--              it doesn't already have an entry (that is, t[k] == nil)
--              **Mutates the original table**
-- @param t     table
-- @param source  table
-- @return      table     The original table reference
Table.addMissingKeys = function(t, source)
  for k, v in pairs(source) do
    if t[k] == nil then
      if type(v) == "table" then
        t[k] = Table.deepCopy(v)
      else
        t[k] = v
      end
    end
  end

  return t
end

---
-- @desc        Wraps table.sort so it can be used in a method chain
--              **Mutates the original table**
-- @param t     table
-- @param func  function  A sorting function
-- @return      table     The original table reference
Table.chainableSort = function(t, func)
  table.sort(t, func)
  return t
end

---
-- @desc        Merges any number of tables sequentially into a new table
-- @param       table
-- @return      table
Table.join = function(...)
  local out = T{}
  for _, t in ipairs({...}) do
    for _, entry in ipairs(t) do
      out[#out+1] = entry
    end
  end

  return out
end

---
-- @desc        Merges any number of indexed tables alternately into a new table.
--              i.e.:
--              Table.zip({1, 2, 3}, {"a", "b", "c"}, {true, true, true}
--              --> {1, "a", true, 2, "b", true, 3, "c", true}
--              If the tables are of uneven length, any remaining elements will
--              be added at the end
-- @param       table
-- @return      table
Table.zip = function(...)
  local tIn = {...}

  local tOut = T{}

  local nonEmpty = {}
  for k in pairs(tIn) do
    nonEmpty[#nonEmpty+1] = k
  end

  local index = 1
  while (#nonEmpty > 0) do
    local lookingAt = 1
    while (lookingAt <= #nonEmpty) do
      local val = tIn[nonEmpty[lookingAt]][index]

      if val ~= nil then
        tOut[#tOut+1] = val
        lookingAt = lookingAt + 1
      else
        table.remove(nonEmpty, lookingAt)
      end
    end

    index = index + 1
  end

  return tOut
end

return T{Table, T}
