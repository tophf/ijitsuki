script_name = 'Blame'
script_description = table.concat({
  'Marks lines exceeding specified limits:',
  'min/max duration, CPS, line count, overlaps, missing styles.'
}, ' ')
require('utils')
local re = require('aegisub.re')
local _list_0 = {
  {
    -1,
    'previous'
  },
  {
    1,
    'next'
  }
}
for _index_0 = 1, #_list_0 do
  local v = _list_0[_index_0]
  local goto = 'Go to ' .. v[2]
  aegisub.register_macro(script_name .. ': ' .. goto, goto .. ' blemished line', function(subs, sel, act)
    local step = v[1]
    local dest
    if step < 0 then
      dest = 1
    else
      dest = #subs
    end
    local is_blemished = re.compile(table.concat({
      [[(?:^|\s)]],
      '(?:',
      [[(?:short|long)[\d.]+s]],
      [[|\d+(?:cps|lines)]],
      [[|ovr\d+?|nostyle]],
      ')',
      [[(?:\s|$)]]
    }, ''))
    for i = act + step, dest, step do
      do
        local line = subs[i]
        if line.class == 'dialogue' then
          if not line.comment then
            if is_blemished:match(line.effect) then
              return {
                i
              }
            end
          end
        end
      end
    end
    return aegisub.cancel()
  end)
