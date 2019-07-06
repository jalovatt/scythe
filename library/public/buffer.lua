-- NoIndex: true

local Table, T = require("public.table"):unpack()

local Buffer = {}

-- Any assigned buffers will be marked as N = true here
local assignedBuffers = {}

-- When deleting elements, their buffer numbers
-- will be added here for easy access.
local releasedBuffers = T{}

Buffer.get = function (num)
  local ret = {}

  for i = 1, (num or 1) do

    if #releasedBuffers > 0 then

      ret[i] = releasedBuffers:remove()

    else
      for j = 1, 1023 do

        if not assignedBuffers[j] then
          ret[i] = j

          assignedBuffers[j] = true
          goto skip
        end

      end

      error("Unable to find an unused graphics buffer")

      ::skip::
    end

  end

  return (#ret == 1) and ret[1] or ret

end

-- Elements should pass their buffer (or buffer table) to this
-- when being deleted
Buffer.release = function (num)

  if type(num) == "number" then
    releasedBuffers:insert(num)
  else
    for _, v in pairs(num) do
      releasedBuffers:insert(v)
    end
  end

end

return Buffer
