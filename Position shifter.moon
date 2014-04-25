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
        .move = {.move_x1, .move_y1, .move_x2, .move_y2}
        .clip = {.clip_x, .clip_y, .clip_x, .clip_y}

    arraysum = (arr, delta) ->
    	unpack [delta[i] + tonumber arr[i] for i=1,#arr]

    drawingsum = (s, dx, dy) ->
    	s\gsub '(-?%d+)%s*(-?%d+)',
        	(x,y) -> (math.floor x + dx + 0.5)..' '..(math.floor y + dy + 0.5)

    digit = '(%s*%-?[%d%.]+%s*)'
    replacer = {
    	{	'\\pos'
    		'\\pos%('..digit..','..digit..'%)'
    		(x,y) -> ('\\pos(%g,%g)')\format x + cfg.pos_x, y + cfg.pos_y
    	}
    	{	'\\move'
    		'\\move%('..digit..','..digit..','..digit..','..digit
    		(x,y,x2,y2) -> ('\\move(%g,%g,%g,%g')\format arraysum {x,y,x2,y2}, cfg.move
    	}
    	{	'\\org'
    		'\\org%('..digit..','..digit..'%)'
    		(x,y) -> ('\\org(%g,%g)')\format x + cfg.org_x, y + cfg.org_y
    	}
    	{	'\\i?clip'
    		'(\\i?clip)%('..digit..','..digit..','..digit..','..digit..'%)'
	        (tag,x,y,x2,y2) -> ('%s(%g,%g,%g,%g)')\format tag, arraysum {x,y,x2,y2}, cfg.clip
	    }
    	{	'\\i?clip'
    		'(\\i?clip%(%s*%d*%s*%,?)([mlbsc%s%d%-]+)%)'
	        (tag,numbers) -> tag..drawingsum numbers, cfg.clip_x, cfg.clip_y
	    }
    	{	'\\p%d'
    		'({.-\\p%d+.-})([mlbsc%s%d%-]+)'
	        (tag,numbers) -> tag..drawingsum numbers, cfg.p_x, cfg.p_y
	    }
	}

    changed = false

    for k,i in ipairs sel
    	aegisub.progress.set k/#sel*100

        line = subs[i]
        s = line.text

        for r in *replacer
       		s = s\gsub r[2],r[3] if s\find r[1]

        if line.text != s
        	changed = true
	        line.text = s
	        subs[i] = line

    if not changed
        aegisub.log 'Nothing was changed.'
        aegisub.cancel!

    sel
