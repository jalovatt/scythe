-- NoIndex: true

local Table = {}
setmetatable(Table, {__index = table})

local T = function(t) return setmetatable(t, {__index = Table}) end

-- Iterates over the given table, calling cb(value, key, table) for each element
-- ** Not guaranteed to run in order of the elements' indices **
Table.forEach = function(t, cb)
  for k, v in pairs(t) do
    cb(v, k, t)
  end
end

-- Identical to Table.forEach, but guaranteed to run in numerical order on only
-- the array portion of the given table
Table.orderedForEach = function(t, cb)
  local l = #t

  for i = 1, l do
    cb(t[i], i, t)
  end
end

-- Iterates over the given table, calling cb(value, key, table) for each element
-- and returning a new table with cb's returned values and the original keys
Table.map = function(t, cb)
  local mapped = T{}

  for k, v in pairs(t) do
    mapped[k] = cb(v, k, t)
  end

  return mapped
end

-- Identical to Table.map, but guaranteed to run in numerical order on only the
-- array portion of the given table
Table.orderedMap = function(t, cb)
  local mapped = T{}
  local l = #t

  for i = 1, l do
    mapped[i] = cb(t[i], i, t)
  end

  return mapped
end

-- Returns a new table containing only those elements of the given table for which
-- cb(value, key, table) returns true. ** Not guaranteed to return elements in
-- their original order **
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

-- Identical to Table.filter, but guarantee to run in numerical order on only the
-- array portion of the given table
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

-- Iterates over a given table with the given accumulator (or 0, if not provided),
-- calling cb(accumulator, value, key, table) for each element.
-- ** cb's returned value is passed as the accumulator to the next iteration **
-- ** Not guaranteed to run in numerical order **
Table.reduce = function(t, cb, acc)
  if acc == nil then acc = 0 end

  for k, v in pairs(t) do
    acc = cb(acc, v, k, t)
  end

  return acc
end

-- Identical to Table.reduce, but guarantee to run in numerical order on only the
-- array portion of the given table
Table.orderedReduce = function(t, cb, acc)
  if acc == nil then acc = 0 end

  local l = #t
  for i = 1, l do
    acc = cb(acc, t[i], i, t)
  end

  return acc
end

-- Performs a shallow copy of the given table - that is, only the "top" level of
-- elements is considered. Any tables are copied by reference to the new table.
-- Taken from: http://lua-users.org/wiki/CopyTable
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


-- Performs a deep copy of the given table - any tables are recursively deep-copied
-- to the new table. To keep items from being deep-copied and/or prevent circular
-- references from causing a stack overflow, tables with .__noRecursion will
-- by copied by reference.
-- ** Do not provide 'copies' when calling **
-- Adapted from: http://lua-users.org/wiki/CopyTable
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

