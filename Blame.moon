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
        check_max_duration:true,      max_duration:10.0
        check_max_lines:true,         max_lines:2
        check_max_chars_per_sec:true, max_chars_per_sec:25
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
            textonly_withbreaks = .text\gsub('{.-}','')\gsub('\\h',' ')
            textonly = textonly_withbreaks\gsub('\\N','')\gsub("[ ,.-!?&():;/<>|%%$+=_'\"]",'')
            length = textonly\len()
            cps = if duration==0 then 0 else length/duration
            style = styles[.style] or styles['Default'] or styles['*Default']

            msg   = (' short%gs')\format duration if cfg.check_min_duration and duration < cfg.min_duration
            msg ..= (' long%gs')\format  duration if cfg.check_max_duration and duration > cfg.max_duration
            msg ..= (' %dcps')\format    cps      if cfg.check_max_chars_per_sec and math.floor(cps) > cfg.max_chars_per_sec

            if cfg.check_max_lines and style
                screen_estate_x = playresX - max(.margin_r, style.margin_r) - max(.margin_l, style.margin_l)
                lines = 0
                for span in textonly_withbreaks\gsub('\\N','\n')\split '\n'
                    lines += ({aegisub.text_extents(style, span)})[1]/screen_estate_x
                    lines = math.floor(lines) + 1 if lines - math.floor(lines) > 0
                msg ..= (' %dlines')\format lines if lines > cfg.max_lines

            msg = msg\sub(2)
            if (msg != '' or .effect != '') and msg != .effect and cfg.list_errors
                .effect = msg
                subs[i] = line

            if log_only
                aegisub.log '%d: %s\t%s%s\n',
                    i - firstdialogueline,
                    msg,
                    textonly_withbreaks\sub(1,20),
                    (if #textonly_withbreaks>20 then '...' else '') if msg != ''
                aegisub.progress.set i/#subs*100
        msg != ''

    max = (a,b) -> if a>b then a else b
    string.split = (sepcharclass) => @\gmatch '([^'..sepcharclass..']+)'
    string.trim = => @\gsub('^%s+','')\gsub('%s+$','')
    string.val = => @=='true' and (@=='true' or @=='false') or tonumber(@) and @\match('^%s*[0-9.]+%s*$') or @
    cfgserialize = (t,sep=', ') -> if t then table.concat [k..':'..tostring(v) for k,v in pairs t], sep else ''
    cfgdeserialize = (s) -> {unpack [i\trim!\val! for i in kv\split ':'] for kv in s\split ',\n\r'}

    -- init & collect info
    playresX = 384
    styles = {}
    cfglineindex = {}
    firstdialogueline = 0
    local cfg, cfgsource

    for i,s in ipairs subs
        --assuming standard section order: info, styles, events
        switch s.class
            when 'info'
                playresX = tonumber(s.value) if s.key=='PlayResX' and s.value\match '^%s*%d+%s*$'
                if s.key==script_name
                    table.insert cfglineindex, i
                    ok,_cfg = pcall cfgdeserialize, s.value
                    cfg,cfgsource = _cfg,'script' if ok and _cfg.save
            when 'style'
                styles[s.name] = s
            when 'dialogue'
                firstdialogueline = i
                break

    -- load user config if script hasn't one
    userconfigname = aegisub.decode_path('?user/'..script_name..'.conf')
    if not cfg
        f = io.open userconfigname,'r'
        if f
            ok,_cfg = pcall cfgdeserialize, f\read('*all')
            if ok and _cfg.save
                cfgsource = userconfigname
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
    BTNS = ok:'&Go', cancel:'&Cancel'
    with BTNS
        .list = {.ok, .cancel}
    with SAVE
        .list = {.no, .script, .user, .remove}

    dlg = {
        {'checkbox',  0,0,3,1, label:'Min duration, seconds:', name:'check_min_duration', value:cfg.check_min_duration}
        {'checkbox',  0,1,3,1, label:'Max duration, seconds:', name:'check_max_duration', value:cfg.check_max_duration}
        {'floatedit', 3,0,1,1, name:'min_duration', value:cfg.min_duration, min:0, max:10, step:0.1}
        {'floatedit', 3,1,1,1, name:'max_duration', value:cfg.max_duration, min:0, max:100, step:1}

        {'checkbox',  0,3,3,1, label:'Max screen lines per subtitle', name:'check_max_lines', value:cfg.check_max_lines}
        {'intedit',   3,3,1,1, name:'max_lines', value:cfg.max_lines, min:1, max:10}

        {'checkbox',  0,5,3,1, label:'Max characters per second', name:'check_max_chars_per_sec', value:cfg.check_max_chars_per_sec}
        {'intedit',   3,5,1,1, name:'max_chars_per_sec', value:cfg.max_chars_per_sec, min:1, max:100}

        {'checkbox',  0,7,4,1, name:'select_errors', label:'Select bad lines', value:cfg.select_errors}
        {'checkbox',  0,8,4,1, name:'list_errors', label:'List errors in Effect field', value:cfg.list_errors}
        {'dropdown',  0,9,4,1, name:'save', items:SAVE.list, value:cfg.save}
        {'label',     0,10,4,2,label:'Config: '..cfgsource}
        {'checkbox',  0,12,3,1, name:'selected_only', label:'Selected lines only', value:cfg.selected_only}
    }
    for c in *dlg do for k,v in pairs {class:c[1], x:c[2], y:c[3], width:c[4], height:c[5]} do c[k] = v --conform the dialog

    -- show dialog
    btn,cfg = aegisub.dialog.display(dlg, BTNS.list)

    aegisub.cancel() if btn != BTNS.ok

    switch cfg.save
        when SAVE.script
            subs.delete unpack cfglineindex if #cfglineindex > 0
            subs.append {class:'info', section:'Script Info', key:script_name, value:cfgserialize(cfg)}

        when SAVE.user
            f = io.open userconfigname,'w'
            if not f
                aegisub.log 'Error writing '..userconfigname
            else
                f\write cfgserialize cfg,'\n'
                f\close!

        when SAVE.remove
            subs.delete unpack cfglineindex if #cfglineindex > 0
            return

    -- process subs
    log_only = not cfg.select_errors and not cfg.list_errors
    if cfg.selected_only
        [i for i in *sel when blameline i,subs[i],cfg]
    else
        [i for i,s in ipairs subs when blameline i,s,cfg]

    aegisub.progress.set 100 if log_only
    nil if not cfg.select_errors
