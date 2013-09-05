export script_name = 'Add tags'
export script_description = 'Add tags to selected lines'

require 'utils'

aegisub.register_macro script_name, script_description, (subs, sel, act) ->
    local *
    local scope, location, loadprompt, btns, config, userconfigpath

    onetimeinit = ->

        return if config

        scope = all:'All lines', sel:'Selected lines', cur:'Current line'

        location = expandlist {
                {line:      'Line start'}
                {first_in:  '{...'}
                {each_in:   '{... all'}
                {first_out: '...}'}
                {each_out:  '...} all'}
            }

        loadprompt = 'Previous items...'

        btns = expandlist {
                {ok:    '&Add / reuse chosen item'}
                {load:  'Loa&d only'}
                {cancel:'&Cancel'}
            }

        config = -- defaults
            all:      false
            location: location.line
            scope:    scope.sel
            used:     {'\\be1','\\fad(100,100)','\\fs','\\fscx','\\fscy','\\alpha&H80&'}
        config.text = config.used[1]

        userconfigpath = aegisub.decode_path '?user/'..script_name..'.conf'

    execute = ->

        cfgread!
        showdialog!
        cfgwrite!

        txt = config.text
        config.scope = scope.sel if config.scope\find '^'..scope.sel
        local ovrbound, ovrtext, ovrnum
        switch config.location
            when location.line
                ovrbound = '^(.*)$'
                ovrtext = (s) ->
                    if s\sub(1,1) == '{'
                        s\gsub('^{(.-)}','{%1'..txt..'}')
                    else
                        '{'..txt..'}'..s
                ovrnum = 1
            when location.first_in  then ovrbound, ovrtext, ovrnum = '{', '{'..txt, 1
            when location.first_out then ovrbound, ovrtext, ovrnum = '}', txt..'}', 1
            when location.each_in   then ovrbound, ovrtext, ovrnum = '{', '{'..txt, nil
            when location.each_out  then ovrbound, ovrtext, ovrnum = '}', txt..'}', nil

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
            when scope.cur
                processline act,subs[act]
            else
                style = config.scope\gsub('^.*:%s+','')
                for i,s in ipairs subs
                    processline i,s if s.style==style

    showdialog = ->
        local cfg

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

    makedialog = ->
        _styles = {}
        for s in *subs
            table.insert _styles,'Style: '..s.name if s.class=='style'
            break if s.class=='dialogue'
        _scopeitems = {scope.all, scope.sel..' ('..tostring(#sel)..')', scope.cur, unpack _styles}
        _scope = if config.scope\find '^'..scope.sel then _scopeitems[2] else config.scope
        _used = table.copy config.used
        table.insert _used,1,loadprompt

        dlg = {
            {'textbox',  0,0,6,4, name:'text', text:config.text,
                                  hint:'Input tags to add'}
            {'dropdown', 0,4,1,1, name:'location', items:location.__list, value:config.location,
                                  hint:'Point of insertion:\n\tline start\n\tovrblock start / end'}
            {'dropdown', 1,4,3,1, name:'scope', items:_scopeitems, value:_scope,
                                  hint:'Scope of action:\n\tall lines\n\tselected lines\n\tspecific style'}
            {'dropdown', 4,4,2,1, name:'used', items:_used, value:loadprompt,
                                  hint:'Select value to use instead of the typed text'}
        }
        --conform the dialog
        for c in *dlg do for i,k in ipairs {'class','x','y','width','height'} do c[k] = c[i]
        dlg

    expandlist = (extendedlist) ->
        -- example:
        -- input: {{ok:'&Add'}, {load:'Loa&d...'}, {cancel:'&Cancel'}}
        -- output: {ok:'&Add', load:'Loa&d...', cancel:'&Cancel',
        --          __list: {'&Add', 'Loa&d...', '&Cancel'},
        --          __namedlist: {ok:'&Add', load:'Loa&d...', cancel:'&Cancel'}
        list = __list:{}, __namedlist:{}
        for LI in *extendedlist
            for k,v in pairs LI
                list[k] = v
                list.__namedlist[k] = v
                table.insert list.__list, v
        list

    min = (a,b) -> if a<b then a else b
    string.trim = => @\gsub('^%s+','')\gsub('%s+$','')
    string.split = (sepcharclass) => return for s in @\gmatch '([^'..sepcharclass..']+)' do s

    cfgread = ->
        if f = io.open userconfigpath,'r'
            splitkv = (kv) ->
                k,v = kv\match '^%s*(.-)%s*:%s*(.+)$'
                if v\find '|' then k,v\split '|' else k,v
            _cfg = {splitkv(kv) for kv in *f\read('*all')\split '\n\r'}
            config = _cfg if _cfg and _cfg.scope
            f\close!

    cfgwrite = ->
        if f = io.open userconfigpath,'w'
            s = ''
            for k,v in pairs config
                s ..= k..':'..(if type(v)=='table' then table.concat v,'|' else tostring v)..'\n'
            f\write s,'\n'
            f\close!
        else
            aegisub.log 'Error writing '..userconfigpath

    onetimeinit!
    execute!
    sel
