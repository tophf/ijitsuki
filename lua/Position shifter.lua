script_name = "Position shifter"
script_description = "Shifts positions in selected lines with \pos,\move,\org,\clip"
require("re")
return aegisub.register_macro(script_name, script_description, function(subs, sel)
  local checkrunnable, execute, makedialog
  checkrunnable = function()
    local r = re.compile("\\{.*\\\\(?:pos|move|org|i?clip)\\s*\\(.*\\}", re.ICASE)
    for _index_0 = 1, #sel do
      local i = sel[_index_0]
      if r:match(subs[i].text) then
        return true
      end
    end
    aegisub.log("You should select lines with \\pos or \\move or \\org or \\clip")
    return aegisub.cancel()
  end
  execute = function()
    local btns = {
      ok = "&Shift",
      cancel = "&Cancel"
    }
    local btn, cfg = aegisub.dialog.display(makedialog(), {
      btns.ok,
      btns.cancel
    }, btns)
    if not btn or btn == btns.cancel then
      aegisub.cancel()
    end
    do
      cfg.pos = {
        cfg.pos_x,
        cfg.pos_y
      }
      cfg.org = {
        cfg.org_x,
        cfg.org_y
      }
      cfg.move = {
        cfg.move_x1,
        cfg.move_y1,
        cfg.move_x2,
        cfg.move_y2
      }
      cfg.clip = {
        cfg.clip_x,
        cfg.clip_y,
        cfg.clip_x,
        cfg.clip_y
      }
    end
    local float2str
    float2str = function(f)
      return tostring(f):gsub("%.(%d-)0+$", "%.%1"):gsub("%.$", "")
    end
    local arraysum2str
    arraysum2str = function(arr1str, arr2)
      return unpack((function()
        local _accum_0 = { }
        local _len_0 = 1
        for i = 1, #arr1str do
          _accum_0[_len_0] = float2str(tonumber(arr1str[i]) + arr2[i])
          _len_0 = _len_0 + 1
        end
        return _accum_0
      end)())
    end
    for _index_0 = 1, #sel do
      local i = sel[_index_0]
      local line = subs[i]
      local s = line.text
      s = s:gsub("\\pos%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)", function(x, y)
        return ("\\pos(%s,%s)"):format(arraysum2str({
          x,
          y
        }, cfg.pos))
      end)
      s = s:gsub("\\move%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)", function(x, y, x2, y2)
        return ("\\move(%s,%s,%s,%s"):format(arraysum2str({
          x,
          y,
          x2,
          y2
        }, cfg.move))
      end)
      s = s:gsub("\\org%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)", function(x, y)
        return ("\\org(%s,%s)"):format(arraysum2str({
          x,
          y
        }, cfg.org))
      end)
      s = s:gsub("\\(i?clip)%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)", function(tag, x, y, x2, y2)
        return ("\\%s(%s,%s,%s,%s)"):format(tag, arraysum2str({
          x,
          y,
          x2,
          y2
        }, cfg.clip))
      end)
      s = s:gsub("\\(i?clip%(%s*%d*%s*%,?)([mlbsc%s%d%-]+)%)", function(tag, numbers)
        return ("\\%s%s)"):format(tag, numbers:gsub("(-?%d+)%s*(-?%d+)", function(x, y)
          return ("%d %d"):format(arraysum2str({
            x,
            y
          }, cfg.clip))
        end))
      end)
      line.text = s
      subs[i] = line
    end
  end
  makedialog = function()
    local dlg = {
      {
        "label",
        0,
        0,
        1,
        1,
        label = "\\pos"
      },
      {
        "floatedit",
        1,
        0,
        1,
        1,
        name = "pos_x",
        value = 0.00,
        hint = "Shift x coordinate of \pos"
      },
      {
        "floatedit",
        2,
        0,
        1,
        1,
        name = "pos_y",
        value = 0.00,
        hint = "Shift y coordinate of \pos"
      },
      {
        "label",
        0,
        1,
        1,
        1,
        label = "\\move"
      },
      {
        "floatedit",
        1,
        1,
        1,
        1,
        name = "move_x1",
        value = 0.00,
        hint = "Shift first x coordinate of \move"
      },
      {
        "floatedit",
        2,
        1,
        1,
        1,
        name = "move_y1",
        value = 0.00,
        hint = "Shift first y coordinate of \move"
      },
      {
        "floatedit",
        3,
        1,
        1,
        1,
        name = "move_x2",
        value = 0.00,
        hint = "Shift second x coordinate of \move"
      },
      {
        "floatedit",
        4,
        1,
        1,
        1,
        name = "move_y2",
        value = 0.00,
        hint = "Shift second y coordinate of \move"
      },
      {
        "label",
        0,
        2,
        1,
        1,
        label = "\\org"
      },
      {
        "floatedit",
        1,
        2,
        1,
        1,
        name = "org_x",
        value = 0.00,
        hint = "Shift x coordinate of \org"
      },
      {
        "floatedit",
        2,
        2,
        1,
        1,
        name = "org_y",
        value = 0.00,
        hint = "Shift y coordinate of \org"
      },
      {
        "label",
        0,
        3,
        1,
        1,
        label = "\\clip"
      },
      {
        "floatedit",
        1,
        3,
        1,
        1,
        name = "clip_x",
        value = 0.00,
        hint = "Shift x coordinate of \clip"
      },
      {
        "floatedit",
        2,
        3,
        1,
        1,
        name = "clip_y",
        value = 0.00,
        hint = "Shift y coordinate of \clip"
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
  checkrunnable()
  execute()
  return sel
end)
