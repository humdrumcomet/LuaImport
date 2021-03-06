eqtTable = {}
figTable = {}
tblTable = {}

function newFig(kind, figName, props)
    local kind = kind or 'reg'
    local kindSup = {
            tikz = [[\includestandalone]],
            reg = [[\includegraphics]]
        }

    figTable[figName] = {
        kind = kindSup[kind],
        positioning = 'tbh',
        centeringOpen = [[\begin{centering}]],
        centeringClose = [[\end{centering}]],
        size = [[width=0.8\textwidth]]
    }
    local trimmed = string.gsub(props, '^%s*(.-)%s*$', '%1')
    modStr = trimmed..[[,]]
    for key, value in string.gmatch(modStr, '(%w-)%s*=%s*(%b{}),') do
        figTable[figName][key] = string.gsub(value, '^{(.-)}$', '%1')
    end

    if figTable[figName]['centering'] == 'false' then
        figTable[figName]['centeringOpen'] = ''
        figTable[figName]['centeringClose'] = ''
    end
end

function newEqt(kind, eqtName, finEqt, initEqt, interEqt)
    kind = kind or 'equation'
    eqtExt = eqtExt or ''
    eqtTable[eqtName] = {
        kind = kind,
        initEqt = initEqt or '',
        interEqt = interEqt or '',
        finEqt = finEqt
    }
    --print(eqtName, kind, eq)
end

function newGl(kind, name, inputStr)
    --Order is:
    --callName
    --type -> gls, acr (can add ext, pl), cst, sym
    --name
    --description
    --plural form
    --plural description
    --extended description
    local typeCall = {
        cst = [[type=constants, ]],
        sym = [[type=symbols, ]],
        acr = [[type=\acronymtype, ]],
        gls = ''
    }
    local acrG = ''
    local acrPl = ''
    local glsAdd = ''
    if type(inputStr)=='string' then
        inputs = {kind = kind, name = name}
        trimmed = string.gsub(inputStr, '^%s*(.-)%s*$', '%1')
        modStr = trimmed..[[,]]
        for key, value in string.gmatch(modStr, '(%w-)%s*=%s*(%b{}),') do
            inputs[key] = string.gsub(value, '^{(.-)}$', '%1')
        end
        if inputs.descriptionExt then
            acrG = [[see=[Glossary:]{]]..inputs.name..[[g}} \newglossaryentry{]]..
                    inputs.name..[[g}{name={\glsentrytext{]]..
                    inputs.name..[[}}, description={]]..inputs.descriptionExt..[[}]]

            glsAdd = [[\glsadd{]]..inputs.name..[[g}]]
        end
        if inputs.displayPl then
            acrPl = [[plural={]]..inputs.displayPl..[[}, descriptionplural={]]..
                    inputs.descriptionPl..[[}, firstplural={\glsentrydescplural{]]..
                    inputs.name..[[} (\glsentryplural{]]..inputs.name..[[})]]..glsAdd..[[},]]
        end
    else
        inputs = inputStr
        print('----in gls')
        print(inputs.kind)
    end

    callBuild = {
        base = function(inputs) return [[\newglossaryentry{]]..inputs.name..[[}{]]..
                    typeCall[inputs.kind]..[[name={]]..
                    inputs.display..[[}, description={]]..
                    inputs.description..[[},]] end,

        cst = function(inputs) return callBuild.base(inputs)..[[}]] end,
        sym = function(inputs) return callBuild.base(inputs)..[[}]] end,
        gls = function(inputs) return callBuild.base(inputs)..[[}]] end,
        acr = function(inputs) return callBuild.base(inputs)..[[first={\glsentrydesc{]]..
                inputs.name..[[} (\glsentrytext{]]..inputs.name..[[})]]..glsAdd..[[}, ]]..
                acrPl..acrG..[[}]] end,
    }
    texString = callBuild[inputs.kind](inputs)
    tex.sprint(texString..' ')

end

function insertFigFromTable(figName)
    figStr = [[\begin{figure}[]]..figTable[figName]['positioning']..']'..
                figTable[figName]['centeringOpen']..figTable[figName]['kind']..
                [[[]]..figTable[figName]['size']..[[]{]]..figTable[figName]['path']..
                [[} \caption{]]..figTable[figName]['caption']..[[} \label{fig:]]..figName..
                [[}]]..figTable[figName]['centeringClose']..[[\end{figure}]]
    --print(figStr)
    tex.sprint(figStr)
end

function insertEqtFromTable(eqtName, opts)
    optsTable = optsToTable(opts)
    vers = optsTable['vers'] or 'fin'
    numPrint = optsTable['numPrint'] or 'nochg'
    surroundKind = optsTable['surround'] or 'full'
    --eqKind = eqtTable[eqtName]['kind'] or 'equation'
    eqKind = optsTable['kind'] or 'equation'
    if vers == 'showExp' or vers == 'showExpFull' then
        eqKind = 'align'
    end
    --print(eqKind)
    append = {
        nochg = '',
        nonum = [[\nonumber]],
        newLine = [[\\]]
    }
    surroundBegin = {
        full = [[\begin{]]..eqKind..[[}]],
        inline = [[$]]
    }
    surroundEnd = {
        full = [[\label{eqt:]]..eqtName..[[}\end{]]..eqKind..[[}]],
        inline = [[$]]

    }
    equation = {
        init = eqtTable[eqtName]['initEqt'],
        inter = eqtTable[eqtName]['interEqt'],
        fin = eqtTable[eqtName]['finEqt'],
        showExp = string.gsub(eqtTable[eqtName]['initEqt'], ' = ', ' &= ')..' '..
                append['nonum']..append['newLine'] ..' '..
                string.gsub(eqtTable[eqtName]['finEqt'], ' = ', ' &= '),
        showExpFull = string.gsub(eqtTable[eqtName]['initEqt'], ' = ', ' &= ')..' '..
                append['nonum']..append['newLine'] ..' '..
                string.gsub(eqtTable[eqtName]['interEqt'], ' = ', ' &= ')..' '..
                append['nonum']..append['newLine'] ..' '..
                string.gsub(eqtTable[eqtName]['finEqt'], ' = ', ' &= ')
    }
    eqStr = surroundBegin[surroundKind]..equation[vers]..append[numPrint]..surroundEnd[surroundKind]
    tex.sprint(eqStr)
end
