export script_name = "Dup after"
export script_description = "Duplicates and shifts by original duration"

dup = (subs, sel) ->
    return for i in *sel
        with line = subs[i]
            duration = .end_time - .start_time
            .start_time += duration
            .end_time += duration
            line

aegisub.register_macro script_name, script_description, (subs, sel) ->
    for i,line in pairs dup(subs,sel)
        subs.insert sel[i] + i - 1, line
    [k+v for k,v in pairs sel]

aegisub.register_macro script_name..' and group',
    script_description..' (place the copy in continuous group after the last selected line)',
    (subs, sel) ->
        subs.insert sel[#sel] + 1, unpack dup(subs,sel)
        [sel[#sel] + i for i = 1,#sel]
