local Buffer = {}

-- Any used buffers will be marked as True here
local usedBuffers = {}

-- When deleting elements, their buffer numbers
-- will be added here for easy access.
local releasedBuffers = {}

Buffer.get = function (num)
    local ret = {}
    --local prev

    for i = 1, (num or 1) do

        if #releasedBuffers > 0 then

            ret[i] = table.remove(releasedBuffers)

        else
            for j = 1, 1023 do
            --for j = (not prev and 1023 or prev - 1), 0, -1 do

                if not usedBuffers[j] then
                    ret[i] = j

                    usedBuffers[j] = true
                    goto skip
                end

            end

            -- Something bad happened, probably my fault
            GUI.error_message = "Couldn't get a new graphics buffer - " ..
              "all of them are in use"

            ::skip::
        end

    end

    return (#ret == 1) and ret[1] or ret

end

-- Elements should pass their buffer (or buffer table) to this
-- when being deleted
Buffer.release = function (num)

    if type(num) == "number" then
        table.insert(releasedBuffers, num)
    else
        for _, v in pairs(num) do
            table.insert(releasedBuffers, v)
        end
    end

end

return Buffer
