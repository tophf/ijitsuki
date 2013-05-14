export script_name = "Add tags"
export script_description = "Add tags to selected lines"

aegisub.register_macro script_name, script_description, (subs, sel) ->
    local *

    scope = sel:"Selected Lines", all:"All lines"
    location = line:"Line start", each_in:"{...", each_out:"...}"

    execute = ->
        btns = ok:"&Add", cancel:"&Cancel"
        btn, cfg = aegisub.dialog.display makedialog!, btns

        aegisub.cancel() if btn != btns.ok

        txt = cfg.text
        ovrnum = if cfg.all then nil else 1
        ovrbound, ovrtext = switch cfg.location
            when location.line     then "^", "{"..txt.."}"
            when location.each_in  then "{", "{"..txt
            when location.each_out then "}", txt.."}"

        processline = (i,line) ->
            if line.class=="dialogue"
                line.text = line.text\gsub ovrbound, ovrtext, ovrnum
                subs[i] = line

        switch cfg.scope
            when scope.all
                for i,s in ipairs subs do processline i,s
            when scope.sel
                for i in *sel do processline i,subs[i]
            else
                style = cfg.scope\gsub("^.*:%s+","")
                for i,s in ipairs subs
                    if s.style==style then processline i,s

    makedialog = ->
        _location = {location.line, location.each_in, location.each_out}
        _scope = {scope.all, scope.sel, unpack liststyles!}
        dlg = {
            {"checkbox", 0,0,5,1, name:"all", value:false, label:"Add to all tag fields in line?"}
            {"label",    0,1,1,1, label:"location:"}
            {"dropdown", 1,1,5,1, name:"location", items:_location, value:location.line, hint:"Add to line start, tag start or tag end"}
            {"label",    0,2,1,1, label:"Select:"}
            {"dropdown", 1,2,5,1, name:"scope", items:_scope, value:scope.sel, hint:"Selected lines or specific style"}
            {"label",    0,3,1,1, label:"Tags:"}
            {"textbox",  1,3,12,3, name:"text", text:"\\", hint:"Input tags to add"}
        }
        for c in *dlg do for i,k in ipairs {'class','x','y','width','height'} do c[k] = c[i] --conform the dialog
        dlg

    liststyles = ->
        list = {}
        for i,s in ipairs subs
            table.insert list,"Style: "..s.name if s.class=="style"
            break if s.class=="dialogue"
        list

    execute!
    sel