-- Returns a string of the table's contents, indented to show nested tables
-- If 't' contains classes, or a lot of nested tables, etc, be wary of using larger
-- values for maxDepth - this function will happily freeze Reaper for ten minutes.
Table.stringify = function (t, maxDepth, currentDepth)
  local ret = {}
  currentDepth = currentDepth or 0

  for n,v in pairs(t) do
    ret[#ret+1] = string.rep("  ", currentDepth) .. tostring(n) .. " = "

    if type(v) == "table" then
      ret[#ret] = ret[#ret] .. "table:"

      if (not maxDepth or currentDepth <= maxDepth) and not v.__noRecursion then
        ret[#ret+1] = Table.stringify(v, maxDepth, currentDepth + 1)
      end
    else
      ret[#ret] = ret[#ret] .. tostring(v)
    end
  end

  return table.concat(ret, "\n")
end


-- Performs a shallow comparison of two tables. Only "top-level" elements are
-- considered; functions and tables are compared by reference.
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

-- Recursively compares the contents of two tables, since Lua doesn't offer it
-- Returns true if all of table a's keys and values match all of table b's.
Table.deepEquals = function (a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return false end

  local seenKeys = {}
  for k1, v1 in pairs(a) do
    local v2 = b[k1]
    if v2 == nil or not Table.deepEquals(v1, v2) then return false end
    seenKeys[k1] = true
  end
  for k2 in pairs(b) do
    if not seenKeys[k2] then return false end
  end

  return true
end


-- 	Sorting function adapted from: http://lua-users.org/wiki/SortedIteration
Table.fullSort = function (op1, op2)

  -- Sort strings that begin with a number as if they were numbers,
  -- i.e. so that 12 > "6 apples"
  if type(op1) == "string" and string.match(op1, "^(%-?%d+)") then
    op1 = tonumber( string.match(op1, "^(%-?%d+)") )
  end
  if type(op2) == "string" and string.match(op2, "^(%-?%d+)") then
    op2 = tonumber( string.match(op2, "^(%-?%d+)") )
  end

  --if op1 == "0" then op1 = 0 end
  --if op2 == "0" then op2 = 0 end
  local type1, type2 = type(op1), type(op2)
  if type1 ~= type2 then --cmp by type
    return type1 < type2
  elseif type1 == "number" and type2 == "number"
      or type1 == "string" and type2 == "string" then
    return op1 < op2 --comp by default
  elseif type1 == "boolean" and type2 == "boolean" then
    return op1 == true
  else
    return tostring(op1) < tostring(op2) --cmp by address
  end

end


--[[	Allows "for x, y in pairs(z) do" in proper alphanumeric order

  Copied from Programming In Lua, 19.3

  Call with f = "full" to use the full sorting function above, or
  use f to provide your own sorting function as per pairs() and ipairs()

]]--
Table.kpairs = function (t, f)
  if f == "full" then
    f = Table.fullSort
  end

  local a = {}
  for n in pairs(t) do table.insert(a, n) end

  table.sort(a, f)

  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function

    i = i + 1

    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end

  end

  return iter
end


-- Accepts a table, and returns a table with the keys and values swapped, i.e.
-- {a = 1, b = 2, c = 3} --> {1 = "a", 2 = "b", 3 = "c"}
-- This will behave unpredictably if given a table where the same value exists
-- over multiple keys
Table.invert = function(t)
  local inv = T{}

  for k, v in pairs(t) do
    inv[v] = k
  end

  return inv
end


-- Looks through a table using ipairs (provide a different iterator function with
-- 'iter'), returning the first value and index for which cb(value, key, table) is
-- truthy.
Table.find = function(t, cb, iter)
  iter = iter or ipairs

  local result
  for k, v in iter(t) do
    result = cb(v, k, t)

    if result then return result, k end
  end
end

-- Looks through a table and returns 'true' if cb(value, key, table) is true for
-- any elements
Table.any = function(t, cb)
  for k, v in pairs(t) do
    if cb(v, k, t) then return true end
  end

  return false
end

-- Returns true if cb(v, k, t) is true for all values in the table
Table.all = function(t, cb)
  for k, v in pairs(t) do
    if not cb(v, k, t) then return false end
  end

  return true
end

-- Returns true if cb(v, k, t) is false for all values in the table
Table.none = function(t, cb)
  for k, v in pairs(t) do
    if cb(v, k, t) then return false end
  end

  return true
end

-- Returns the length of a table, counting both indexed and keyed elements
Table.fullLength = function(t)
  local len = 0
  for _ in pairs(t) do
    len = len + 1
  end

  return len
end


-- Accepts a table of hashes, returning a dense array of the hashes sorted
-- by the given key
Table.sortHashesByKey = function(hashes, key)
  local sorted = T{}

  for _, hash in pairs(hashes) do
    sorted[#sorted + 1] = hash
  end

  sorted:sort( function(a, b) return a[key] < b[key] end )

  return sorted

end


-- Using 'source' as a base, adds any key/value pairs to t for which it doesn't
-- already have an entry (t[k] == nil)
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


-- Just a wrapper so we can chain this
Table.chainableSort = function(t, func)
  table.sort(t, func)
  return t
end

return T{Table, T}
