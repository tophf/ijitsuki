export script_name = 'Blame'
export script_description = 'Finds lines exceeding specified limits: min/max duration, CPS, line count, etc.'

require "utils"

aegisub.register_macro script_name, script_description, (subs, sel) ->
    local *
    local cfg, cfgsource, btns, dlg, userconfigpath
    local playresX, styles, cfglineindices, dialogfirst, overlap_end

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
        ignore_typeset:true
        selected_only:false
        select_errors:true
        list_errors:true
        log_errors:false
        save:SAVE.user
    }

    TYPESETREGEXP = [[\{.*?\\(pos|move|k|kf|ko|K|t|fax|fay|org|frx|fry|frz|an)[^a-zA-Z].*?\}]]

    execute = ->
        cfgread!
        init!

        btn, cfg = aegisub.dialog.display(dlg, {btns.ok, btns.cancel}, btns)
        aegisub.cancel! if not btn or btn == btns.cancel

        cfgwrite!

        lines = if cfg.selected_only
                    for i in *sel
                        continue if subs[i].comment
                        {i:i,line:subs[i]}
                else
                    for i,line in ipairs subs
                        continue if line.class!='dialogue' or line.comment
                        {i:i,line:line}

        if cfg.check_overlaps
            overlap_end = 0
            table.sort lines, (a,b) ->
                a_t,b_t = a.line.start_time, b.line.start_time
                a_t < b_t or (a_t == b_t and a.i < b.i)

        tosel = [v.i for num,v in ipairs lines when blameline num,v,lines]

        if cfg.log_errors or not (cfg.list_errors or cfg.select_errors)
            aegisub.log '\n'..#tosel..' lines blamed.\n'
        if playresX<=0
            aegisub.log '%s %s',
                'Max screen lines checking not performed',
                'due to absent/invalid script horizontal resolution (PlayResX)'
        aegisub.progress.set 100

        tosel if cfg.select_errors

    blameline = (num, v, lines) ->
        msg = ''
        {:i,:line} = v
        with line
            duration = (.end_time - .start_time)/1000
            textonly = .text\gsub('{.-}','')\gsub('\\h',' ')
            length = textonly\gsub('\\N','')\gsub("[ ,.-!?&():;/<>|%%$+=_'\"]",'')\len!
            cps = if duration==0 then 0 else length/duration
            style = styles[.style] or styles['Default'] or styles['*Default']

            ignoretypeset = (line) -> cfg.ignore_typeset and TYPESETREGEXP\match line.text

            if not ignoretypeset line
                if cfg.check_min_duration and duration < cfg.min_duration
                    if not cfg.ignore_short_if_cps_ok or math.floor(cps) > cfg.max_chars_per_sec
                        msg   = (' short%gs')\format duration

                if cfg.check_max_duration and duration > cfg.max_duration
                    msg ..= (' long%gs')\format duration

                if cfg.check_max_chars_per_sec and math.floor(cps) > cfg.max_chars_per_sec
                    msg ..= (' %dcps')\format cps

                if cfg.check_max_lines and style and playresX>0
                    available_width = playresX
                    available_width -= if .margin_r>0 then .margin_r else style.margin_r
                    available_width -= if .margin_l>0 then .margin_l else style.margin_l
                    numlines = 0
                    for span in textonly\gsub('\\N','\n')\split_iter '\n'
                        width = ({aegisub.text_extents(style, span..' ')})[1]
                        --add one space to compensate aegisub.text_extents being too small
                        numlines += math.floor(width/available_width + 0.9999999999)
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
                            cnt += 1 if not ignoretypeset L
                        msg ..= ' ovr'..cnt if cnt > 0

            if cfg.check_missing_styles
                missing = styles[.style]==nil
                for ovr in .text\gmatch "{(.*\\r.*)}"
                    for ovrstyle in ovr\gmatch "\\r([^}\\]+)"
                        missing = true unless styles[ovrstyle]
                msg ..= ' nostyle' if missing

            msg = msg\sub(2)
            if (msg != '' or .effect != '') and msg != .effect and cfg.list_errors
                .effect = msg
                subs[i] = line

            if not cfg.list_errors or cfg.log_errors
                aegisub.log '%d: %s\t%s%s\n',
                    i - dialogfirst + 1,
                    msg,
                    textonly\sub(1,20),
                    (if #textonly > 20 then '...' else '') if msg != ''
                aegisub.progress.set num/#subs*100
        msg != ''

    max = (a, b) -> if a>b then a else b
    string.split_iter = (sepcharclass) => @\gmatch '([^'..sepcharclass..']+)'
    string.trim = => @\gsub('^%s+','')\gsub('%s+$','')
    string.val = => @=='true' and (@=='true' or @=='false') or tonumber(@) and @\match('^%s*[0-9.]+%s*$') or @

    cfgserialize = (t, sep) -> if t then table.concat [k..':'..tostring(v) for k,v in pairs t], sep else ''
    cfgdeserialize = (s) -> {unpack [i\trim!\val! for i in kv\split_iter ':'] for kv in s\split_iter ',\n\r'}
    cfgread = ->
        --load user config if script hasn't one
        userconfig = '?user/'..script_name..'.conf'
        userconfigpath = aegisub.decode_path userconfig
        if not cfg
            f = io.open userconfigpath,'r'
            if f
                ok,_cfg = pcall cfgdeserialize, f\read '*all'
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
        playresX = 0
        styles = {}
        cfglineindices = {}
        dialogfirst = 0

        for i,s in ipairs subs
            --assuming standard section order: info, styles, events
            switch s.class
                when 'info'
                    playresX = tonumber(s.value) if s.key=='PlayResX' and s.value\match '^%s*%d+%s*$'
                    if s.key==script_name
                        table.insert cfglineindices, i
                        ok,_cfg = pcall cfgdeserialize, s.value
                        cfg,cfgsource = _cfg,'script' if ok and _cfg.save
                when 'style'
                    styles[s.name] = s
                when 'dialogue'
                    dialogfirst = i
                    break

        btns = ok:'&Go', cancel:'&Cancel'
        with SAVE
            .list = {.no, .script, .user, .removeonly}

        --accels: gcnixlhoftmsrwe
        dlg = {
            {'checkbox',  0,0,7,1, label:'Mi&n duration, seconds:', name:'check_min_duration', value:cfg.check_min_duration}
            {'floatedit', 7,0,2,1,  name:'min_duration', value:cfg.min_duration, min:0, max:10, step:0.1}

            {'checkbox',  0,1,9,1, label:'&Ignore if CPS is ok', name:'ignore_short_if_cps_ok', value:cfg.ignore_short_if_cps_ok}

            {'checkbox',  0,2,7,1, label:'Ma&x duration, seconds:', name:'check_max_duration', value:cfg.check_max_duration}
            {'floatedit', 7,2,2,1,  name:'max_duration', value:cfg.max_duration, min:0, max:100, step:1}

            {'checkbox',  0,3,7,1, label:'Max screen &lines per subtitle', name:'check_max_lines', value:cfg.check_max_lines,
                                    hint:'Requires 1) playresX in script header 2) all used fonts installed'}
            {'intedit',   7,3,2,1,  name:'max_lines', value:cfg.max_lines, min:1, max:10}

            {'checkbox',  0,4,7,1, label:'Max c&haracters per second', name:'check_max_chars_per_sec', value:cfg.check_max_chars_per_sec}
            {'intedit',   7,4,2,1,  name:'max_chars_per_sec', value:cfg.max_chars_per_sec, min:1, max:100}

            {'checkbox',  0,5,3,1, label:'&Overlaps:', name:'check_overlaps', value:cfg.check_overlaps}
            {'checkbox',  3,5,5,1, label:'...report only the &first in group', name:'list_only_first_overlap', value:cfg.list_only_first_overlap}

            {'checkbox',  0,6,9,1, label:'Skip ALL RULES ABOVE on &typeset', name:'ignore_typeset', value:cfg.ignore_typeset,
                                    hint:TYPESETREGEXP}

            {'checkbox',  0,8,9,1, label:'&Missing style definitions', name:'check_missing_styles', value:cfg.check_missing_styles}

            {'checkbox',  0,10,3,1,label:'&Select', name:'select_errors', value:cfg.select_errors}
            {'checkbox',  3,10,3,1,label:'&Report to <Effect>', name:'list_errors', value:cfg.list_errors}
            {'checkbox',  7,10,1,1,label:'Sho&w in log', name:'log_errors', value:cfg.log_errors,
                                    hint:'...forced when both Select and Report are disabled'}
            {'checkbox',  0,11,9,1,label:'Process s&elected lines only', name:'selected_only', value:cfg.selected_only}
            {'dropdown',  0,12,9,1, name:'save', items:SAVE.list, value:cfg.save}
            {'label',     0,13,9,2,label:'Config: '..cfgsource}
        }
        for c in *dlg do for i,k in ipairs {'class','x','y','width','height'} do c[k] = c[i] --conform the dialog

        re = require "aegisub.re" --"re" conflicts with some other lua module installed by luarocks // (c) torque
        TYPESETREGEXP = re.compile TYPESETREGEXP

    execute!
