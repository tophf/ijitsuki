export script_name = "Current style -> select/navigate"
export script_description = "Selects/navigates between all lines with style equal to current line's style"

aegisub.register_macro "Current style -> select all", script_description, (subs, sel, act) ->
    lookforstyle = subs[act].style
    if #sel>1
        [i for i in *sel when subs[i].style==lookforstyle]
    else
        [k for k,s in ipairs subs when s.style==lookforstyle]

aegisub.register_macro "Current style -> previous", "", (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act-1,1,-1
        return if subs[i].class!='dialogue'
        if subs[i].style==lookforstyle
            return {i}

aegisub.register_macro "Current style -> next", "", (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act+1,#subs
        if subs[i].style==lookforstyle
            return {i}

aegisub.register_macro "Current style -> first in block", "", (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act-1,1,-1
        if subs[i].class!='dialogue' or subs[i].style!=lookforstyle
            return {i+1}

aegisub.register_macro "Current style -> last in block", "", (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act+1,#subs
        if subs[i].style!=lookforstyle
            return {i-1}
