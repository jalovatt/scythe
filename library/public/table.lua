local Table = {}
setmetatable(Table, {__index = table})

local T = function(t) return setmetatable(t, {__index = Table}) end

Table.forEach = function(t, cb)
  for k, v in pairs(t) do
    cb(v, k, t)
  end
end

Table.orderedForEach = function(t, cb)
  local l = #t

  for i = 1, l do
    cb(t[i], i, t)
  end
end

Table.map = function(t, cb)
  local mapped = T{}

  for k, v in pairs(t) do
    mapped[k] = cb(v, k, t)
  end

  return mapped
end

Table.orderedMap = function(t, cb)
  local mapped = T{}
  local l = #t

  for i = 1, l do
    mapped[i] = cb(t[i], i, t)
  end

  return mapped
end

Table.filter = function(t, cb)
  local filtered, l = T{}, 0

  for k, v in pairs(t) do
    if cb(v, k, t) then
      filtered[l] = v
      l = l + 1
    end
  end

  return filtered
end

Table.orderedFilter = function(t, cb)
  local filtered, fl = T{}, 0
  local l = #t

  for i = 1, l do
    if cb(t[i], i, t) then
      filtered[fl] = t[i]
      fl = fl + 1
    end
  end

  return filtered
end

Table.reduce = function(t, cb, acc)
  if acc == nil then acc = 0 end

  for k, v in pairs(t) do
    acc = cb(acc, v, k, t)
  end

  return acc
end

Table.orderedReduce = function(t, cb, acc)
  if acc == nil then acc = 0 end

  local l = #t
  for i = 1, l do
    acc = cb(acc, t[i], i, t)
  end

  return acc
end

Table.copy = function (source, base)
  if type(source) ~= "table" then return source end

  local meta = getmetatable(source)
  local new = base or {}
  for k, v in pairs(source) do
      if type(v) == "table" then
          if base then
              new[k] = Table.copy(v, base[k])
          else
              new[k] = Table.copy(v, nil)
          end
      else
          if not base or (base and new[k] == nil) then
              new[k] = v
          end
      end
  end
  setmetatable(new, meta)

  return new
end

-- Returns a string of the table's contents, indented to show nested tables
-- If 't' contains classes, or a lot of nested tables, etc, be wary of using larger
-- values for max_depth - this function will happily freeze Reaper for ten minutes.
Table.stringify = function (t, max_depth, cur_depth)
  local ret = {}
  local n,v
  cur_depth = cur_depth or 0

  for n,v in pairs(t) do
              ret[#ret+1] = string.rep("  ", cur_depth) .. n .. " = "

              if type(v) == "table" then
                  ret[#ret] = ret[#ret] .. "table:"

                  if not max_depth or cur_depth <= max_depth then
                      ret[#ret+1] = Table.stringify(v, max_depth, cur_depth + 1)
                  end
              else
                  ret[#ret] = ret[#ret] .. tostring(v)
              end
  end

  return table.concat(ret, "\n")
end


-- Recursively compares the contents of two tables, since Lua doesn't offer it
-- Returns true if all of table a's keys and values match all of table b's.
Table.deepEquals = function (a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return false end

  local key_exists = {}
  for k1, v1 in pairs(a) do
      local v2 = b[k1]
      if v2 == nil or not Table.compare(v1, v2) then return false end
      key_exists[k1] = true
  end
  for k2, v2 in pairs(b) do
      if not key_exists[k2] then return false end
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


-- Looks through a table using ipairs (specify a different function with 'iter') and returns
-- the first value for which cb(value) is truthy.
Table.find = function(t, cb, iter)
  iter = iter or ipairs

  local result
  for k, v in iter(t) do
    result = cb(v)

    if result then return result end
  end
end

Table.any = function(t, cb)
  for k, v in pairs(t) do
    if cb(v, k, t) then return true end
  end

  return true
end

-- Returns true if cb(v, k, t) is truthy for all values in the table
Table.all = function(t, cb)
  for k, v in pairs(t) do
    if not cb(v, k, t) then return false end
  end

  return true
end

-- Returns true if cb(v, k, t) is falsy for all values in the table
Table.none = function(t, cb)
  for k, v in pairs(t) do
    if cb(v, k, t) then return false end
  end

  return true
end

-- Returns the length of a table, counting both indexed and keyed elements
Table.length = function(t)
  local len = 0
  for k in pairs(t) do
      len = len + 1
  end

  return len
end

return T{Table, T}
