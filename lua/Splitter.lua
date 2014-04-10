script_name = 'Splitter'
script_description = 'Splits lines'
aegisub.register_macro('Split by \\N', '..and trim spaces/hyphens at start', function(subs, sel)
  local offs = 0
  for i, j in ipairs(sel) do
    local _continue_0 = false
    repeat
      j = j + offs
      do
        local line = subs[j]
        if not (line.text:find('\\N')) then
          _continue_0 = true
          break
        end
        local txt = line.text
        local chars = txt:gsub('\\N', ''):len()
        local t1, t2 = line.start_time, line.end_time
        local dur = t2 - t1
        subs.delete(j)
        while true do
          local pos = txt:find('\\N') or (txt:len() + 1)
          line.text = txt:sub(1, pos - 1):gsub('^%s*[-–—]*%s*', ''):gsub('%s*$', '')
          txt = txt:sub(pos + 2)
          line.start_time = t1
          if txt == '' then
            line.end_time = t2
          else
            line.end_time = t1 + line.text:len() / chars * dur
          end
          subs.insert(j, line)
          j = j + 1
          offs = offs + 1
          t1 = line.end_time
          if txt == '' then
            break
          end
        end
        offs = offs - 1
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
end)
aegisub.register_macro('Split 1 frame', 'Splits selected lines after 1st frame', function(subs, sel, active)
  if not aegisub.frame_from_ms(0) then
    aegisub.log('Load video first!')
    aegisub.cancel()
  end
  for i = #sel, 1, -1 do
    local j = sel[i]
    local l = subs[j]
    if l.class == 'dialogue' then
      local t_nextframe = aegisub.ms_from_frame(aegisub.frame_from_ms(l.start_time) + 1)
      local t_end0 = l.end_time
      l.end_time = t_nextframe
      subs.insert(j, l)
      l.start_time, l.end_time = t_nextframe, t_end0
      subs[j + 1] = l
    end
  end
  return sel
end)
return aegisub.register_macro('Split 1 frame on chapters', 'Splits 1st frame on lines starting at chapter mark', function(subs, sel, active)
  if not aegisub.frame_from_ms(0) then
    aegisub.log('Load video first!')
    aegisub.cancel()
  end
  local fn = aegisub.dialog.open('Chapter file', '', '', 'All Files (*)|*|xml chapters (.xml)|*.xml|simple OGG chapters (.txt)|*.txt')
  if not fn then
    aegisub.cancel()
  end
  local file = io.open(fn)
  if not file then
    aegisub.cancel()
  end
  local pat
  if fn:lower():find('%.xml$') then
    pat = '<ChapterTimeStart>'
  else
    pat = 'CHAPTER%d+%s-='
  end
  pat = pat .. '%s-(%d+:%d+:%d+%.?%d?%d?%d?)'
  local inject_i
  inject_i = function(i, line)
    if line == nil then
      line = subs[i]
    end
    line.i = i
    return line
  end
  local sorted
  do
    local _accum_0 = { }
    local _len_0 = 1
    for i, line in ipairs(subs) do
      if line.class == 'dialogue' then
        _accum_0[_len_0] = inject_i(i, line)
        _len_0 = _len_0 + 1
      end
    end
    sorted = _accum_0
  end
  table.sort(sorted, function(a, b)
    return a.start_time < b.start_time or (a.start_time == b.start_time and a.i < b.i)
  end)
  local to_split = { }
  for s in file:lines() do
    local _continue_0 = false
    repeat
      local time = s:match(pat)
      if not time then
        _continue_0 = true
        break
      end
      aegisub.log('Checking ' .. time .. '\n')
      local h, m, ss
      h, m, s, ss = unpack((function()
        local _accum_0 = { }
        local _len_0 = 1
        for v in time:gmatch('(%d+)') do
          _accum_0[_len_0] = v
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
      local chap_ms = (h * 3600 + m * 60 + s) * 1000 + (ss or 0)
      local f = aegisub.frame_from_ms(chap_ms)
      local a, b = 1, #sorted
      while b - a > 1 do
        local c = math.floor((a + b) / 2)
        local cf = aegisub.frame_from_ms(sorted[c].start_time)
        if cf < f then
          a = c
        elseif cf > f then
          b = c
        else
          while c > 1 and cf == aegisub.frame_from_ms(sorted[c - 1].start_time) do
            c = c - 1
          end
          while c <= #sorted and cf == aegisub.frame_from_ms(sorted[c].start_time) do
            local L = sorted[c]
            if aegisub.frame_from_ms(L.end_time) - 1 > f then
              L.log = '\t' .. time .. '\t' .. L.text:sub(1, 20) .. (#L.text > 20 and '...' or '')
              table.insert(to_split, L)
            end
            c = c + 1
          end
          break
        end
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  io.close(file)
  table.sort(to_split, function(a, b)
    return a.i > b.i
  end)
  for _index_0 = 1, #to_split do
    local line = to_split[_index_0]
    local nextframetime = aegisub.ms_from_frame(aegisub.frame_from_ms(line.start_time) + 1)
    local origendtime = line.end_time
    line.end_time = nextframetime
    subs.insert(line.i, line)
    line.start_time, line.end_time = nextframetime, origendtime
    subs[line.i + 1] = line
  end
  aegisub.log('\nChapters split: ' .. #to_split .. '\n')
  aegisub.log(table.concat((function()
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #to_split do
      local L = to_split[_index_0]
      _accum_0[_len_0] = L.log
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)(), '\n'))
  local _accum_0 = { }
  local _len_0 = 1
  for k, L in pairs(to_split) do
    _accum_0[_len_0] = L.i + k - 1
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)
