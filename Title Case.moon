export script_name = 'Title Case'
export script_description = 'Applies English Title Case to selected lines'

local *
re = require 'aegisub.re'

lcase = ' a an and as at but by en for if in of on or the to v v. via vs vs. '

aegisub.register_macro script_name, script_description, (subs, sel) ->
    for i in *sel
        with line = subs[i]
            linestart = true
            prevblockpunct = ''

            s = .text\gsub('\\N','\n')\gsub('\\n','\r')\gsub('\\h','\a')

            s = ('{}'..s)\gsub '(%b{})([^{]+)', (tag, text) ->
                blockstart = true
                tag..text\gsub "([!?.\"”»') ]-)([^`~!@#$%^&*()_=+[%]{};:\"\\|,./<>%s-]+)", (punct, word) ->
                    newsentence = ((blockstart and prevblockpunct or '')..punct)\match('[.!?]')
                    first = rxFirst\match(word)[1].str
                    first = if linestart or newsentence or not lcase\find(' '..word\lower!..' ')
                        first\utf8upper!
                    else
                        first\utf8lower!

                    linestart = false
                    blockstart = false
                    prevblockpunct = punct

                    punct..first..word\sub(#first + 1)\utf8lower!

            s = s\sub(3)\gsub('\n','\\N')\gsub('\r','\\n')\gsub('\a','\\h')
            if s != .text
                .text = s
                subs[i] = line


rxFirst = re.compile '^(.)', re.NOSUB
rxAccentsU = re.compile '[ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞ]', re.NOSUB
rxAccentsL = re.compile '[àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþ]', re.NOSUB

accentsU = ['à']:'À', ['á']:'Á', ['â']:'Â', ['ã']:'Ã', ['ä']:'Ä', ['å']:'Å', ['æ']:'Æ', ['ç']:'Ç', ['è']:'È', ['é']:'É', ['ê']:'Ê', ['ë']:'Ë', ['ì']:'Ì', ['í']:'Í', ['î']:'Î', ['ï']:'Ï', ['ð']:'Ð', ['ñ']:'Ñ', ['ò']:'Ò', ['ó']:'Ó', ['ô']:'Ô', ['õ']:'Õ', ['ö']:'Ö', ['ø']:'Ø', ['ù']:'Ù', ['ú']:'Ú', ['û']:'Û', ['ü']:'Ü', ['ý']:'Ý', ['þ']:'Þ'
accentsL = ['À']:'à', ['Á']:'á', ['Â']:'â', ['Ã']:'ã', ['Ä']:'ä', ['Å']:'å', ['Æ']:'æ', ['Ç']:'ç', ['È']:'è', ['É']:'é', ['Ê']:'ê', ['Ë']:'ë', ['Ì']:'ì', ['Í']:'í', ['Î']:'î', ['Ï']:'ï', ['Ð']:'ð', ['Ñ']:'ñ', ['Ò']:'ò', ['Ó']:'ó', ['Ô']:'ô', ['Õ']:'õ', ['Ö']:'ö', ['Ø']:'ø', ['Ù']:'ù', ['Ú']:'ú', ['Û']:'û', ['Ü']:'ü', ['Ý']:'ý', ['Þ']:'þ'

string.utf8lower = => rxAccentsU\sub @\lower!, (char) -> accentsL[char]
string.utf8upper = => rxAccentsL\sub @\upper!, (char) -> accentsU[char]