end
return aegisub.register_macro(script_name, script_description, function(subs, sel)
  local SAVE, DEFAULTS, SIGNS, SIGNSre, METRICS, execute, blameline, should_ignore_signs, set_style, calc_numlines, max, cfgserialize, cfgdeserialize, cfgread, cfgwrite, init
  local cfg, cfgsource, btns, dlg, userconfigpath
  local playres, styles, cfglineindices, dialogfirst, overlap_end, check_max_lines_enabled
  SAVE = {
    no = "Apply and don't save settings",
    script = "Apply and save settings in script",
    user = "Apply and save settings in user config",
    removeonly = "Only remove saved settings from script"
  }
  DEFAULTS = {
    check_min_duration = true,
    min_duration = 1.0,
    ignore_short_if_cps_ok = true,
    check_max_duration = true,
    max_duration = 10.0,
    check_max_lines = true,
    max_lines = 2,
    check_max_chars_per_sec = true,
    max_chars_per_sec = 25,
    check_missing_styles = true,
    check_overlaps = true,
    list_only_first_overlap = true,
    ignore_signs = true,
    selected_only = false,
    select_errors = true,
    list_errors = true,
    log_errors = false,
    save = SAVE.user
  }
  SIGNS = table.concat({
    [[\{.*?\\(]],
    'pos|move|an|a|org|',
    'frx|fry|frz|',
    'fax|fay|',
    'k|kf|ko|K|',
    't',
    [[)[^a-zA-Z].*?\}]]
  }, '')
  SIGNSre = re.compile(SIGNS)
  METRICS = { }
  do
    local _with_0 = METRICS
    _with_0.q2_re = re.compile([[\{.*?\\q2.*?\}]])
    _with_0.tag = {
      fn = 'fontname',
      r = '',
      fsp = 'spacing',
      fs = 'fontsize',
      fscx = 'scale_x'
    }
    local alltags = table.concat((function()
      local _accum_0 = { }
      local _len_0 = 1
      for k, v in pairs(_with_0.tag) do
        _accum_0[_len_0] = k
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)(), '|')
    local allvalues = table.concat({
      [[(?<=fn)(?:[^\\}]*|\\|\s*$)|]],
      [[(?<=r)(?:[^\\}]*|\\|\s*$)|]],
      [[(?:[\s\\]+|-?[\d.]+|\s*$)]]
    }, '')
    local tagexpr = [[\\((?:]] .. alltags .. ')(?:' .. allvalues .. '))'
    _with_0.ovr_re = re.compile([[\{.*?]] .. tagexpr .. [[.*?\}]])
    _with_0.tag_re = re.compile(tagexpr)
    _with_0.tagparts_re = re.compile('(' .. alltags .. ')(' .. allvalues .. ')')
  end
  execute = function()
    cfgread()
    init()
    local btn
    btn, cfg = aegisub.dialog.display(dlg, {
      btns.ok,
      btns.cancel
    }, btns)
    if not btn or btn == btns.cancel then
      aegisub.cancel()
    end
    cfgwrite()
    local lines
    if cfg.selected_only then
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #sel do
          local _continue_0 = false
          repeat
            local i = sel[_index_0]
            if subs[i].comment then
              _continue_0 = true
              break
            end
            local _value_0 = {
              i = i,
              line = subs[i]
            }
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        lines = _accum_0
      end
    else
      do
        local _accum_0 = { }
        local _len_0 = 1
        for i, line in ipairs(subs) do
          local _continue_0 = false
          repeat
            if line.class ~= 'dialogue' or line.comment then
              _continue_0 = true
              break
            end
            local _value_0 = {
              i = i,
              line = line
            }
            _accum_0[_len_0] = _value_0
            _len_0 = _len_0 + 1
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
        lines = _accum_0
      end
    end
    if cfg.check_overlaps then
      overlap_end = 0
      table.sort(lines, function(a, b)
        local a_t, b_t = a.line.start_time, b.line.start_time
        return a_t < b_t or (a_t == b_t and a.i < b.i)
      end)
    end
    local video_loaded = aegisub.frame_from_ms(0)
    check_max_lines_enabled = cfg.check_max_lines and playres.x > 0 and video_loaded
    local tosel
    do
      local _accum_0 = { }
      local _len_0 = 1
      for num, v in ipairs(lines) do
        if blameline(num, v, lines) then
          _accum_0[_len_0] = v.i
          _len_0 = _len_0 + 1
        end
      end
      tosel = _accum_0
    end
    if cfg.log_errors or not (cfg.list_errors or cfg.select_errors) then
      aegisub.log('\n%d lines blamed.\n', #tosel)
    end
    if cfg.check_max_lines and not check_max_lines_enabled then
      local err1
      if not (video_loaded) then
        err1 = "load video file"
      end
      local err2
      if not (playres.x > 0) then
        err2 = "specify correct PlayRes in script's properties!"
      end
      aegisub.log('%s. %s%s%s%s.', "Max screen lines checking not performed", "Please, ", err1 or "", (function()
        if err1 and err2 then
          return " and "
        else
          return "", err2 or ""
        end
      end)())
    end
    aegisub.progress.set(100)
    if cfg.select_errors then
      return tosel
    end
  end
  blameline = function(num, v, lines)
    local msg = ''
    local index, line
    index, line = v.i, v.line
    do
      local duration = (line.end_time - line.start_time) / 1000
      local textonly = line.text:gsub('{.-}', ''):gsub('\\h', ' ')
      local length = textonly:gsub('\\N', ''):gsub("[ ,.-!?&():;/<>|%%$+=_'\"]", ''):len()
      local cps
      if duration == 0 then
        cps = 0
      else
        cps = length / duration
      end
      local style = styles[line.style] or styles['Default'] or styles['*Default']
      if not should_ignore_signs(line) then
        if cfg.check_min_duration and duration < cfg.min_duration then
          if not cfg.ignore_short_if_cps_ok or math.floor(cps) > cfg.max_chars_per_sec then
            msg = (' short%gs'):format(duration)
          end
        end
        if cfg.check_max_duration and duration > cfg.max_duration then
          msg = msg .. (' long%gs'):format(duration)
        end
        if cfg.check_max_chars_per_sec and math.floor(cps) > cfg.max_chars_per_sec then
          msg = msg .. (' %dcps'):format(cps)
        end
        if check_max_lines_enabled and style then
          local numlines = 0
          if METRICS.q2_re:match(line.text) then
            local s = line.text:gsub('\\N%s*{.-}%s*', '')
            numlines = (#s - s:gsub('\\N', ''):len()) / 2 + 1
          else
            local available_width = playres.x
            available_width = available_width - (function()
              if line.margin_r > 0 then
                return line.margin_r
              else
                return style.margin_r
              end
            end)()
            available_width = available_width - (function()
              if line.margin_l > 0 then
                return line.margin_l
              else
                return style.margin_l
              end
            end)()
            available_width = available_width * (playres.realx / playres.x)
            local ovrstyle = table.copy(style)
            for subline in line.text:gsub('\\N', '\n'):split_iter('\n') do
              local prevspanstart = 1
              subline = subline:trim()
              for ovr, ovrstart, ovrend in METRICS.ovr_re:gfind(subline) do
                numlines = numlines + calc_numlines(subline:sub(prevspanstart, ovrstart - 1), ovrstyle, available_width)
                prevspanstart = ovrend + 1
                local tagpos = 1
                while true do
                  local tag = METRICS.tag_re:match(ovr, tagpos)
                  if not (tag) then
                    break
                  end
                  tagpos = tag[2].last + 1
                  local tagparts = METRICS.tagparts_re:match(tag[2].str)
                  tag.name, tag.value = tagparts[2].str, tagparts[3].str:trim()
                  if tag.name == 'r' then
                    ovrstyle = table.copy(styles[tag.value] or style)
                  else
                    set_style(ovrstyle, tag, style)
                  end
                end
              end
              numlines = numlines + calc_numlines(subline:sub(prevspanstart), ovrstyle, available_width)
              numlines = math.floor(numlines + 0.9999999999)
            end
          end
          if numlines > cfg.max_lines then
            msg = msg .. (' %dlines'):format(numlines)
          end
        end
        if cfg.check_overlaps then
          if line.start_time < overlap_end then
            if not (cfg.list_only_first_overlap) then
              msg = msg .. ' ovr'
            end
          else
            overlap_end = line.end_time
            local cnt = 0
            for j = num + 1, #lines do
              local L = lines[j].line
              if L.start_time >= overlap_end then
                break
              end
              if not should_ignore_signs(L) then
                cnt = cnt + 1
              end
            end
            if cnt > 0 then
              msg = msg .. (' ovr' .. cnt)
            end
          end
        end
      end
      if cfg.check_missing_styles then
        local missing = styles[line.style] == nil
        for ovr in line.text:gmatch('{(.*\\r.*)}') do
          for ovrstyle in ovr:gmatch('\\r([^}\\]+)') do
            if not (styles[ovrstyle]) then
              missing = true
            end
          end
        end
        if missing then
          msg = msg .. ' nostyle'
        end
      end
      msg = msg:sub(2)
      if (msg ~= '' or line.effect ~= '') and msg ~= line.effect and cfg.list_errors then
        line.effect = msg
        subs[index] = line
      end
      if not cfg.list_errors or cfg.log_errors then
        aegisub.progress.set(num / #lines * 100)
        if msg ~= '' then
          aegisub.log('%d: %s\t%s%s\n', index - dialogfirst + 1, msg, textonly:sub(1, 20), ((function()
            if #textonly > 20 then
              return '...'
            else
              return ''
            end
          end)()))
        end
      end
    end
    return msg ~= ''
  end
  should_ignore_signs = function(line)
    return cfg.ignore_signs and SIGNSre:match(line.text)
  end
  set_style = function(style, tag, fallbackstyle)
    local field = METRICS.tag[tag.name]
    if tag.value ~= '' then
      style[field] = tag.value
    else
      style[field] = fallbackstyle[field]
    end
  end
  calc_numlines = function(text, style, available_width)
    local ok, width = pcall(aegisub.text_extents, style, text:gsub('{.-}', ''):gsub('\\h', ' '))
    if not (ok) then
      return 0
    end
    return width / available_width
  end
  max = function(a, b)
    if a > b then
      return a
    else
      return b
    end
  end
  string.split_iter = function(self, sepcharclass)
    return self:gmatch('([^' .. sepcharclass .. ']+)')
  end
  string.trim = function(self)
    return self:gsub('^%s+', ''):gsub('%s+$', '')
  end
  string.val = function(self)
    local s = self:trim():lower()
    if s == 'true' then
      return true
    end
    if s == 'false' then
      return false
    end
    if s:match('^%-?[0-9.]+$') then
      return tonumber(s)
    end
    return self
  end
  cfgserialize = function(t, sep)
    if not (t) then
      return ''
    end
    return table.concat((function()
      local _accum_0 = { }
      local _len_0 = 1
      for k, v in pairs(t) do
        _accum_0[_len_0] = k .. ':' .. tostring(v)
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)(), sep)
  end
  cfgdeserialize = function(s)
    local kv2pair
    kv2pair = function(kv)
      return unpack((function()
        local _accum_0 = { }
        local _len_0 = 1
        for i in kv:split_iter(':') do
          _accum_0[_len_0] = i:val()
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
    end
    local _tbl_0 = { }
    for kv in s:split_iter(',\n\r') do
      local _key_0, _val_0 = kv2pair(kv)
      _tbl_0[_key_0] = _val_0
    end
    return _tbl_0
  end
  cfgread = function()
    local userconfig = '?user/' .. script_name .. '.conf'
    userconfigpath = aegisub.decode_path(userconfig)
    if not cfg then
      local f = io.open(userconfigpath, 'r')
      if f then
        local ok, _cfg = pcall(cfgdeserialize, f:read('*all'))
        if ok and _cfg.save then
          cfgsource = userconfig
          cfg = _cfg
        end
        f:close()
      end
    end
    if not cfg then
      cfgsource = 'defaults'
      cfg = table.copy(DEFAULTS)
    else
      local cfgdef = false
      for k, v in pairs(DEFAULTS) do
        if cfg[k] == nil then
          cfg[k], cfgdef = v, true
        end
      end
      if cfgdef then
        cfgsource = cfgsource .. ' + defaults'
      end
    end
  end
  cfgwrite = function()
    local _exp_0 = cfg.save
    if SAVE.script == _exp_0 then
      if #cfglineindices > 0 then
        subs.delete(unpack(cfglineindices))
      end
      return subs.append({
        class = 'info',
        section = 'Script Info',
        key = script_name,
        value = cfgserialize(cfg, ', ')
      })
    elseif SAVE.user == _exp_0 then
      local f = io.open(userconfigpath, 'w')
      if not f then
        return aegisub.log('Error writing ' .. userconfigpath)
      else
        f:write(cfgserialize(cfg, '\n'))
        return f:close()
      end
    elseif SAVE.removeonly == _exp_0 then
      if #cfglineindices > 0 then
        subs.delete(unpack(cfglineindices))
      end
      return aegisub.cancel()
    end
  end
  init = function()
    playres = {
      x = 0,
      y = 0,
      realx = 0
    }
    styles = { }
    cfglineindices = { }
    dialogfirst = 0
    for i, s in ipairs(subs) do
      local _exp_0 = s.class
      if 'info' == _exp_0 then
        local kl = s.key:lower()
        if kl == 'playresx' or kl == 'playresy' then
          if s.value:match('^%s*%d+%s*$') then
            playres[kl:sub(#kl)] = tonumber(s.value)
          end
        elseif s.key == script_name then
          table.insert(cfglineindices, i)
          local ok, _cfg = pcall(cfgdeserialize, s.value)
          if ok and _cfg.save then
            cfg, cfgsource = _cfg, 'script'
          end
        end
      elseif 'style' == _exp_0 then
        styles[s.name] = s
      elseif 'dialogue' == _exp_0 then
        dialogfirst = i
        break
      end
    end
    if aegisub.video_size() then
      local w, h, ar, artype = aegisub.video_size()
      playres.realx = math.floor(playres.y / h * w)
    end
    btns = {
      ok = '&Go',
      cancel = '&Cancel'
    }
    do
      SAVE.list = {
        SAVE.no,
        SAVE.script,
        SAVE.user,
        SAVE.removeonly
      }
    end
    dlg = {
      {
        'checkbox',
        0,
        0,
        7,
        1,
        label = 'Mi&n duration, seconds:',
        name = 'check_min_duration',
        value = cfg.check_min_duration
      },
      {
        'floatedit',
        7,
        0,
        2,
        1,
        name = 'min_duration',
        value = cfg.min_duration,
        min = 0,
        max = 10,
        step = 0.1
      },
      {
        'checkbox',
        0,
        1,
        9,
        1,
        label = '&Ignore if CPS is ok',
        name = 'ignore_short_if_cps_ok',
        value = cfg.ignore_short_if_cps_ok
      },
      {
        'checkbox',
        0,
        2,
        7,
        1,
        label = 'Ma&x duration, seconds:',
        name = 'check_max_duration',
        value = cfg.check_max_duration
      },
      {
        'floatedit',
        7,
        2,
        2,
        1,
        name = 'max_duration',
        value = cfg.max_duration,
        min = 0,
        max = 100,
        step = 1
      },
      {
        'checkbox',
        0,
        3,
        7,
        1,
        label = 'Max screen &lines per subtitle',
        name = 'check_max_lines',
        value = cfg.check_max_lines,
        hint = 'Requires 1) PlayRes in script header 2) all used fonts installed'
      },
      {
        'intedit',
        7,
        3,
        2,
        1,
        name = 'max_lines',
        value = cfg.max_lines,
        min = 1,
        max = 10
      },
      {
        'checkbox',
        0,
        4,
        7,
        1,
        label = 'Max c&haracters per second',
        name = 'check_max_chars_per_sec',
        value = cfg.check_max_chars_per_sec
      },
      {
        'intedit',
        7,
        4,
        2,
        1,
        name = 'max_chars_per_sec',
        value = cfg.max_chars_per_sec,
        min = 1,
        max = 100
      },
      {
        'checkbox',
        0,
        5,
        3,
        1,
        label = '&Overlaps:',
        name = 'check_overlaps',
        value = cfg.check_overlaps
      },
      {
        'checkbox',
        3,
        5,
        5,
        1,
        label = '...report only the &first in group',
        name = 'list_only_first_overlap',
        value = cfg.list_only_first_overlap
      },
      {
        'checkbox',
        0,
        6,
        9,
        1,
        label = 'Ignore &ALL RULES ABOVE on signs',
        name = 'ignore_signs',
        value = cfg.ignore_signs,
        hint = SIGNS
      },
      {
        'checkbox',
        0,
        8,
        9,
        1,
        label = '&Missing style definitions',
        name = 'check_missing_styles',
        value = cfg.check_missing_styles
      },
      {
        'checkbox',
        0,
        10,
        3,
        1,
        label = '&Select',
        name = 'select_errors',
        value = cfg.select_errors
      },
      {
        'checkbox',
        3,
        10,
        3,
        1,
        label = '&Report to <Effect>',
        name = 'list_errors',
        value = cfg.list_errors
      },
      {
        'checkbox',
        7,
        10,
        1,
        1,
        label = 'Sho&w in log',
        name = 'log_errors',
        value = cfg.log_errors,
        hint = '...forced when both Select and Report are disabled'
      },
      {
        'checkbox',
        0,
        11,
        9,
        1,
        label = 'Process s&elected lines only',
        name = 'selected_only',
        value = cfg.selected_only
      },
      {
        'dropdown',
        0,
        12,
        9,
        1,
        name = 'save',
        items = SAVE.list,
        value = cfg.save
      },
      {
        'label',
        0,
        13,
        9,
        2,
        label = 'Config: ' .. cfgsource
      }
    }
    for _index_0 = 1, #dlg do
      local c = dlg[_index_0]
      for i, k in ipairs({
        'class',
        'x',
        'y',
        'width',
        'height'
      }) do
        c[k] = c[i]
      end
    end
  end
  return execute()
end)
