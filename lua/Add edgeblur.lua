script_name = "Add edgeblur"
script_description = "Adds \\be1 tags to all selected lines"
require("re")
return aegisub.register_macro(script_name, script_description, function(subs, sel)
  for _index_0 = 1, #sel do
    local i = sel[_index_0]
    local l = subs[i]
    local s = l.text
    if s and not re.match(s, "\\{[^}]*\\\\(?:be|blur)\\d", re.ICASE) then
      if s:match("^%s*{") then
        l.text = s:gsub("^(%s*{)", "%1\\be1")
      else
        l.text = "{\\be1}" .. s
      end
      subs[i] = l
    end
  end
  return sel
end)
