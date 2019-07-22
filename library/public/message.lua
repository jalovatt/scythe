local Message = {}

-- Print arguments to the Reaper console.
Message.Msg = function (...)
  local out = {}
  for _, v in ipairs({...}) do
    out[#out+1] = tostring(v)
  end
  reaper.ShowConsoleMsg(table.concat(out, ", ").."\n")
end

local queuedMessages = {}

Message.queueMsg = function (...)
  local out = {}
  for _, v in ipairs({...}) do
    out[#out+1] = tostring(v)
  end
  queuedMessages[#queuedMessages+1] = table.concat(out, ", ")
end

Message.printQueue = function()
  reaper.ShowConsoleMsg(table.concat(queuedMessages, "\n").."\n")
  queuedMessages = {}
end

return Message
