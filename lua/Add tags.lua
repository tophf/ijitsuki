script_name = 'Add tags'
script_description = 'Add tags to selected lines'
require('utils')
return aegisub.register_macro(script_name, script_description, function(subs, sel, act)
  local scope, location, loadprompt, config, userconfigpath, execute, showdialog, makebuttons, makedialog, min, cfgserialize, cfgdeserialize
  scope = {
    all = 'All lines',
    sel = 'Selected Lines',
    curline = 'Current line'
  }
  location = {
    line = 'Line start',
    each_in = '{...',
    each_out = '...}'
  }
  loadprompt = 'Do not use...'
  config = {
    all = false,
    location = location.line,
    scope = scope.sel,
    used = {
      '\\be1',
      '\\fad(100,100)',
      '\\fs',
      '\\fscx',
      '\\fscy',
      '\\alpha&H80&'
    }
  }
  config.text = config.used[1]
  userconfigpath = aegisub.decode_path('?user/' .. script_name .. '.conf')
  execute = function()
    do
      local f = io.open(userconfigpath, 'r')
      if f then
        local ok, _cfg = pcall(cfgdeserialize, f:read('*all'))
        if ok and _cfg.scope then
          config = _cfg
        end
        f:close()
      end
    end
    showdialog()
    if config.scope:find('^' .. scope.sel) then
      config.scope = scope.sel
    end
    local txt = config.text
    local ovrnum
    if config.all then
      ovrnum = nil
    else
      ovrnum = 1
    end
    local ovrbound, ovrtext
    local _exp_0 = config.location
    if location.line == _exp_0 then
      ovrbound, ovrtext = '^', '{' .. txt .. '}'
    elseif location.each_in == _exp_0 then
      ovrbound, ovrtext = '{', '{' .. txt
    elseif location.each_out == _exp_0 then
      ovrbound, ovrtext = '}', txt .. '}'
    end
    local processline
    processline = function(i, line)
      do
        local _with_0 = line
        if _with_0.class == 'dialogue' and not _with_0.comment then
          _with_0.text = _with_0.text:gsub(ovrbound, ovrtext, ovrnum)
          subs[i] = line
        end
        return _with_0
      end
    end
    local _exp_1 = config.scope
    if scope.all == _exp_1 then
      for i, s in ipairs(subs) do
        processline(i, s)
      end
    elseif scope.sel == _exp_1 then
      for _index_0 = 1, #sel do
        local i = sel[_index_0]
        processline(i, subs[i])
      end
    elseif scope.curline == _exp_1 then
      return processline(act, subs[act])
    else
      local style = config.scope:gsub('^.*:%s+', '')
      for i, s in ipairs(subs) do
        if s.style == style then
          processline(i, s)
        end
      end
    end
  end
  showdialog = function()
    local cfg
    local btns = makebuttons({
      {
        ok = '&Add'
      },
      {
        load = 'Loa&d...'
      },
      {
        cancel = '&Cancel'
      }
    })
    local dlg = makedialog()
    while true do
      local btn
      btn, cfg = aegisub.dialog.display(dlg, btns.__list, btns.__namedlist)
      local _exp_0 = btn
      if btns.ok == _exp_0 then
        break
      elseif btns.load == _exp_0 then
        if cfg.used ~= loadprompt then
          for _index_0 = 1, #dlg do
            local v = dlg[_index_0]
            if v.name == 'text' then
              v.text = cfg.used
              break
            end
          end
        end
      else
        aegisub.cancel()
      end
    end
    for k, v in pairs(cfg) do
      if type(v) == type(config[k]) then
        config[k] = v
      end
    end
    if cfg.used ~= loadprompt then
      config.text = cfg.used
    end
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, min(20, #config.used) do
        local _continue_0 = false
        repeat
          if config.used[i]:trim() == config.text:trim() then
            _continue_0 = true
            break
          end
          local _value_0 = config.used[i]
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      config.used = _accum_0
    end
    table.insert(config.used, 1, config.text)
    do
      local f = io.open(userconfigpath, 'w')
      if f then
        f:write(cfgserialize(config, '\n'))
        return f:close()
      else
        return aegisub.log('Error writing ' .. userconfigpath)
      end
    end
  end
  makebuttons = function(extendedlist)
    local btns = {
      __list = { },
      __namedlist = { }
    }
    for _index_0 = 1, #extendedlist do
      local L = extendedlist[_index_0]
      for k, v in pairs(L) do
        btns[k] = v
        btns.__namedlist[k] = v
        table.insert(btns.__list, v)
      end
    end
    return btns
  end
  makedialog = function()
    local _styles = { }
    for _index_0 = 1, #subs do
      local s = subs[_index_0]
      if s.class == 'style' then
        table.insert(_styles, 'Style: ' .. s.name)
      end
      if s.class == 'dialogue' then
        break
      end
    end
    local _location = {
      location.line,
      location.each_in,
      location.each_out
    }
    local _scopeitems = {
      scope.all,
      scope.sel .. ' (' .. tostring(#sel) .. ')',
      scope.curline,
      unpack(_styles)
    }
    local _scope
    if config.scope:find('^' .. scope.sel) then
      _scope = _scopeitems[2]
    else
      _scope = config.scope
    end
    local _used = table.copy(config.used)
    table.insert(_used, 1, loadprompt)
    local dlg = {
      {
        'checkbox',
        0,
        0,
        10,
        1,
        name = 'all',
        value = config.all,
        label = 'Add to all tag fields in line?'
      },
      {
        'label',
        0,
        1,
        1,
        1,
        label = 'Location:'
      },
      {
        'dropdown',
        1,
        1,
        13,
        1,
        name = 'location',
        items = _location,
        value = config.location,
        hint = 'Add to line start, tag start or tag end'
      },
      {
        'label',
        0,
        2,
        1,
        1,
        label = 'Scope:'
      },
      {
        'dropdown',
        1,
        2,
        13,
        1,
        name = 'scope',
        items = _scopeitems,
        value = _scope,
        hint = 'Selected lines or specific style'
      },
      {
        'label',
        0,
        3,
        1,
        1,
        label = 'Previous:'
      },
      {
        'dropdown',
        1,
        3,
        13,
        1,
        name = 'used',
        items = _used,
        value = loadprompt,
        hint = 'Click "Add" to use the selected value .\nClick "Load" to load value into tag box'
      },
      {
        'label',
        0,
        4,
        1,
        1,
        label = 'Tags:'
      },
      {
        'textbox',
        0,
        5,
        14,
        4,
        name = 'text',
        text = config.text,
        hint = 'Input tags to add'
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
    return dlg
  end
  min = function(a, b)
    if a < b then
      return a
    else
      return b
    end
  end
  string.trim = function(self)
    return self:gsub('^%s+', ''):gsub('%s+$', '')
  end
  string.split = function(self, sepcharclass)
    return (function()
      local _accum_0 = { }
      local _len_0 = 1
      for s in self:gmatch('([^' .. sepcharclass .. ']+)') do
        _accum_0[_len_0] = s
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)()
  end
  cfgserialize = function(t)
    local s = ''
    for k, v in pairs(t) do
      s = s .. (k .. ':' .. ((function()
        if type(v) == 'table' then
          return table.concat(v, '|')
        else
          return tostring(v)
        end
      end)()) .. '\n')
    end
    return s
  end
  cfgdeserialize = function(s)
    local splitkv
    splitkv = function(kv)
      local k, v = kv:match('^%s*(.-)%s*:%s*(.+)$')
      if v:find('|') then
        return k, v:split('|')
      else
        return k, v
      end
    end
    local _tbl_0 = { }
    local _list_0 = s:split('\n\r')
    for _index_0 = 1, #_list_0 do
      local kv = _list_0[_index_0]
      local _key_0, _val_0 = splitkv(kv)
      _tbl_0[_key_0] = _val_0
    end
    return _tbl_0
  end
  execute()
  return sel
end)
