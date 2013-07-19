script_name = "Wrap in {}"
script_description = "Wraps all/selected lines in curly braces"
return aegisub.register_macro(script_name, script_description, function(subs, sel)
  local apply
  apply = function(i, line)
    local text = line.text
    if text and text ~= "" then
      local wrapifnonempty
      wrapifnonempty = function(s)
        if s == "" then
          return s
        else
          return "{" .. s .. "}"
        end
      end
      local stripovr
      stripovr = function(ovr)
        local keepbreak
        keepbreak = function(tag)
          return tag:gsub("\\[^nN].*$", "")
        end
        return wrapifnonempty(ovr:gsub("\\t%s*%((.*)%)", stripovr):gsub("(\\[^\\]+)", keepbreak))
      end
      text = text:gsub("{(.-)}", stripovr):gsub("{%s*}", ""):gsub("{(.*)}", "<%1>"):gsub("^<(.+)>$", "%1")
      line.text = wrapifnonempty(text)
      subs[i] = line
    end
  end
  if #sel > 1 then
    for _index_0 = 1, #sel do
      local i = sel[_index_0]
      apply(i, subs[i])
    end
  else
    for i, s in ipairs(subs) do
      apply(i, s)
    end
  end
  return sel
end)
