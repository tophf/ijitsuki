export script_name = 'Blame'
export script_description = table.concat {
        'Marks lines exceeding specified limits:'
        'min/max duration, CPS, line count, overlaps, missing styles.'
    },' '

require 'utils'
re = require 'aegisub.re'

for v in *{{-1,'previous'},{1,'next'}}
    goto = 'Go to '..v[2]
    aegisub.register_macro script_name..': '..goto, goto..' blemished line',
        (subs, sel, act) ->
            step = v[1]
            dest = if step < 0 then 1 else #subs
            is_blemished = re.compile table.concat {
                    [[(?:^|\s)]]
                    '(?:'
                    [[(?:short|long)[\d.]+s]]
                    [[|\d+(?:cps|lines)]]
                    [[|ovr\d+?|nostyle]]
                    ')'
                    [[(?:\s|$)]]
                }, ''
            for i = act+step, dest, step
                with line = subs[i]
                    if line.class=='dialogue'
                        if not line.comment
                            if is_blemished\match line.effect
                                return {i}
            aegisub.cancel!

aegisub.register_macro script_name, script_description, (subs, sel) ->
    local *
    local cfg, cfgsource, btns, dlg, userconfigpath
    local playres, styles, cfglineindices, dialogfirst, overlap_end

    SAVE = {
        no:         "Apply and don't save settings"
        script:     "Apply and save settings in script"
        user:       "Apply and save settings in user config"
        removeonly: "Only remove saved settings from script"
    }

    DEFAULTS = {
        check_min_duration:true,      min_duration:1.0
        ignore_short_if_cps_ok:true
        check_max_duration:true,      max_duration:10.0
        check_max_lines:true,         max_lines:2
        check_max_chars_per_sec:true, max_chars_per_sec:25
        check_missing_styles:true
        check_overlaps:true,          list_only_first_overlap:true
        ignore_signs:true
        selected_only:false
        select_errors:true
        list_errors:true
        log_errors:false
        save:SAVE.user
    }

    SIGNS = table.concat {
            [[\{.*?\\(]]
            'pos|move|an|a|org|'
            'frx|fry|frz|'
            'fax|fay|'
            'k|kf|ko|K|'
            't'
            [[)[^a-zA-Z].*?\}]]
        },''
    SIGNSre = re.compile SIGNS

    METRICS = {}
    with METRICS
        .q2_re = re.compile [[\{.*?\\q2.*?\}]]
        .tag = {
                fn:  'fontname'
                r:   ''
                fsp: 'spacing'
                fs:  'fontsize'
                fscx:'scale_x'
            }
        alltags = table.concat [k for k,v in pairs .tag],'|'
        allvalues = table.concat {
                [[(?<=fn)(?:[^\\}]*|\\|\s*$)|]]
                [[(?<=r)(?:[^\\}]*|\\|\s*$)|]]
                [[(?:[\s\\]+|-?[\d.]+|\s*$)]]
            },''
        tagexpr = [[\\((?:]]..alltags..')(?:'..allvalues..'))'
        .ovr_re = re.compile [[\{.*?]]..tagexpr..[[.*?\}]]
        .tag_re = re.compile tagexpr
        .tagparts_re = re.compile '('..alltags..')('..allvalues..')'

    execute = ->
        cfgread!
        init!

        btn, cfg = aegisub.dialog.display(dlg, {btns.ok, btns.cancel}, btns)
        aegisub.cancel! if not btn or btn == btns.cancel

        cfgwrite!

        local lines
        if cfg.selected_only
            lines = for i in *sel
                    continue if subs[i].comment
                    {i:i,line:subs[i]}
        else
            lines = for i,line in ipairs subs
                    continue if line.class!='dialogue' or line.comment
                    {i:i,line:line}

        if cfg.check_overlaps
            overlap_end = 0
            table.sort lines, (a,b) ->
                a_t, b_t = a.line.start_time, b.line.start_time
                a_t < b_t or (a_t == b_t and a.i < b.i)

        video_loaded = aegisub.frame_from_ms(0)
        check_max_lines_enabled = cfg.check_max_lines and playres.x > 0 and video_loaded
        tosel = [v.i for num,v in ipairs lines when blameline num,v,lines]

        if cfg.log_errors or not (cfg.list_errors or cfg.select_errors)
            aegisub.log '\n%d lines blamed.\n',#tosel
        if cfg.check_max_lines and not check_max_lines_enabled
            err1 = "load video file" unless video_loaded
            err2 = "specify correct PlayRes in script's properties!" unless playres.x > 0
            aegisub.log '%s. %s%s%s%s.',
                "Max screen lines checking not performed",
                "Please, ",err1 or "",if err1 and err2 then " and " else "",err2 or ""
        aegisub.progress.set 100

        tosel if cfg.select_errors

    blameline = (num, v, lines) ->
        msg = ''
        {i:index, :line} = v
        with line
            duration = (.end_time - .start_time)/1000
            textonly = .text\gsub('{.-}','')\gsub('\\h',' ')
            length = textonly\gsub('\\N','')\gsub("[ ,.-!?&():;/<>|%%$+=_'\"]",'')\len!
            cps = if duration==0 then 0 else length/duration
            style = styles[.style] or styles['Default'] or styles['*Default']

            if not should_ignore_signs line
                if cfg.check_min_duration and duration < cfg.min_duration
                    if not cfg.ignore_short_if_cps_ok or math.floor(cps) > cfg.max_chars_per_sec
                        msg   = (' short%gs')\format duration

                if cfg.check_max_duration and duration > cfg.max_duration
                    msg ..= (' long%gs')\format duration

                if cfg.check_max_chars_per_sec and math.floor(cps) > cfg.max_chars_per_sec
                    msg ..= (' %dcps')\format cps

                if check_max_lines_enabled and style
                    numlines = 0
                    if METRICS.q2_re\match .text
                        s = .text\gsub '\\N%s*{.-}%s*',''
                        numlines = (#s - s\gsub('\\N','')\len!)/2 + 1
                    else
                        available_width = playres.x
                        available_width -= if .margin_r>0 then .margin_r else style.margin_r
                        available_width -= if .margin_l>0 then .margin_l else style.margin_l
                        available_width *= playres.realx / playres.x
                        ovrstyle = table.copy style

                        for subline in .text\gsub('\\N','\n')\split_iter '\n'
                            prevspanstart = 1
                            subline = subline\trim!

                            -- iterate blocks with {...\tags that alter width metrics...}
                            for ovr, ovrstart, ovrend in METRICS.ovr_re\gfind subline
                                numlines += calc_numlines subline\sub(prevspanstart, ovrstart-1),
                                                          ovrstyle, available_width
                                prevspanstart = ovrend + 1

                                tagpos = 1
                                -- iterate width-altering \tags inside current {} block
                                -- and put overrides into style used for text width calculation
                                while true
                                    tag = METRICS.tag_re\match ovr, tagpos
                                    break unless tag
                                    tagpos = tag[2].last + 1

                                    tagparts = METRICS.tagparts_re\match tag[2].str
                                    tag.name, tag.value = tagparts[2].str, tagparts[3].str\trim!

                                    if tag.name=='r'
                                        ovrstyle = table.copy styles[tag.value] or style
                                    else
                                        set_style ovrstyle, tag, style

                            numlines += calc_numlines subline\sub(prevspanstart),
                                                      ovrstyle, available_width
                            numlines = math.floor numlines + 0.9999999999

                    msg ..= (' %dlines')\format numlines if numlines > cfg.max_lines

                if cfg.check_overlaps
                    if .start_time < overlap_end
                        msg ..= ' ovr' unless cfg.list_only_first_overlap
                    else
                        --new timegroup start, let's count overlapped lines
                        overlap_end = .end_time
                        cnt = 0
                        for j = num+1,#lines
                            L = lines[j].line
                            break if L.start_time >= overlap_end
                            cnt += 1 if not should_ignore_signs L
                        msg ..= ' ovr'..cnt if cnt > 0

            if cfg.check_missing_styles
                missing = styles[.style]==nil
                for ovr in .text\gmatch '{(.*\\r.*)}'
                    for ovrstyle in ovr\gmatch '\\r([^}\\]+)'
                        missing = true unless styles[ovrstyle]
                msg ..= ' nostyle' if missing

            msg = msg\sub(2)
            if (msg != '' or .effect != '') and msg != .effect and cfg.list_errors
                .effect = msg
                subs[index] = line

            if not cfg.list_errors or cfg.log_errors
                aegisub.progress.set num/#lines*100
                if msg != ''
                    aegisub.log '%d: %s\t%s%s\n',
                        index - dialogfirst + 1,
                        msg,
                        textonly\sub(1,20),
                        (if #textonly > 20 then '...' else '')
        msg != ''

    should_ignore_signs = (line) -> cfg.ignore_signs and SIGNSre\match line.text

    set_style = (style, tag, fallbackstyle) ->
        field = METRICS.tag[tag.name]
        style[field] = if tag.value!='' then tag.value else fallbackstyle[field]

    calc_numlines = (text, style, available_width) ->
        ok,width = pcall aegisub.text_extents, style, text\gsub('{.-}','')\gsub('\\h',' ')
        return 0 unless ok
        return width/available_width

    max = (a, b) -> if a > b then a else b
    string.split_iter = (sepcharclass) => @\gmatch '([^'..sepcharclass..']+)'
    string.trim = => @\gsub('^%s+','')\gsub('%s+$','')
    string.val = =>
        s = @\trim!\lower!
        return true if s=='true'
        return false if s=='false'
        return tonumber s if s\match '^%-?[0-9.]+$'
        @

    cfgserialize = (t, sep) ->
        return '' unless t
        table.concat [k..':'..tostring(v) for k,v in pairs t], sep

    cfgdeserialize = (s) ->
        kv2pair = (kv) -> unpack [i\val! for i in kv\split_iter ':']
        {kv2pair kv for kv in s\split_iter ',\n\r'}

    cfgread = ->
        --load user config if script hasn't one
        userconfig = '?user/'..script_name..'.conf'
        userconfigpath = aegisub.decode_path userconfig
        if not cfg
            f = io.open userconfigpath,'r'
            if f
                ok, _cfg = pcall(cfgdeserialize, f\read '*all')
                if ok and _cfg.save
                    cfgsource = userconfig
                    cfg = _cfg
                f\close!

        if not cfg
            cfgsource = 'defaults'
            cfg = table.copy DEFAULTS
        else
            cfgdef = false
            for k,v in pairs DEFAULTS
                cfg[k], cfgdef = v, true if cfg[k]==nil
            cfgsource ..= ' + defaults' if cfgdef

    cfgwrite = ->
        switch cfg.save
            when SAVE.script
                subs.delete unpack cfglineindices if #cfglineindices > 0
                subs.append {class:'info', section:'Script Info', key:script_name, value:cfgserialize(cfg,', ')}

            when SAVE.user
                f = io.open userconfigpath,'w'
                if not f
                    aegisub.log 'Error writing '..userconfigpath
                else
                    f\write cfgserialize cfg,'\n'
                    f\close!

            when SAVE.removeonly
                subs.delete unpack cfglineindices if #cfglineindices > 0
                aegisub.cancel!

    init = ->
        playres = x:0, y:0, realx:0
        styles = {}
        cfglineindices = {}
        dialogfirst = 0

        for i,s in ipairs subs
            --assuming standard section order: info, styles, events
            switch s.class
                when 'info'
                    kl = s.key\lower!
                    if kl=='playresx' or kl=='playresy'
                        playres[kl\sub #kl] = tonumber s.value if s.value\match '^%s*%d+%s*$'
                    elseif s.key==script_name
                        table.insert cfglineindices, i
                        ok, _cfg = pcall(cfgdeserialize, s.value)
                        cfg, cfgsource = _cfg, 'script' if ok and _cfg.save
                when 'style'
                    styles[s.name] = s
                when 'dialogue'
                    dialogfirst = i
                    break

        if aegisub.video_size!
            w,h,ar,artype = aegisub.video_size!
            playres.realx = math.floor playres.y / h * w

        btns = ok:'&Go', cancel:'&Cancel'
        with SAVE
            .list = {.no, .script, .user, .removeonly}

        --accels: gcnixlhofAmsrwe
        dlg = {
            {'checkbox',  0,0,7,1, label:'Mi&n duration, seconds:', name:'check_min_duration',
                                   value:cfg.check_min_duration}
            {'floatedit', 7,0,2,1,  name:'min_duration', value:cfg.min_duration, min:0, max:10, step:0.1}
            ---------------------------------------------------------
            {'checkbox',  0,1,9,1, label:'&Ignore if CPS is ok', name:'ignore_short_if_cps_ok',
                                   value:cfg.ignore_short_if_cps_ok}
            ---------------------------------------------------------
            {'checkbox',  0,2,7,1, label:'Ma&x duration, seconds:', name:'check_max_duration',
                                   value:cfg.check_max_duration}
            {'floatedit', 7,2,2,1,  name:'max_duration', value:cfg.max_duration, min:0, max:100, step:1}
            ---------------------------------------------------------
            {'checkbox',  0,3,7,1, label:'Max screen &lines per subtitle', name:'check_max_lines',
                                   value:cfg.check_max_lines,
                                    hint:'Requires 1) PlayRes in script header 2) all used fonts installed'}
            {'intedit',   7,3,2,1,  name:'max_lines', value:cfg.max_lines, min:1, max:10}
            ---------------------------------------------------------
            {'checkbox',  0,4,7,1, label:'Max c&haracters per second', name:'check_max_chars_per_sec',
                                   value:cfg.check_max_chars_per_sec}
            {'intedit',   7,4,2,1,  name:'max_chars_per_sec', value:cfg.max_chars_per_sec, min:1, max:100}
            ---------------------------------------------------------
            {'checkbox',  0,5,3,1, label:'&Overlaps:', name:'check_overlaps', value:cfg.check_overlaps}
            {'checkbox',  3,5,5,1, label:'...report only the &first in group', name:'list_only_first_overlap',
                                   value:cfg.list_only_first_overlap}
            ---------------------------------------------------------
            {'checkbox',  0,6,9,1, label:'Ignore &ALL RULES ABOVE on signs', name:'ignore_signs',
                                   value:cfg.ignore_signs, hint:SIGNS}
            ---------------------------------------------------------
            {'checkbox',  0,8,9,1, label:'&Missing style definitions', name:'check_missing_styles',
                                   value:cfg.check_missing_styles}
            ---------------------------------------------------------
            {'checkbox',  0,10,3,1,label:'&Select', name:'select_errors', value:cfg.select_errors}
            {'checkbox',  3,10,3,1,label:'&Report to <Effect>', name:'list_errors', value:cfg.list_errors}
            {'checkbox',  7,10,1,1,label:'Sho&w in log', name:'log_errors', value:cfg.log_errors,
                                    hint:'...forced when both Select and Report are disabled'}
            {'checkbox',  0,11,9,1,label:'Process s&elected lines only', name:'selected_only',
                                   value:cfg.selected_only}
            {'dropdown',  0,12,9,1, name:'save', items:SAVE.list, value:cfg.save}
            {'label',     0,13,9,2,label:'Config: '..cfgsource}
        }
        --conform the dialog
        for c in *dlg
            for i,k in ipairs {'class','x','y','width','height'}
                c[k] = c[i]

    execute!
