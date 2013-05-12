export script_name = "Wrap in {}"
export script_description = "Wraps all/selected lines in curly braces"

aegisub.register_macro script_name, script_description, (subs, sel) ->
    apply = (i,line) ->
        text = line.text
        if text and text != ""
            wrapifnonempty = (s) -> if s=="" then s else "{"..s.."}"
            stripovr = (ovr) ->
                keepbreak = (tag) -> tag\gsub "\\[^nN].*$",""
                wrapifnonempty ovr\gsub("\\t%s*%((.*)%)",stripovr)\gsub("(\\[^\\]+)",keepbreak)
            text = text\gsub("{(.-)}",stripovr)\gsub("{%s*}","")\gsub("{(.*)}","<%1>")\gsub("^<(.+)>$","%1")
            line.text = wrapifnonempty text
            subs[i] = line
    if #sel>1
        for i in *sel do apply i,subs[i]
    else
        for i,s in ipairs subs do apply i,s
    sel

