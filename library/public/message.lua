local Message = {}

-- Print arguments to the Reaper console.
Message.Msg = function (...)
  local out = {}
  for _, v in ipairs({...}) do
    out[#out+1] = tostring(v)
  end
  reaper.ShowConsoleMsg(table.concat(out, ", ").."\n")
end

return Message
