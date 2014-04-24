export script_name = 'Position shifter'
export script_description = 'Shifts positions in selected lines with \pos,\move,\org,\clip,\p'

aegisub.register_macro script_name, script_description, (subs, sel) ->
    dlg = {
        {'label',     0,0,1,1, label:'\\pos'}
        {'floatedit', 1,0,1,1, name:'pos_x', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift x coordinate of \pos'}
        {'floatedit', 2,0,1,1, name:'pos_y', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift y coordinate of \pos'}

        {'label',     0,1,1,1, label:'\\move'}
        {'floatedit', 1,1,1,1, name:'move_x1', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift first x coordinate of \move'}
        {'floatedit', 2,1,1,1, name:'move_y1', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift first y coordinate of \move'}
        {'floatedit', 3,1,1,1, name:'move_x2', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift second x coordinate of \move'}
        {'floatedit', 4,1,1,1, name:'move_y2', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift second y coordinate of \move'}

        {'label',     0,2,1,1, label:'\\org'}
        {'floatedit', 1,2,1,1, name:'org_x', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift x coordinate of \org'}
        {'floatedit', 2,2,1,1, name:'org_y', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift y coordinate of \org'}

        {'label',     0,3,1,1, label:'\\clip'}
        {'floatedit', 1,3,1,1, name:'clip_x', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift x coordinate of \clip'}
        {'floatedit', 2,3,1,1, name:'clip_y', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift y coordinate of \clip'}

        {'label',     0,4,1,1, label:'\\p'}
        {'floatedit', 1,4,1,1, name:'p_x', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift x coordinate of \p drawing'}
        {'floatedit', 2,4,1,1, name:'p_y', value:0.0, min:-99999.0, max:99999.0, step:1.0, hint:'Shift y coordinate of \p drawing'}
    }
    for c in *dlg do for i,k in ipairs {'class','x','y','width','height'} do c[k] = c[i] --conform the dialog

    btns = ok:'&Shift', cancel:'&Cancel'
    btn,cfg = aegisub.dialog.display dlg, {btns.ok, btns.cancel}, btns

    aegisub.cancel! if not btn or btn==btns.cancel

    with cfg
        .pos  = {.pos_x, .pos_y}
        .org  = {.org_x, .org_y}
        .move = {.move_x1, .move_y1, .move_x2, .move_y2}
        .clip = {.clip_x, .clip_y, .clip_x, .clip_y}
        .p    = {.p_x, .p_y}

    float2str = (f) -> string.format '%g',f
    arraysum2str = (arr1str,arr2) -> unpack [float2str arr2[i] + tonumber arr1str[i] for i=1,#arr1str]

    changed = false

    for k,i in ipairs sel
    	aegisub.progress.set k/#sel*100

        line = subs[i]
        s = line.text

        s = s\gsub '\\pos%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)',
            (x,y) -> ('\\pos(%s,%s)')\format arraysum2str({x,y}, cfg.pos)

        s = s\gsub '\\move%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)',
            (x,y,x2,y2) -> ('\\move(%s,%s,%s,%s')\format arraysum2str({x,y,x2,y2}, cfg.move)

        s = s\gsub '\\org%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)',
            (x,y) -> ('\\org(%s,%s)')\format arraysum2str({x,y}, cfg.org)

        s = s\gsub '\\(i?clip)%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)',
            (tag,x,y,x2,y2) -> ('\\%s(%s,%s,%s,%s)')\format tag, arraysum2str({x,y,x2,y2}, cfg.clip)

        s = s\gsub '\\(i?clip%(%s*%d*%s*%,?)([mlbsc%s%d%-]+)%)',
            (tag,numbers) -> ('\\%s%s)')\format tag,
                numbers\gsub '(-?%d+)%s*(-?%d+)',
                    (x,y) -> ('%d %d')\format arraysum2str({x,y}, cfg.clip)

        s = s\gsub '({.-\\p%d+.-})([mlbsc%s%d%-]+)',
            (tag,numbers) -> ('%s%s)')\format tag,
                numbers\gsub '(-?%d+)%s*(-?%d+)',
                    (x,y) -> ('%d %d')\format arraysum2str({x,y}, cfg.p)

        changed = true if line.text != s
        line.text = s
        subs[i] = line

    if not changed
        aegisub.log 'Nothing was changed.'
        aegisub.cancel!

    sel
