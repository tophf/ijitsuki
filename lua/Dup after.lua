script_name = "Dup after"
script_description = "Duplicates and shifts by original duration"
local dup
dup = function(subs, sel)
  return (function()
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #sel do
      local i = sel[_index_0]
      do
        local line = subs[i]
        local duration = line.end_time - line.start_time
        line.start_time = line.start_time + duration
        line.end_time = line.end_time + duration
        local _ = line
        _accum_0[_len_0] = line
      end
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
end
aegisub.register_macro(script_name, script_description, function(subs, sel)
  for i, line in pairs(dup(subs, sel)) do
    subs.insert(sel[i] + i - 1, line)
  end
  local _accum_0 = { }
  local _len_0 = 1
  for k, v in pairs(sel) do
    _accum_0[_len_0] = k + v
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)
return aegisub.register_macro(script_name .. ' and group', script_description .. ' (place the copy in continuous group after the last selected line)', function(subs, sel)
  subs.insert(sel[#sel] + 1, unpack(dup(subs, sel)))
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, #sel do
    _accum_0[_len_0] = sel[#sel] + i
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)
