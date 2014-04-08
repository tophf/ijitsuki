script_name = "Current style -> select/navigate"
script_description = "Selects/navigates between all lines with style equal to current line's style"
aegisub.register_macro("Current style -> select all", script_description, function(subs, sel, act)
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
aegisub.register_macro("Current style -> previous", "", function(subs, sel, act)
  local lookforstyle = subs[act].style
  for i = act - 1, 1, -1 do
    if subs[i].class ~= 'dialogue' then
      return 
    end
    if subs[i].style == lookforstyle then
      return {
        i
      }
    end
  end
end)
aegisub.register_macro("Current style -> next", "", function(subs, sel, act)
  local lookforstyle = subs[act].style
  for i = act + 1, #subs do
    if subs[i].style == lookforstyle then
      return {
        i
      }
    end
  end
end)
aegisub.register_macro("Current style -> first in block", "", function(subs, sel, act)
  local lookforstyle = subs[act].style
  for i = act - 1, 1, -1 do
    if subs[i].class ~= 'dialogue' or subs[i].style ~= lookforstyle then
      return {
        i + 1
      }
    end
  end
end)
return aegisub.register_macro("Current style -> last in block", "", function(subs, sel, act)
  local lookforstyle = subs[act].style
  for i = act + 1, #subs do
    if subs[i].style ~= lookforstyle then
      return {
        i - 1
      }
    end
  end
end)
