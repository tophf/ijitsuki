export script_name = 'Splitter'
export script_description = 'Splits lines'

aegisub.register_macro script_name..'/Split by \\N',
    '..and trim spaces/hyphens at start',
    (subs, sel) ->

    offs = 0
    for i,j in ipairs sel
        j += offs
        with line = subs[j]
            continue unless .text\find '\\N'

            txt = .text
            chars = txt\gsub('\\N','')\len!
            t1, t2 = .start_time, .end_time
            dur = t2 - t1

            subs.delete j
            while true
                pos = txt\find('\\N') or (txt\len! + 1)
                .text = txt\sub(1,pos-1)\gsub('^%s*[-–—]*%s*','')\gsub('%s*$','')
                txt = txt\sub pos+2
                .start_time = t1
                .end_time = if txt=='' then t2 else t1 + .text\len! / chars * dur

                subs.insert j, line
                j += 1
                offs += 1

                t1 = .end_time
                break if txt==''
            offs -= 1

aegisub.register_macro script_name..'/Split 1 frame',
    'Splits selected lines after 1st frame',
    (subs, sel, active) ->

    if not aegisub.frame_from_ms(0)
        aegisub.log 'Load video first!'
        aegisub.cancel()

    for i = #sel,1,-1
        j = sel[i]
        l = subs[j]
        if l.class == 'dialogue'
            t_nextframe = aegisub.ms_from_frame(aegisub.frame_from_ms(l.start_time)+1)
            t_end0 = l.end_time

            l.end_time = t_nextframe
            subs.insert j,l

            l.start_time, l.end_time = t_nextframe, t_end0
            subs[j+1] = l
    sel

aegisub.register_macro script_name..'/Split 1 frame on chapters',
    'Splits 1st frame on lines starting at chapter mark',
    (subs, sel, active) ->

    if not aegisub.frame_from_ms 0
        aegisub.log 'Load video first!'
        aegisub.cancel!

    fn = aegisub.dialog.open 'Chapter file', '', '', 'All Files (*)|*|xml chapters (.xml)|*.xml|simple OGG chapters (.txt)|*.txt'
    aegisub.cancel! if not fn

    file = io.open fn
    aegisub.cancel! if not file

    pat = if fn\lower!\find '%.xml$' then '<ChapterTimeStart>' else 'CHAPTER%d+%s-='
    pat = pat..'%s-(%d+:%d+:%d+%.?%d?%d?%d?)'

    -- sort subs by time
    inject_i = (i, line=subs[i]) ->
        line.i = i
        line
    sorted = [inject_i i,line for i,line in ipairs subs when line.class=='dialogue']
    table.sort sorted, (a,b) ->
        a.start_time < b.start_time or (a.start_time == b.start_time and a.i < b.i)

    to_split = {}
    -- parse chapters
    for s in file\lines!
        time = s\match pat
        continue if not time

        aegisub.log 'Checking '..time..'\n'
        h,m,s,ss = unpack [v for v in time\gmatch '(%d+)']
        chap_ms = (h*3600 + m*60 + s)*1000 + (ss or 0)
        f = aegisub.frame_from_ms chap_ms

        a, b = 1, #sorted
        while b - a > 1
            c = math.floor((a + b)/2)
            cf = aegisub.frame_from_ms sorted[c].start_time
            if cf < f
                a = c
            elseif cf > f
                b = c
            else
                while c > 1 and cf==aegisub.frame_from_ms sorted[c-1].start_time
                    c -= 1
                while c <= #sorted and cf==aegisub.frame_from_ms sorted[c].start_time
                    L = sorted[c]
                    if aegisub.frame_from_ms(L.end_time) - 1 > f
                        L.log = '\t'..time..'\t'..L.text\sub(1,20)..(#L.text>20 and '...' or '')
                        table.insert to_split, L
                    c += 1
                break

    io.close file

    -- split lines
    table.sort to_split, (a,b) -> a.i > b.i
    for line in *to_split
        nextframetime = aegisub.ms_from_frame(aegisub.frame_from_ms(line.start_time) + 1)
        origendtime = line.end_time

        line.end_time = nextframetime
        subs.insert line.i, line

        line.start_time, line.end_time = nextframetime, origendtime
        subs[line.i + 1] = line

    aegisub.log '\nChapters split: '..#to_split..'\n'
    aegisub.log table.concat [L.log for L in *to_split],'\n'

    -- select the results
    [L.i+k-1 for k,L in pairs to_split]
