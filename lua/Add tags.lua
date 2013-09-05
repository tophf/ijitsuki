script_name = 'Add tags'
script_description = 'Add tags to selected lines'
require('utils')
return aegisub.register_macro(script_name, script_description, function(subs, sel, act)
  local onetimeinit, execute, showdialog, makedialog, expandlist, min, cfgread, cfgwrite
  local scope, location, loadprompt, btns, config, userconfigpath
  onetimeinit = function()
    if config then
      return 
    end
    scope = {
      all = 'All lines',
      sel = 'Selected lines',
      cur = 'Current line'
    }
    location = expandlist({
      {
        line = 'Line start'
      },
      {
        first_in = '{...'
      },
      {
        each_in = '{... all'
      },
      {
        first_out = '...}'
      },
      {
        each_out = '...} all'
      }
    })
    loadprompt = 'Previous items...'
    btns = expandlist({
      {
        ok = '&Add / reuse chosen item'
      },
      {
        load = 'Loa&d only'
      },
      {
        cancel = '&Cancel'
      }
    })
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
  end
  execute = function()
    cfgread()
    showdialog()
    cfgwrite()
    local txt = config.text
    if config.scope:find('^' .. scope.sel) then
      config.scope = scope.sel
    end
    local ovrbound, ovrtext, ovrnum
    local _exp_0 = config.location
    if location.line == _exp_0 then
      ovrbound = '^(.*)$'
      ovrtext = function(s)
        if s:sub(1, 1) == '{' then
          return s:gsub('^{(.-)}', '{%1' .. txt .. '}')
        else
          return '{' .. txt .. '}' .. s
        end
      end
      ovrnum = 1
    elseif location.first_in == _exp_0 then
      ovrbound, ovrtext, ovrnum = '{', '{' .. txt, 1
    elseif location.first_out == _exp_0 then
      ovrbound, ovrtext, ovrnum = '}', txt .. '}', 1
    elseif location.each_in == _exp_0 then
      ovrbound, ovrtext, ovrnum = '{', '{' .. txt, nil
    elseif location.each_out == _exp_0 then
      ovrbound, ovrtext, ovrnum = '}', txt .. '}', nil
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
    elseif scope.cur == _exp_1 then
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
    return table.insert(config.used, 1, config.text)
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
    local _scopeitems = {
      scope.all,
      scope.sel .. ' (' .. tostring(#sel) .. ')',
      scope.cur,
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
        'textbox',
        0,
        0,
        6,
        4,
        name = 'text',
        text = config.text,
        hint = 'Input tags to add'
      },
      {
        'dropdown',
        0,
        4,
        1,
        1,
        name = 'location',
        items = location.__list,
        value = config.location,
        hint = 'Point of insertion:\n\tline start\n\tovrblock start / end'
      },
      {
        'dropdown',
        1,
        4,
        3,
        1,
        name = 'scope',
        items = _scopeitems,
        value = _scope,
        hint = 'Scope of action:\n\tall lines\n\tselected lines\n\tspecific style'
      },
      {
        'dropdown',
        4,
        4,
        2,
        1,
        name = 'used',
        items = _used,
        value = loadprompt,
        hint = 'Select value to use instead of the typed text'
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
  expandlist = function(extendedlist)
    local list = {
      __list = { },
      __namedlist = { }
    }
    for _index_0 = 1, #extendedlist do
      local LI = extendedlist[_index_0]
      for k, v in pairs(LI) do
        list[k] = v
        list.__namedlist[k] = v
        table.insert(list.__list, v)
      end
    end
    return list
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
  cfgread = function()
    do
      local f = io.open(userconfigpath, 'r')
      if f then
        local splitkv
        splitkv = function(kv)
          local k, v = kv:match('^%s*(.-)%s*:%s*(.+)$')
          if v:find('|') then
            return k, v:split('|')
          else
            return k, v
          end
        end
        local _cfg
        do
          local _tbl_0 = { }
          local _list_0 = f:read('*all'):split('\n\r')
          for _index_0 = 1, #_list_0 do
            local kv = _list_0[_index_0]
            local _key_0, _val_0 = splitkv(kv)
            _tbl_0[_key_0] = _val_0
          end
          _cfg = _tbl_0
        end
        if _cfg and _cfg.scope then
          config = _cfg
        end
        return f:close()
      end
    end
  end
  cfgwrite = function()
    do
      local f = io.open(userconfigpath, 'w')
      if f then
        local s = ''
        for k, v in pairs(config) do
          s = s .. (k .. ':' .. ((function()
            if type(v) == 'table' then
              return table.concat(v, '|')
            else
              return tostring(v)
            end
          end)()) .. '\n')
        end
        f:write(s, '\n')
        return f:close()
      else
        return aegisub.log('Error writing ' .. userconfigpath)
      end
    end
  end
  onetimeinit()
  execute()
  return sel
end)
