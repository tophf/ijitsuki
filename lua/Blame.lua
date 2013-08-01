script_name = 'Blame'
script_description = 'Finds lines exceeding specified limits: min/max duration, CPS, line count, etc.'
require("utils")
return aegisub.register_macro(script_name, script_description, function(subs, sel)
  local SAVE, DEFAULTS, TYPESETREGEXP, execute, blameline, max, cfgserialize, cfgdeserialize, cfgread, cfgwrite, init
  local cfg, cfgsource, btns, dlg, userconfigpath
  local playresX, styles, cfglineindices, dialogfirst, overlap_end
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
    ignore_typeset = true,
    selected_only = false,
    select_errors = true,
    list_errors = true,
    log_errors = false,
    save = SAVE.user
  }
  TYPESETREGEXP = [[\{.*?\\(pos|move|k|kf|ko|K|t|fax|fay|org|frx|fry|frz|an)[^a-zA-Z].*?\}]]
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
      aegisub.log('\n' .. #tosel .. ' lines blamed.\n')
    end
    if playresX <= 0 then
      aegisub.log('%s %s', 'Max screen lines checking not performed', 'due to absent/invalid script horizontal resolution (PlayResX)')
    end
    aegisub.progress.set(100)
    if cfg.select_errors then
      return tosel
    end
  end
  blameline = function(num, v, lines)
    local msg = ''
    local i, line
    i, line = v.i, v.line
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
      local ignoretypeset
      ignoretypeset = function(line)
        return cfg.ignore_typeset and TYPESETREGEXP:match(line.text)
      end
      if not ignoretypeset(line) then
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
          local available_width = playresX
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
          local numlines = 0
          for span in textonly:gsub('\\N', '\n'):split_iter('\n') do
            local width = ({
              aegisub.text_extents(style, span .. ' ')
            })[1]
            numlines = numlines + math.floor(width / available_width + 0.9999999999)
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
              if not ignoretypeset(L) then
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
        for ovr in line.text:gmatch("{(.*\\r.*)}") do
          for ovrstyle in ovr:gmatch("\\r([^}\\]+)") do
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
        subs[i] = line
      end
      if not cfg.list_errors or cfg.log_errors then
        if msg ~= '' then
          aegisub.log('%d: %s\t%s%s\n', i - dialogfirst + 1, msg, textonly:sub(1, 20), ((function()
            if #textonly > 20 then
              return '...'
            else
              return ''
            end
          end)()))
        end
        aegisub.progress.set(num / #subs * 100)
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
    playresX = 0
    styles = { }
    cfglineindices = { }
    dialogfirst = 0
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
        dialogfirst = i
        break
      end
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
        hint = 'Requires 1) playresX in script header 2) all used fonts installed'
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
        label = 'Skip ALL RULES ABOVE on &typeset',
        name = 'ignore_typeset',
        value = cfg.ignore_typeset,
        hint = TYPESETREGEXP
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
    local re = require("aegisub.re")
    TYPESETREGEXP = re.compile(TYPESETREGEXP)
  end
  return execute()
end)
