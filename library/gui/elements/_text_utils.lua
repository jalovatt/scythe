-- luacheck: globals Scythe
local TextUtils = {}

function TextUtils.ctrlchar(self, state, func, ...)

  if state.mouse.cap & 4 == 4 then
    func(self, ... and table.unpack({...}))

    -- Flag to bypass the "clear selection" logic in :ontype()
    return true

  else
    self:insertchar(state.kb.char)
  end

end

function TextUtils.toclipboard(self, cut)

  if self.sel_s and self:SWS_clipboard() then

    local str = self:getselectedtext()
    reaper.CF_SetClipboard(str)
    if cut then self:deleteselection() end

  end

end

function TextUtils.fromclipboard(self)

  if self:SWS_clipboard() then

    local fast_str = reaper.SNM_CreateFastString("")
    local str = reaper.CF_GetClipboardBig(fast_str)
    reaper.SNM_DeleteFastString(fast_str)

    self:insertstring(str, true)

  end

end

function TextUtils.undo(self)

	if #self.undo_states == 0 then return end
	table.insert(self.redo_states, self:geteditorstate() )
	local state = table.remove(self.undo_states)

  self.retval = state.retval
	self.caret = state.caret

	self:windowtocaret()

end

function TextUtils.storeundostate(self)

  table.insert(self.undo_states, self:geteditorstate() )
	if #self.undo_states > self.undo_limit then table.remove(self.undo_states, 1) end
	self.redo_states = {}

end

-- See if we have a new-enough version of SWS for the clipboard functions
-- (v2.9.7 or greater)
function TextUtils.SWS_clipboard(self)

	if Scythe.SWS_exists then
		return true
	else

		reaper.ShowMessageBox(
      "Clipboard functions require the SWS extension, v2.9.7 or newer."..
      "\n\nDownload the latest version at http://www.sws-extension.org/index.php",

      "Sorry!",
      0
    )
		return false

	end

end

return TextUtils
