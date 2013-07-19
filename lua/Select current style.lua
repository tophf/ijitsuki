script_name = "Select current style"
script_description = "Selects all lines with style equal to current line's style"
return aegisub.register_macro(script_name, script_description, function(subs, sel, act)
  local lookforstyle = subs[act].style
  if #sel > 1 then
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #sel do
      local i = sel[_index_0]
      if subs[i].style == lookforstyle then
        _accum_0[_len_0] = i
        _len_0 = _len_0 + 1
      end
    end
    return _accum_0
  else
    local _accum_0 = { }
    local _len_0 = 1
    for k, s in ipairs(subs) do
      if s.style == lookforstyle then
        _accum_0[_len_0] = k
        _len_0 = _len_0 + 1
      end
    end
    return _accum_0
  end
end)
