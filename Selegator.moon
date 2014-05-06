export script_name = 'Selegator'
export script_description = 'Select/navigate in the subtitle grid'

aegisub.register_macro script_name..'/Current style/select all', script_description, (subs, sel, act) ->
    lookforstyle = subs[act].style
    if #sel>1
        [i for i in *sel when subs[i].style==lookforstyle]
    else
        [k for k,s in ipairs subs when s.style==lookforstyle]

aegisub.register_macro script_name..'/Current style/previous', '', (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act-1,1,-1
        return if subs[i].class!='dialogue'
        if subs[i].style==lookforstyle
            return {i}

aegisub.register_macro script_name..'/Current style/next', '', (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act+1,#subs
        if subs[i].style==lookforstyle
            return {i}

aegisub.register_macro script_name..'/Current style/first in block', '', (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act-1,1,-1
        if subs[i].class!='dialogue' or subs[i].style!=lookforstyle
            return {i+1}

aegisub.register_macro script_name..'/Current style/last in block', '', (subs, sel, act) ->
    lookforstyle = subs[act].style
    for i = act+1,#subs
        if subs[i].style!=lookforstyle
            return {i-1}
    {#subs}

aegisub.register_macro script_name..'/Current style/select block', '', (subs, sel, act) ->
    lookforstyle = subs[act].style
    first, last = act, #subs
    for i = act-1,1,-1
        if subs[i].class!='dialogue' or subs[i].style!=lookforstyle
            first = i + 1
            break
    for i = act+1,#subs
        if subs[i].class!='dialogue' or subs[i].style!=lookforstyle
            last = i - 1
            break
    [i for i=first,last]

aegisub.register_macro script_name..'/Select till start',
    'Unlike built-in Shift-Home, it preserves the active line',
    (subs, sel, act) -> [i for i = 1,act when subs[i].class=='dialogue']

aegisub.register_macro script_name..'/Select till end',
    'Unlike built-in Shift-End, it preserves the active line',
    (subs, sel, act) -> [i for i = act,#subs when subs[i].class=='dialogue']
