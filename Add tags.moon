export script_name = 'Add tags'
export script_description = 'Add tags to selected lines'

require 'utils'

aegisub.register_macro script_name, script_description, (subs, sel, act) ->
    local *

    scope = all:'All lines', sel:'Selected Lines', curline:'Current line'
    location = line:'Line start', each_in:'{...', each_out:'...}'
    loadprompt = 'Do not use...'

    config = -- defaults
        all:      false
        location: location.line
        scope:    scope.sel
        used:     {'\\be1','\\fad(100,100)','\\fs','\\fscx','\\fscy','\\alpha&H80&'}
    config.text = config.used[1]

    userconfigpath = aegisub.decode_path '?user/'..script_name..'.conf'

    execute = ->

        if f = io.open userconfigpath,'r'
            ok,_cfg = pcall cfgdeserialize, f\read '*all'
            config = _cfg if ok and _cfg.scope
            f\close!

        showdialog!

        config.scope = scope.sel if config.scope\find '^'..scope.sel
        txt = config.text
        ovrnum = if config.all then nil else 1
        ovrbound, ovrtext = switch config.location
            when location.line     then '^', '{'..txt..'}'
            when location.each_in  then '{', '{'..txt
            when location.each_out then '}', txt..'}'

        processline = (i,line) ->
            with line
                if .class=='dialogue' and not .comment
                    .text = .text\gsub ovrbound, ovrtext, ovrnum
                    subs[i] = line

        switch config.scope
            when scope.all
                for i,s in ipairs subs do processline i,s
            when scope.sel
                for i in *sel do processline i,subs[i]
            when scope.curline
                processline act,subs[act]
            else
                style = config.scope\gsub('^.*:%s+','')
                for i,s in ipairs subs
                    processline i,s if s.style==style

    showdialog = ->
        local cfg
        btns = makebuttons {{ok:'&Add'}, {load:'Loa&d...'}, {cancel:'&Cancel'}}

        dlg = makedialog!

        while true
            btn,cfg = aegisub.dialog.display(dlg, btns.__list, btns.__namedlist)
            switch btn
                when btns.ok
                    break
                when btns.load
                    if cfg.used != loadprompt
                        for v in *dlg do
                            if v.name=='text'
                                v.text = cfg.used
                                break
                else
                    aegisub.cancel!

        for k,v in pairs cfg
            config[k] = v if type(v)==type(config[k])

        config.text = cfg.used if cfg.used != loadprompt

        config.used = for i=1,min 20,#config.used
            if config.used[i]\trim()==config.text\trim() then continue
            config.used[i]
        table.insert config.used,1,config.text

        if f = io.open userconfigpath,'w'
            f\write cfgserialize config,'\n'
            f\close!
        else
            aegisub.log 'Error writing '..userconfigpath

    makebuttons = (extendedlist) -> -- example: {{ok:'&Add'}, {load:'Loa&d...'}, {cancel:'&Cancel'}}
        btns = __list:{}, __namedlist:{}
        for L in *extendedlist
            for k,v in pairs L
                btns[k] = v
                btns.__namedlist[k] = v
                table.insert btns.__list, v
        btns

    makedialog = ->
        _styles = {}
        for s in *subs
            table.insert _styles,'Style: '..s.name if s.class=='style'
            break if s.class=='dialogue'
        _location = {location.line, location.each_in, location.each_out}
        _scopeitems = {scope.all, scope.sel..' ('..tostring(#sel)..')', scope.curline, unpack _styles}
        _scope = if config.scope\find '^'..scope.sel then _scopeitems[2] else config.scope
        _used = table.copy config.used
        table.insert _used,1,loadprompt

        dlg = {
            {'checkbox', 0,0,10,1, name:'all', value:config.all, label:'Add to all tag fields in line?'}
            {'label',    0,1,1,1, label:'Location:'}
            {'dropdown', 1,1,13,1, name:'location', items:_location, value:config.location, hint:'Add to line start, tag start or tag end'}
            {'label',    0,2,1,1, label:'Scope:'}
            {'dropdown', 1,2,13,1, name:'scope', items:_scopeitems, value:_scope, hint:'Selected lines or specific style'}
            {'label',    0,3,1,1, label:'Previous:'}
            {'dropdown', 1,3,13,1, name:'used', items:_used, value:loadprompt, hint:'Click "Add" to use the selected value .\nClick "Load" to load value into tag box'}
            {'label',    0,4,1,1, label:'Tags:'}
            {'textbox',  0,5,14,4, name:'text', text:config.text, hint:'Input tags to add'}
        }
        for c in *dlg do for i,k in ipairs {'class','x','y','width','height'} do c[k] = c[i] --conform the dialog
        dlg

    min = (a,b) -> if a<b then a else b
    string.trim = => @\gsub('^%s+','')\gsub('%s+$','')
    string.split = (sepcharclass) => return for s in @\gmatch '([^'..sepcharclass..']+)' do s
    cfgserialize = (t) ->
        s = ''
        for k,v in pairs t
            s ..= k..':'..(if type(v)=='table' then table.concat v,'|' else tostring v)..'\n'
        s

    cfgdeserialize = (s) ->
        splitkv = (kv) ->
            k,v = kv\match '^%s*(.-)%s*:%s*(.+)$'
            if v\find '|' then k,v\split '|' else k,v
        {splitkv(kv) for kv in *s\split '\n\r'}

    execute!
    sel
