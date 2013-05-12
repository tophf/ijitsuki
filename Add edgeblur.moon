export script_name = "Add edgeblur"
export script_description = "Adds \\be1 tags to all selected lines"

require "re"

aegisub.register_macro script_name, script_description, (subs, sel) ->
    for i in *sel
        l = subs[i]
        s = l.text
        if s and not re.match(s,"\\{[^}]*\\\\(?:be|blur)\\d",re.ICASE)
            l.text = if s\match("^%s*{") then s\gsub("^(%s*{)","%1\\be1") else "{\\be1}"..s
            subs[i] = l
    sel
