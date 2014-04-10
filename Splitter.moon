export script_name = "Split 1 frame"
export script_description = "Splits selected lines after 1st frame"

aegisub.register_macro script_name, script_description, (subs, sel, active) ->
    if not aegisub.frame_from_ms(0)
        aegisub.log "Load video first!"
        aegisub.cancel()

    for i = #sel,1,-1
        j = sel[i]
        l = subs[j]
        if l.class == "dialogue"
            t_nextframe = aegisub.ms_from_frame(aegisub.frame_from_ms(l.start_time)+1)
            t_end0 = l.end_time

            l.end_time = t_nextframe
            subs.insert j,l

            l.start_time, l.end_time = t_nextframe, t_end0
            subs[j+1] = l
    sel
