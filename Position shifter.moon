export script_name = "Position shifter"
export script_description = "Shifts positions in selected lines with \pos,\move,\org,\clip"

require "re"

aegisub.register_macro script_name, script_description, (subs, sel) ->
    local *

    checkrunnable = ->
        r = re.compile "\\{.*\\\\(?:pos|move|org|i?clip)\\s*\\(.*\\}", re.ICASE
        for i in *sel
            return true if r\match(subs[i].text)
        aegisub.log "You should select lines with \\pos or \\move or \\org or \\clip"
        aegisub.cancel()

    execute = ->
        btns = ok:"Shift", cancel:"Cancel"
        btn, cfg = aegisub.dialog.display(makedialog!, btns)

        aegisub.cancel() if btn != btns.ok

        with cfg
            .pos  = {.pos_x, .pos_y}
            .org  = {.org_x, .org_y}
            .move = {.move_x1, .move_y1, .move_x2, .move_y2}
            .clip = {.clip_x, .clip_y, .clip_x, .clip_y}

        float2str = (f) -> tostring(f)\gsub("%.(%d-)0+$","%.%1")\gsub("%.$","")
        arraysum2str = (arr1str,arr2) -> unpack [float2str(tonumber(arr1str[i]) + arr2[i]) for i=1,#arr1str]

        for i in *sel
            line = subs[i]
            s = line.text

            s = s\gsub "\\pos%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)",
                (x,y) -> ("\\pos(%s,%s)")\format arraysum2str({x,y}, cfg.pos)

            s = s\gsub "\\move%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)",
                (x,y,x2,y2) -> ("\\move(%s,%s,%s,%s")\format arraysum2str({x,y,x2,y2}, cfg.move)

            s = s\gsub "\\org%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)",
                (x,y) -> ("\\org(%s,%s)")\format arraysum2str({x,y}, cfg.org)

            s = s\gsub "\\(i?clip)%((%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*),(%s*%-?[%d%.]+%s*)%)",
                (tag,x,y,x2,y2) -> ("\\%s(%s,%s,%s,%s)")\format tag, arraysum2str({x,y,x2,y2}, cfg.clip)

            s = s\gsub "\\(i?clip%(%s*%d*%s*%,?)([mlbsc%s%d%-]+)%)",
                (tag,numbers) -> ("\\%s%s)")\format tag,
                    numbers\gsub "(-?%d+)%s*(-?%d+)",
                        (x,y) -> ("%d %d")\format float2str(x)+cfg.clip_x, float2str(y)+cfg.clip_y

            line.text = s
            subs[i] = line

    makedialog = ->
        dlg = {
            {"label",     0,0,1,1, label:"\\pos"}
            {"floatedit", 1,0,1,1, name:"pos_x", value:0.00, hint:"Shift x coordinate of \pos"}
            {"floatedit", 2,0,1,1, name:"pos_y", value:0.00, hint:"Shift y coordinate of \pos"}

            {"label",     0,1,1,1, label:"\\move"}
            {"floatedit", 1,1,1,1, name:"move_x1", value:0.00, hint:"Shift first x coordinate of \move"}
            {"floatedit", 2,1,1,1, name:"move_y1", value:0.00, hint:"Shift first y coordinate of \move"}
            {"floatedit", 3,1,1,1, name:"move_x2", value:0.00, hint:"Shift second x coordinate of \move"}
            {"floatedit", 4,1,1,1, name:"move_y2", value:0.00, hint:"Shift second y coordinate of \move"}

            {"label",     0,2,1,1, label:"\\org"}
            {"floatedit", 1,2,1,1, name:"org_x", value:0.00, hint:"Shift x coordinate of \org"}
            {"floatedit", 2,2,1,1, name:"org_y", value:0.00, hint:"Shift y coordinate of \org"}

            {"label",     0,3,1,1, label:"\\clip"}
            {"floatedit", 1,3,1,1, name:"clip_x", value:0.00, hint:"Shift x coordinate of \clip"}
            {"floatedit", 2,3,1,1, name:"clip_y", value:0.00, hint:"Shift y coordinate of \clip"}
        }
        for c in *dlg do for i,k in ipairs {'class','x','y','width','height'} do c[k] = c[i] --conform the dialog
        dlg

    checkrunnable!
    execute!
    sel
