export script_name = 'Blame'
export script_description = table.concat {
        'Marks lines exceeding specified limits:'
        'min/max duration, CPS, line count, overlaps, missing styles.'
    },' '

require 'utils'
re = require 'aegisub.re'

aegisub.register_macro script_name..'/'..script_name, script_description, (subs, sel) ->
    local *
    local cfg, cfg_source, btns, dlg, cfg_user_path
    local playres, styles, cfg_line_indices, dialog_first, overlap_end, check_max_lines_enabled

    SAVE = {
        no:         "Apply and don't save settings"
        script:     "Apply and save settings in script"
        user:       "Apply and save settings in user config"
        remove_only:"Only remove saved settings from script"
    }

    DEFAULTS = {
        check_negative_duration:true,
        check_min_duration:true,      min_duration:1.0
        ignore_short_if_cps_ok:true
        check_max_duration:true,      max_duration:10.0
        check_max_lines:true,         max_lines:2
        check_max_chars_per_sec:true, max_chars_per_sec:25
        check_max_chars:true,         max_chars:100
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
        all_tags = table.concat [k for k,v in pairs .tag],'|'
        all_values = table.concat {
                [[(?<=fn)(?:[^\\}]*|\\|\s*$)|]]
                [[(?<=r)(?:[^\\}]*|\\|\s*$)|]]
                [[(?:[\s\\]+|-?[\d.]+|\s*$)]]
            },''
        tag_expr = [[\\((?:]]..all_tags..')(?:'..all_values..'))'
        .ovr_re = re.compile [[\{.*?]]..tag_expr..[[.*?\}]]
        .tag_re = re.compile tag_expr
        .tag_parts_re = re.compile '('..all_tags..')('..all_values..')'

    execute = ->
        cfg_read!
        init!

        btn, cfg = aegisub.dialog.display(dlg, {btns.ok, btns.cancel}, btns)
        aegisub.cancel! if not btn or btn == btns.cancel

        cfg_write!

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
        tosel = [v.i for num,v in ipairs lines when blame_line num,v,lines]

        if cfg.log_errors or not (cfg.list_errors or cfg.select_errors)
            aegisub.log '\n%d lines blamed.\n',#tosel
        if cfg.check_max_lines and (playres.x <= 0 or not video_loaded)
            err1 = "load video file" unless video_loaded
            err2 = "specify correct PlayRes in script's properties!" unless playres.x > 0
            aegisub.log '%s. %s%s%s%s.',
                'Max screen lines checking not performed',
                'Please, ',err1 or '',err1 and err2 and ' and ' or '',err2 or ''
        aegisub.progress.set 100

        tosel if cfg.select_errors

    blame_line = (num, v, lines) ->
        msg = ''
        {i:index, :line} = v
        with line
            duration = (.end_time - .start_time)/1000
            text_only = .text\gsub('{.-}','')\gsub('\\h',' ')
            text_length = text_only\gsub('\\N','')\gsub("[ ,.-!?&():;/<>|%%$+=_'\"]",'')\len!
            cps = if duration==0 then 0 else text_length/duration
            style = styles[.style] or styles['Default'] or styles['*Default']

            if not should_ignore_signs line
                if duration < 0 and cfg.check_negative_duration
                    msg   = (' negative%gs')\format duration

                if cfg.check_min_duration and duration < cfg.min_duration
                    if not cfg.ignore_short_if_cps_ok or math.floor(cps) > cfg.max_chars_per_sec
                        msg   = (' short%gs')\format duration

                if cfg.check_max_duration and duration > cfg.max_duration
                    msg ..= (' long%gs')\format duration

                if cfg.check_max_chars_per_sec and math.floor(cps) > cfg.max_chars_per_sec
                    msg ..= (' %dcps')\format cps

                if cfg.check_max_chars and text_length > cfg.max_chars
                    msg ..= (' +%dchars')\format (text_length - cfg.max_chars)

                if check_max_lines_enabled and style
                    num_lines = 0
                    if METRICS.q2_re\match .text
                        s = .text\gsub '\\N%s*{.-}%s*',''
                        num_lines = (#s - s\gsub('\\N','')\len!)/2 + 1
                    else
                        available_width = playres.x
                        available_width -= if .margin_r>0 then .margin_r else style.margin_r
                        available_width -= if .margin_l>0 then .margin_l else style.margin_l
                        available_width *= playres.real_x / playres.x
                        ovr_style = table.copy style

                        for subline in .text\gsub('\\N','\n')\split_iter '\n'
                            prev_span_start = 1
                            subline = subline\trim!

                            -- iterate blocks with {...\tags that alter width metrics...}
                            for ovr, ovrstart, ovrend in METRICS.ovr_re\gfind subline
                                num_lines += calc_numlines subline\sub(prev_span_start, ovrstart-1),
                                                          ovr_style, available_width
                                prev_span_start = ovrend + 1

                                tag_pos = 1
                                -- iterate width-altering \tags inside current {} block
                                -- and put overrides into style used for text width calculation
                                while true
                                    tag = METRICS.tag_re\match ovr, tag_pos
                                    break unless tag
                                    tag_pos = tag[2].last + 1

                                    tag_parts = METRICS.tag_parts_re\match tag[2].str
                                    tag.name, tag.value = tag_parts[2].str, tag_parts[3].str\trim!

                                    if tag.name=='r'
                                        ovr_style = table.copy styles[tag.value] or style
                                    else
                                        set_style ovr_style, tag, style

                            num_lines += calc_numlines subline\sub(prev_span_start),
                                                      ovr_style, available_width
                            num_lines = math.floor num_lines + 0.9999999999

                    msg ..= (' %dlines')\format num_lines if num_lines > cfg.max_lines

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
                    for ovr_style in ovr\gmatch '\\r([^}\\]+)'
                        missing = true unless styles[ovr_style]
                msg ..= ' nostyle' if missing

            msg = msg\sub(2)
            if (msg != '' or .effect != '') and msg != .effect and cfg.list_errors
                .effect = msg
                subs[index] = line

            if not cfg.list_errors or cfg.log_errors
                aegisub.progress.set num/#lines*100
                if msg != ''
                    aegisub.log '#%d, %s   %8s \t%s%s\n',
                        index - dialog_first + 1,
                        ms2str(.start_time),
                        msg,
                        text_only\sub(1,20),
                        (if #text_only > 20 then '...' else '')
        msg != ''

    should_ignore_signs = (line) -> cfg.ignore_signs and SIGNSre\match line.text

    set_style = (style, tag, fallback_style) ->
        field = METRICS.tag[tag.name]
        style[field] = if tag.value!='' then tag.value else fallback_style[field]

    calc_numlines = (text, style, available_width) ->
        ok,width = pcall aegisub.text_extents, style, text\gsub('{.-}','')\gsub('\\h',' ')
        return 0 unless ok
        return width/available_width

    max = (a, b) -> if a > b then a else b
    string.split_iter = (separator_chars) => @\gmatch '([^'..separator_chars..']+)'
    string.trim = => @\gsub('^%s+','')\gsub('%s+$','')
    string.val = =>
        s = @\trim!\lower!
        return true if s=='true'
        return false if s=='false'
        return tonumber s if s\match '^%-?[0-9.]+$'
        @
    ms2str = (ms) ->
        s = ('%02d:%02d:%02d')\format math.floor(ms/3600000),
            math.floor(ms/60000 % 60),
            math.floor(ms/1000 % 60)
        s\gsub('^00?:?0?','') -- strip 00:0 at the beginning

    cfg_serialize = (cfg, sep) ->
        return '' unless cfg
        table.concat [k..':'..tostring(v) for k,v in pairs cfg], sep

    cfg_deserialize = (str) ->
        kv2pair = (kv) -> unpack [i\val! for i in kv\split_iter ':']
        {kv2pair kv for kv in str\split_iter ',\n\r'}

    cfg_read = ->
        --load user config if script hasn't one
        cfg_user = '?user/'..script_name..'.conf'
        cfg_user_path = aegisub.decode_path cfg_user
        if not cfg
            f = io.open cfg_user_path,'r'
            if f
                ok, _cfg = pcall(cfg_deserialize, f\read '*all')
                if ok and _cfg.save
                    cfg_source = cfg_user
                    cfg = _cfg
                f\close!

        if not cfg
            cfg_source = 'defaults'
            cfg = table.copy DEFAULTS
        else
            cfg_default = false
            for k,v in pairs DEFAULTS
                cfg[k], cfg_default = v, true if cfg[k]==nil
            cfg_source ..= ' + defaults' if cfg_default

    cfg_write = ->
        switch cfg.save
            when SAVE.script
                subs.delete unpack cfg_line_indices if #cfg_line_indices > 0
                subs.append {class:'info', section:'Script Info', key:script_name, value:cfg_serialize(cfg,', ')}

            when SAVE.user
                f = io.open cfg_user_path,'w'
                if not f
                    aegisub.log 'Error writing '..cfg_user_path
                else
                    f\write cfg_serialize cfg,'\n'
                    f\close!

            when SAVE.remove_only
                subs.delete unpack cfg_line_indices if #cfg_line_indices > 0
                aegisub.cancel!

    init = ->
        playres = x:0, y:0, real_x:0
        styles = {}
        cfg_line_indices = {}
        dialog_first = 0

        for i,s in ipairs subs
            --assuming standard section order: info, styles, events
            switch s.class
                when 'info'
                    kl = s.key\lower!
                    if kl=='playresx' or kl=='playresy'
                        playres[kl\sub #kl] = tonumber s.value if s.value\match '^%s*%d+%s*$'
                    elseif s.key==script_name
                        table.insert cfg_line_indices, i
                        ok, _cfg = pcall(cfg_deserialize, s.value)
                        cfg, cfg_source = _cfg, 'script' if ok and _cfg.save
                when 'style'
                    styles[s.name] = s
                when 'dialogue'
                    dialog_first = i
                    break

        if aegisub.video_size!
            w,h,ar,ar_type = aegisub.video_size!
            playres.real_x = math.floor playres.y / h * w

        btns = ok:'&Go', cancel:'&Cancel'
        with SAVE
            .list = {.no, .script, .user, .remove_only}

        --accels: g(go) c(cancel) vnixlhdofAmsrwe
        dlg = {
            {'checkbox',  0,0,7,1, label:'Negati&ve duration', name:'check_negative_duration',
                                   value:cfg.check_negative_duration}
            ---------------------------------------------------------
            {'checkbox',  0,1,7,1, label:'Mi&n duration, seconds:', name:'check_min_duration',
                                   value:cfg.check_min_duration}
            {'floatedit', 7,1,2,1,  name:'min_duration', value:cfg.min_duration, min:0, max:10, step:0.1}
            ---------------------------------------------------------
            {'checkbox',  3,2,7,1, label:'&Ignore if CPS is ok', name:'ignore_short_if_cps_ok',
                                   value:cfg.ignore_short_if_cps_ok}
            ---------------------------------------------------------
            {'checkbox',  0,3,7,1, label:'Ma&x duration, seconds:', name:'check_max_duration',
                                   value:cfg.check_max_duration}
            {'floatedit', 7,3,2,1,  name:'max_duration', value:cfg.max_duration, min:0, max:100, step:1}
            ---------------------------------------------------------
            {'checkbox',  0,5,7,1, label:'Max screen &lines per subtitle', name:'check_max_lines',
                                   value:cfg.check_max_lines,
                                    hint:'Requires 1) PlayRes in script header 2) all used fonts installed'}
            {'intedit',   7,5,2,1,  name:'max_lines', value:cfg.max_lines, min:1, max:10}
            ---------------------------------------------------------
            {'checkbox',  0,6,7,1, label:'Max c&haracters per second', name:'check_max_chars_per_sec',
                                   value:cfg.check_max_chars_per_sec}
            {'intedit',   7,6,2,1,  name:'max_chars_per_sec', value:cfg.max_chars_per_sec, min:1, max:100}
            ---------------------------------------------------------
            {'checkbox',  0,7,7,1, label:'Max characters per &dialog event', name:'check_max_chars',
                                   value:cfg.check_max_chars}
            {'intedit',   7,7,2,1,  name:'max_chars', value:cfg.max_chars, min:1, max:1000}
            ---------------------------------------------------------
            {'checkbox',  0,9,3,1, label:'&Overlaps:', name:'check_overlaps', value:cfg.check_overlaps}
            {'checkbox',  3,9,5,1, label:'...report only the &first in group', name:'list_only_first_overlap',
                                   value:cfg.list_only_first_overlap}
            ---------------------------------------------------------
            {'checkbox',  0,10,9,1, label:'Ignore &ALL RULES ABOVE on signs', name:'ignore_signs',
                                   value:cfg.ignore_signs, hint:SIGNS}
            ---------------------------------------------------------
            {'checkbox',  0,12,9,1, label:'&Missing style definitions', name:'check_missing_styles',
                                   value:cfg.check_missing_styles}
            ---------------------------------------------------------
            {'checkbox',  0,14,3,1,label:'&Select', name:'select_errors', value:cfg.select_errors}
            {'checkbox',  3,14,3,1,label:'&Report to <Effect>', name:'list_errors', value:cfg.list_errors}
            {'checkbox',  7,14,1,1,label:'Sho&w in log', name:'log_errors', value:cfg.log_errors,
                                    hint:'...forced when both Select and Report are disabled'}
            {'checkbox',  0,15,9,1,label:'Process s&elected lines only', name:'selected_only',
                                   value:cfg.selected_only}
            {'dropdown',  0,17,9,1, name:'save', items:SAVE.list, value:cfg.save}
            {'label',     0,18,9,2,label:'Config: '..cfg_source}
        }
        --conform the dialog
        for c in *dlg
            for i,k in ipairs {'class','x','y','width','height'}
                c[k] = c[i]

    execute!

-------------------------------------------------------------------------

for v in *{{-1,'previous'},{1,'next'}}
    name = 'Go to '..v[2]
    aegisub.register_macro script_name..'/'..name, name..' blemished line',
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
