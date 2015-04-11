export script_name = 'Title Case'
export script_description = 'Applies English Title Case to selected lines'

lcase = ' a an and as at but by en for if in of on or the to v v. via vs vs. '

aegisub.register_macro script_name, script_description, (subs, sel) ->
    for i in *sel
        with line = subs[i]
            linestart = true
            prevblockpunct = ''
            s = .text\gsub('\\N','\n')\gsub('\\n','\r')
            s = ('{}'..s)\gsub '(%b{})([^{]+)', (tag, text) ->
                blockstart = true
                tag..text\gsub "([!?.\"”»') ]-)([^`~!@#$%^&*()_=+[%]{};:\"\\|,./<>%s-]+)", (punct, word) ->
                    newsentence = ((blockstart and prevblockpunct or '')..punct)\match('[.!?]')
                    first = if linestart or newsentence or not lcase\find(' '..word\lower!..' ')
                        word\sub(1,1)\upper!
                    else
                        word\sub(1,1)\lower!

                    linestart = false
                    blockstart = false
                    prevblockpunct = punct

                    punct..first..word\sub(2)\lower!

            s = s\sub(3)\gsub('\n','\\N')\gsub('\r','\\n')
            if s != .text
                .text = s
                subs[i] = line