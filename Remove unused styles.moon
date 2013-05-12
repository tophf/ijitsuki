﻿export script_name = "Remove unused styles"
export script_description = "Removes styles not referenced in dialogue lines (comment lines are ignored)"

aegisub.register_macro script_name, script_description, (subs, sel) ->
    local *

    execute = ->
        require "utils"

        used = {}
        s1,s2 = 0,0

        --analyse

        count_used = (k,linenum) ->
            cnt = used[k]
            if cnt
                cnt.n += 1
                table.insert(cnt.lines, linenum - s2)
            else
                used[k] = n:1, lines:{}

        for i,line in ipairs subs
            if line.class=="style"
                used[line.name] = n:0, lines:{}
                s1 = i if s1==0
                s2 = i

            elseif line.class=="dialogue"
                count_used line.style, i
                for ovr in line.text\gmatch("{(.*\\r.*)}")
                    for ovrstyle in ovr\gmatch("\\r([^}\\]+)")
                        count_used( ovrstyle\gsub("%s*$",""), i) --trim trailing spaces

        if s1==0 or s2==#subs
            aegisub.log "Style definition section not found" if s1==0
            aegisub.log "Subtitles section not found" if s2==#subs
            aegisub.cancel()

        --clean

        aegisub.progress.set 50
        logUsed, logDel = "",""
        nUsed, nDel = 0,0

        for i = s2,s1,-1
            style = subs[i].name
            with occurences = used[style]
                if .n > 0
                    logUsed = string.format "  %s: %d%s\n%s", style, .n, list_spans(.lines,"\t: %s",4), logUsed
                    nUsed += 1
                else
                    logDel = string.format "  %s\t: DELETED\n%s", style, logDel
                    nDel += 1
                    subs.delete i

        --report

        aegisub.progress.set 100
        aegisub.log "USED: %d\n", nUsed
        aegisub.log "%s--------\n", logUsed if nUsed > 0
        aegisub.log "DELETED: %d\n%s", nDel, logDel
        if nDel==0
            aegisub.cancel()

    list_spans = (numberlist, format="%s", maxspans=-1) ->
        -- maxspans: -1 = no limit
        if not numberlist or maxspans==0 or maxspans < -1
            ""
        else
            s = ""
            spans = 0
            L1 = numberlist[1]
            L2 = L1

            add_span = ->
                spans += 1
                if maxspans == -1 or spans <= maxspans
                    s ..= string.format ", %d%s", L1, (if L2>L1 then "-"..tostring(L2) else "")
                    true
                else
                    s ..= "..."
                    false

            format_result = (s) -> string.format format, s\sub(3)

            for n in *numberlist[1,]
                if n - L2 > 1
                    if not add_span!
                        return format_result s
                    L1 = n
                L2 = n
            add_span!
            format_result s

    execute!