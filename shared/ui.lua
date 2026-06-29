-- WiRe shared UI helpers

local ui = {}

function ui.centerText(target, y, text, fg, bg)
  local oldTerm = term.current()
  if target then term.redirect(target) end
  local w = ({term.getSize()})[1]
  if bg then term.setBackgroundColor(bg) end
  if fg then term.setTextColor(fg) end
  term.setCursorPos(math.max(1, math.floor((w - #text) / 2) + 1), y)
  term.write(text)
  if target then term.redirect(oldTerm) end
end

return ui
