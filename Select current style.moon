export script_name = "Select current style"
export script_description = "Selects all lines with style equal to current line's style"

aegisub.register_macro script_name, script_description, (subs, sel, act) ->
    lookforstyle = subs[act].style
    if #sel>1
        [i for i in *sel when subs[i].style==lookforstyle]
    else
        [k for k,s in ipairs subs when s.style==lookforstyle]
