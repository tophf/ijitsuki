script_name = "Remove unused styles"
script_description = "Removes styles not referenced in dialogue lines (comment lines are ignored)"
return aegisub.register_macro(script_name, script_description, function(subs, sel)
  local execute, list_spans
  execute = function()
    require("utils")
    local used = { }
    local s1, s2 = 0, 0
    local count_used
    count_used = function(k, linenum)
      local cnt = used[k]
      linenum = linenum - s2
      if cnt then
        cnt.n = cnt.n + 1
        return table.insert(cnt.lines, linenum)
      else
        used[k] = {
          n = 1,
          lines = {
            linenum
          }
        }
      end
    end
    for i, line in ipairs(subs) do
      if line.class == "style" then
        used[line.name] = {
          n = 0,
          lines = { }
        }
        if s1 == 0 then
          s1 = i
        end
        s2 = i
      elseif line.class == "dialogue" then
        count_used(line.style, i)
        for ovr in line.text:gmatch("{(.*\\r.*)}") do
          for ovrstyle in ovr:gmatch("\\r([^}\\]+)") do
            count_used(ovrstyle:gsub("%s*$", ""), i)
          end
        end
      end
    end
    if s1 == 0 or s2 == #subs then
      if s1 == 0 then
        aegisub.log("Style definition section not found")
      end
      if s2 == #subs then
        aegisub.log("Subtitles section not found")
      end
      aegisub.cancel()
    end
    aegisub.progress.set(50)
    local logUsed, logDel = "", ""
    local nUsed, nDel = 0, 0
    for i = s2, s1, -1 do
      local style = subs[i].name
      do
        local occurences = used[style]
        if occurences.n > 0 then
          logUsed = ("  %s: %d%s\n%s"):format(style, occurences.n, list_spans(occurences.lines, "\t@ %s", 3), logUsed)
          nUsed = nUsed + 1
        else
          logDel = ("  %s\t: DELETED\n%s"):format(style, logDel)
          nDel = nDel + 1
          subs.delete(i)
        end
      end
      used[style] = nil
    end
    local logUnknown = ""
    local nUnknown = 0
    for style, u in pairs(used) do
      if u then
        logUnknown = logUnknown .. ("  %s: %d%s\n"):format(style, u.n, list_spans(u.lines, "\t@ %s", 3))
        nUnknown = nUnknown + 1
      end
    end
    aegisub.progress.set(100)
    aegisub.log("USED: %d\n", nUsed)
    if nUsed > 0 then
      aegisub.log("%s--------\n", logUsed)
    end
    aegisub.log("DELETED: %d\n%s", nDel, logDel)
    if nUnknown > 0 then
      aegisub.log("--------\nORPHANED: %d\n%s", nUnknown, logUnknown)
    end
    if nDel == 0 then
      return aegisub.cancel()
    end
  end
  list_spans = function(numberlist, format, maxspans)
    if format == nil then
      format = "%s"
    end
    if maxspans == nil then
      maxspans = -1
    end
    if not numberlist or maxspans == 0 or maxspans < -1 then
      return ""
    else
      local s = ""
      local spans = 0
      local L1 = numberlist[1]
      local L2 = L1
      local add_span
      add_span = function()
        spans = spans + 1
        if maxspans == -1 or spans <= maxspans then
          s = s .. (", %d%s"):format(L1, ((function()
            if L2 > L1 then
              return "-" .. tostring(L2)
            else
              return ""
            end
          end)()))
          return true
        else
          s = s .. "..."
          return false
        end
      end
      local format_result
      format_result = function(s)
        return string.format(format, s:sub(3))
      end
      for _index_0 = 1, #numberlist do
        local n = numberlist[_index_0]
        if n - L2 > 1 then
          if not add_span() then
            return format_result(s)
          end
          L1 = n
        end
        L2 = n
      end
      add_span()
      return format_result(s)
    end
  end
  return execute()
end)
