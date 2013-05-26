export script_name = 'Blame'
export script_description = 'Marks lines exceeding specified limits: min/max duration, CPS, screen line count'

require "utils"

aegisub.register_macro script_name, script_description, (subs, sel) ->
    local *

    SAVE = {
        no:     "Apply and don't save settings"
        script: "Apply and save settings in script"
        user:   "Apply and save settings in user config"
        remove: "Only remove saved settings from script"
    }

    DEFAULTS = {
        check_min_duration:true,      min_duration:1.0
        ignore_short_if_cps_ok: true
        check_max_duration:true,      max_duration:10.0
        check_max_lines:true,         max_lines:2
        check_max_chars_per_sec:true, max_chars_per_sec:25
        check_missing_styles:true
        selected_only: false
        select_errors: true
        list_errors: true
        save: SAVE.script
    }

    blameline = (i,line,cfg) ->
        msg = ''
        with line
            return false if .class != 'dialogue' or .comment

            duration = (.end_time - .start_time)/1000
            textonly = .text\gsub('{.-}','')\gsub('\\h',' ')
            length = textonly\gsub('\\N','')\gsub("[ ,.-!?&():;/<>|%%$+=_'\"]",'')\len()
            cps = if duration==0 then 0 else length/duration
            style = styles[.style] or styles['Default'] or styles['*Default']

            if cfg.check_min_duration and duration < cfg.min_duration
                if not cfg.ignore_short_if_cps_ok or math.floor(cps) > cfg.max_chars_per_sec
                    msg   = (' short%gs')\format duration

            if cfg.check_max_duration and duration > cfg.max_duration
                msg ..= (' long%gs')\format duration

            if cfg.check_max_chars_per_sec and math.floor(cps) > cfg.max_chars_per_sec
                msg ..= (' %dcps')\format cps

            if cfg.check_max_lines and style and playresX>0
                screen_estate_x = playresX - max(.margin_r, style.margin_r) - max(.margin_l, style.margin_l)
                lines = 0
                for span in textonly\gsub('\\N','\n')\split_iter '\n'
                    lines += ({aegisub.text_extents(style, span)})[1]/screen_estate_x
                    lines = math.floor(lines) + 1 if lines - math.floor(lines) > 0
                msg ..= (' %dlines')\format lines if lines > cfg.max_lines

            if cfg.check_missing_styles
                missing = styles[.style]==nil
                for ovr in .text\gmatch "{(.*\\r.*)}"
                    for ovrstyle in ovr\gmatch "\\r([^}\\]+)"
                        missing = true if not styles[ovrstyle]
                msg ..= ' nostyle' if missing

            msg = msg\sub(2)
            if (msg != '' or .effect != '') and msg != .effect and cfg.list_errors
                .effect = msg
                subs[i] = line

            if log_only
                aegisub.log '%d: %s\t%s%s\n',
                    i - firstdialogueline,
                    msg,
                    textonly\sub(1,20),
                    (if #textonly > 20 then '...' else '') if msg != ''
                aegisub.progress.set i/#subs*100
        msg != ''

    max = (a,b) -> if a>b then a else b
    string.split_iter = (sepcharclass) => @\gmatch '([^'..sepcharclass..']+)'
    string.trim = => @\gsub('^%s+','')\gsub('%s+$','')
    string.val = => @=='true' and (@=='true' or @=='false') or tonumber(@) and @\match('^%s*[0-9.]+%s*$') or @
    cfgserialize = (t,sep=', ') -> if t then table.concat [k..':'..tostring(v) for k,v in pairs t], sep else ''
    cfgdeserialize = (s) -> {unpack [i\trim!\val! for i in kv\split_iter ':'] for kv in s\split_iter ',\n\r'}

    -- init & collect info
    playresX = 0
    styles = {}
    cfglineindices = {}
    firstdialogueline = 0
    local cfg, cfgsource

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
                firstdialogueline = i
                break

    -- load user config if script hasn't one
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

    -- create dialog
    BUTTONS = ok:'&Go', cancel:'&Cancel'
    with SAVE
        .list = {.no, .script, .user, .remove}

    dlg = {
        {'checkbox',  0,0,3,1, label:'Min duration, seconds:', name:'check_min_duration', value:cfg.check_min_duration}
        {'floatedit', 3,0,1,1,  name:'min_duration', value:cfg.min_duration, min:0, max:10, step:0.1}
        {'checkbox',  0,1,4,1, label:'Ignore min duration if CPS is ok', name:'ignore_short_if_cps_ok', value:cfg.ignore_short_if_cps_ok}
        {'checkbox',  0,2,3,1, label:'Max duration, seconds:', name:'check_max_duration', value:cfg.check_max_duration}
        {'floatedit', 3,2,1,1,  name:'max_duration', value:cfg.max_duration, min:0, max:100, step:1}

        {'checkbox',  0,3,3,1, label:'Max screen lines per subtitle', name:'check_max_lines', value:cfg.check_max_lines}
        {'intedit',   3,3,1,1,  name:'max_lines', value:cfg.max_lines, min:1, max:10}

        {'checkbox',  0,4,3,1, label:'Max characters per second', name:'check_max_chars_per_sec', value:cfg.check_max_chars_per_sec}
        {'intedit',   3,4,1,1,  name:'max_chars_per_sec', value:cfg.max_chars_per_sec, min:1, max:100}

        {'checkbox',  0,5,3,1, label:'Missing style definitions', name:'check_missing_styles', value:cfg.check_missing_styles}

        {'checkbox',  0,7,4,1,  name:'select_errors', label:'Select bad lines', value:cfg.select_errors}
        {'checkbox',  0,8,4,1,  name:'list_errors', label:'List errors in Effect field', value:cfg.list_errors}
        {'dropdown',  0,9,4,1,  name:'save', items:SAVE.list, value:cfg.save}
        {'label',     0,10,4,2,label:'Config: '..cfgsource}
        {'checkbox',  0,12,3,1, name:'selected_only', label:'Selected lines only', value:cfg.selected_only}
    }
    for c in *dlg do for i,k in ipairs {'class','x','y','width','height'} do c[k] = c[i] --conform the dialog

    -- show dialog
    btn, cfg = aegisub.dialog.display(dlg, BUTTONS)

    aegisub.cancel() if not btn or btn == BUTTONS.cancel

    switch cfg.save
        when SAVE.script
            subs.delete unpack cfglineindices if #cfglineindices > 0
            subs.append {class:'info', section:'Script Info', key:script_name, value:cfgserialize(cfg)}

        when SAVE.user
            f = io.open userconfigpath,'w'
            if not f
                aegisub.log 'Error writing '..userconfigpath
            else
                f\write cfgserialize cfg,'\n'
                f\close!

        when SAVE.remove
            subs.delete unpack cfglineindices if #cfglineindices > 0
            return

    -- process subs
    log_only = not cfg.select_errors and not cfg.list_errors
    tosel = if cfg.selected_only
                [i for i in *sel when blameline i,subs[i],cfg]
            else
                [i for i,s in ipairs subs when blameline i,s,cfg]

    if playresX<=0
        aegisub.log 'Max screen lines checking not performed due to absent/invalid script horizontal resolution (PlayResX)'
    aegisub.progress.set 100 if log_only or playresX<=0

    tosel if cfg.select_errors
