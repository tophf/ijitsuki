script_name = 'Blame'
script_description = 'Marks lines exceeding specified limits: min/max duration, CPS, screen line count'
require("utils")
return aegisub.register_macro(script_name, script_description, function(subs, sel)
  local SAVE, DEFAULTS, blameline, max, cfgserialize, cfgdeserialize, playresX, styles, cfglineindices, firstdialogueline, userconfig, userconfigpath, btns, dlg, btn, cfg, log_only, tosel
  SAVE = {
    no = "Apply and don't save settings",
    script = "Apply and save settings in script",
    user = "Apply and save settings in user config",
    remove = "Only remove saved settings from script"
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
    selected_only = false,
    select_errors = true,
    list_errors = true,
    save = SAVE.script
  }
  blameline = function(i, line, cfg)
    local msg = ''
    do
      if line.class ~= 'dialogue' or line.comment then
        return false
      end
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
      if cfg.check_max_lines and style and playresX > 0 then
        local screen_estate_x = playresX - max(line.margin_r, style.margin_r) - max(line.margin_l, style.margin_l)
        local lines = 0
        for span in textonly:gsub('\\N', '\n'):split_iter('\n') do
          lines = lines + (({
            aegisub.text_extents(style, span)
          })[1] / screen_estate_x)
          if lines - math.floor(lines) > 0 then
            lines = math.floor(lines) + 1
          end
        end
        if lines > cfg.max_lines then
          msg = msg .. (' %dlines'):format(lines)
        end
      end
      if cfg.check_missing_styles then
        local missing = styles[line.style] == nil
        for ovr in line.text:gmatch("{(.*\\r.*)}") do
          for ovrstyle in ovr:gmatch("\\r([^}\\]+)") do
            if not styles[ovrstyle] then
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
        subs[i] = line
      end
      if log_only then
        if msg ~= '' then
          aegisub.log('%d: %s\t%s%s\n', i - firstdialogueline, msg, textonly:sub(1, 20), ((function()
            if #textonly > 20 then
              return '...'
            else
              return ''
            end
          end)()))
        end
        aegisub.progress.set(i / #subs * 100)
      end
    end
    return msg ~= ''
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
    return self == 'true' and (self == 'true' or self == 'false') or tonumber(self) and self:match('^%s*[0-9.]+%s*$') or self
  end
  cfgserialize = function(t, sep)
    if sep == nil then
      sep = ', '
    end
    if t then
      return table.concat((function()
        local _accum_0 = { }
        local _len_0 = 1
        for k, v in pairs(t) do
          _accum_0[_len_0] = k .. ':' .. tostring(v)
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)(), sep)
    else
      return ''
    end
  end
  cfgdeserialize = function(s)
    local _tbl_0 = { }
    for kv in s:split_iter(',\n\r') do
      local _key_0, _val_0 = unpack((function()
        local _accum_0 = { }
        local _len_0 = 1
        for i in kv:split_iter(':') do
          _accum_0[_len_0] = i:trim():val()
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
      _tbl_0[_key_0] = _val_0
    end
    return _tbl_0
  end
  playresX = 0
  styles = { }
  cfglineindices = { }
  firstdialogueline = 0
  local cfg, cfgsource
  for i, s in ipairs(subs) do
    local _exp_0 = s.class
    if 'info' == _exp_0 then
      if s.key == 'PlayResX' and s.value:match('^%s*%d+%s*$') then
        playresX = tonumber(s.value)
      end
      if s.key == script_name then
        table.insert(cfglineindices, i)
        local ok, _cfg = pcall(cfgdeserialize, s.value)
        if ok and _cfg.save then
          cfg, cfgsource = _cfg, 'script'
        end
      end
    elseif 'style' == _exp_0 then
      styles[s.name] = s
    elseif 'dialogue' == _exp_0 then
      firstdialogueline = i
      break
    end
  end
  userconfig = '?user/' .. script_name .. '.conf'
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
  btns = {
    ok = '&Go',
    cancel = '&Cancel'
  }
  do
    local _with_0 = SAVE
    _with_0.list = {
      _with_0.no,
      _with_0.script,
      _with_0.user,
      _with_0.remove
    }
  end
  dlg = {
    {
      'checkbox',
      0,
      0,
      3,
      1,
      label = 'Min duration, seconds:',
      name = 'check_min_duration',
      value = cfg.check_min_duration
    },
    {
      'floatedit',
      3,
      0,
      1,
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
      4,
      1,
      label = 'Ignore min duration if CPS is ok',
      name = 'ignore_short_if_cps_ok',
      value = cfg.ignore_short_if_cps_ok
    },
    {
      'checkbox',
      0,
      2,
      3,
      1,
      label = 'Max duration, seconds:',
      name = 'check_max_duration',
      value = cfg.check_max_duration
    },
    {
      'floatedit',
      3,
      2,
      1,
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
      3,
      1,
      label = 'Max screen lines per subtitle',
      name = 'check_max_lines',
      value = cfg.check_max_lines
    },
    {
      'intedit',
      3,
      3,
      1,
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
      3,
      1,
      label = 'Max characters per second',
      name = 'check_max_chars_per_sec',
      value = cfg.check_max_chars_per_sec
    },
    {
      'intedit',
      3,
      4,
      1,
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
      label = 'Missing style definitions',
      name = 'check_missing_styles',
      value = cfg.check_missing_styles
    },
    {
      'checkbox',
      0,
      7,
      4,
      1,
      name = 'select_errors',
      label = 'Select bad lines',
      value = cfg.select_errors
    },
    {
      'checkbox',
      0,
      8,
      4,
      1,
      name = 'list_errors',
      label = 'List errors in Effect field',
      value = cfg.list_errors
    },
    {
      'dropdown',
      0,
      9,
      4,
      1,
      name = 'save',
      items = SAVE.list,
      value = cfg.save
    },
    {
      'label',
      0,
      10,
      4,
      2,
      label = 'Config: ' .. cfgsource
    },
    {
      'checkbox',
      0,
      12,
      3,
      1,
      name = 'selected_only',
      label = 'Selected lines only',
      value = cfg.selected_only
    }
  }
  local _list_0 = dlg
  for _index_0 = 1, #_list_0 do
    local c = _list_0[_index_0]
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
  btn, cfg = aegisub.dialog.display(dlg, {
    btns.ok,
    btns.cancel
  }, btns)
  if not btn or btn == btns.cancel then
    aegisub.cancel()
  end
  local _exp_0 = cfg.save
  if SAVE.script == _exp_0 then
    if #cfglineindices > 0 then
      subs.delete(unpack(cfglineindices))
    end
    subs.append({
      class = 'info',
      section = 'Script Info',
      key = script_name,
      value = cfgserialize(cfg)
    })
  elseif SAVE.user == _exp_0 then
    local f = io.open(userconfigpath, 'w')
    if not f then
      aegisub.log('Error writing ' .. userconfigpath)
    else
      f:write(cfgserialize(cfg, '\n'))
      f:close()
    end
  elseif SAVE.remove == _exp_0 then
    if #cfglineindices > 0 then
      subs.delete(unpack(cfglineindices))
    end
    return 
  end
  log_only = not cfg.select_errors and not cfg.list_errors
  if cfg.selected_only then
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #sel do
        local i = sel[_index_0]
        if blameline(i, subs[i], cfg) then
          _accum_0[_len_0] = i
          _len_0 = _len_0 + 1
        end
      end
      tosel = _accum_0
    end
  else
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i, s in ipairs(subs) do
        if blameline(i, s, cfg) then
          _accum_0[_len_0] = i
          _len_0 = _len_0 + 1
        end
      end
      tosel = _accum_0
    end
  end
  if playresX <= 0 then
    aegisub.log('Max screen lines checking not performed due to absent/invalid script horizontal resolution (PlayResX)')
  end
  if log_only or playresX <= 0 then
    aegisub.progress.set(100)
  end
  if cfg.select_errors then
    return tosel
  end
end)
