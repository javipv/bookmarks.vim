" Script Name: boomarks.vim
 "Description: 
"
" Copyright:   (C) 2019-2021
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  <javierpuigdevall@gmail.com>
"
" Dependencies: jpLib.vim
"


"- functions -------------------------------------------------------------------


" Get the plugin reload command
function! bookmarks#Reload()
    if exists("g:bookmarks_sessionFile")
        let l:sessionFile = g:bookmarks_sessionFile
    endif

    let l:pluginPath = substitute(s:plugin_path, "autoload", "plugin", "")
    let l:autoloadFile = s:plugin_path."/".s:plugin_name
    let l:pluginFile = l:pluginPath."/".s:plugin_name

    if exists("g:bookmarks_sessionFile")
        return "unlet loaded_bookmarks | so ".l:autoloadFile." | so ".l:pluginFile . " | let g:bookmarks_sessionFile = \"" . l:sessionFile . "\""
    else
        return "unlet loaded_bookmarks | so ".l:autoloadFile." | so ".l:pluginFile
    endif
endfunction


" Edit plugin files
" Cmd: Bkedit
function! bookmarks#EditPlugin()
    let l:plugin = substitute(s:plugin_path, "autoload", "plugin", "")
    silent exec("tabnew ".s:plugin)
    silent exec("vnew   ".l:plugin."/".s:plugin_name)
endfunction


function! s:Initialize()
    let s:verbose = 0
    let g:bookmarks_sessionFile = ""
    if exists("s:windowConfigList")
        unlet s:windowConfigList
    endif

    " Define sign configuration.
    sign define marks text=> texthl=none

    if g:bookmarks_loadSignsOnFileOpen
        " Load signs on file open.
        au BufReadPre,FileReadPre * call s:SignLoad()
        "au! BufReadPre,FileReadPre *
    endif

    "silent exec "silent! autocmd! WinEnter ".l:buffName." call s:QfMapKeys()"
    "silent exec "silent! autocmd! WinLeave ".l:buffName." call s:QfUnmapKeys()"
endfunction


function! s:Error(mssg)
    echohl ErrorMsg | echom "[".s:plugin."] ".a:mssg | echohl None
endfunction


function! s:Error(mssg)
    echohl ErrorMsg | echom "[".s:plugin."] ".a:mssg | echohl None
endfunction


function! s:Warn(mssg)
    echohl WarningMsg | echom a:mssg | echohl None
endfunction


function! s:Highlight(nomalMssgPre, hiMssg, nomalMssgPost)
    if a:nomalMssgPre != ""
        echo ""
        echon "".a:nomalMssgPre
    endif

    if a:nomalMssgPost != ""
        echohl WarningMsg | echon a:hiMssg | echohl None
        echon "".a:nomalMssgPost
    else
        echohl WarningMsg | echon a:hiMssg | echohl None
    endif

    echo ""
endfunction


function! s:Highlight2(nomalMssgPre1, hiMssg1, nomalMssgPost1, hiMssg2, nomalMssgPost2)
    if a:nomalMssgPre1 != ""
        echo ""
        echon "".a:nomalMssgPre1
    endif

    if a:nomalMssgPost1 != ""
        echohl WarningMsg | echon a:hiMssg1 | echohl None
        echon "".a:nomalMssgPost1
    else
        echohl WarningMsg | echon a:hiMssg1 | echohl None
    endif


    "if a:nomalMssgPre2 != ""
        "echon "".a:nomalMssgPre2
    "endif

    if a:nomalMssgPost2 != ""
        echohl WarningMsg | echon a:hiMssg2 | echohl None
        echon "".a:nomalMssgPost2
    else
        echohl WarningMsg | echon a:hiMssg2 | echohl None
    endif
endfunction


" Debug function. Log message
function! s:Verbose(level,func,mssg)
    if s:verbose >= a:level
        echom "[".s:plugin_name." : ".a:func." ] ".a:mssg
    endif
endfunction


" Debug function. Log message and wait user key
function! s:VerboseStop(level,func,mssg)
    if s:verbose >= a:level
        call input("[".s:plugin_name." : ".a:func." ] ".a:mssg." (press key)")
    endif
endfunction


function! s:Info(mssg)
    echo "[".s:plugin_name."] ".a:mssg
endfunction


" Command: Bkv
function! bookmarks#Verbose(level)
    if a:level == ""
        call s:Verbose(0, expand('<sfile>'), "Verbose level: ".s:verbose)
        return
    endif
    let s:verbose = a:level
    call s:Verbose(0, expand('<sfile>'), "Set verbose level: ".s:verbose)
endfunction


function! s:WindowSplitMenu(default)
    let w:winSize = winheight(0)
    let text =  "split hor&izontal\n&split vertical\nnew &tab\ncurrent &window"
    let w:split = confirm("", l:text, a:default)
    redraw
endfunction


function! s:WindowSplit()
    if !exists('w:split')
        return
    endif

    let l:split = w:split
    let l:winSize = w:winSize

    if w:split == 1
        silent exec("sp! | enew")
    elseif w:split == 2
        silent exec("vnew")
    elseif w:split == 3
        silent exec("tabnew")
    elseif w:split == 4
        silent exec("enew")
    endif

    let w:split = l:split
    let w:winSize = l:winSize - 2
endfunction


function! s:WindowSplitEnd()
    if exists('w:split')
        if w:split == 1
            if exists('w:winSize')
                let lines = line('$')
                if l:lines <= w:winSize
                    echo "resize ".l:lines
                    exe "resize ".l:lines
                else
                    exe "resize ".w:winSize
                endif
            endif
            exe "normal! gg"
        endif
    endif
    silent! unlet w:winSize
    silent! unlet w:split
endfunction


" Get session file to save/load/add the data.
" Return: 0 on success, 1 otherwhise.
function! s:GetSessionFile()
    let l:sessionFile = ""

    if exists("g:bookmarks_sessionFile")
        if ( g:bookmarks_sessionFile != "" )
            return 0
        endif
    endif

    let l:sessionFile = g:bookmarks_fileDflt
    call s:Info("Use session file: ".l:sessionFile)

    if confirm("[".s:plugin_name."] Use default session name: ".l:sessionFile,"&yes\n&no",1) != 1
        return 1
    endif

    if l:sessionFile == ""
        call s:Warn("Unknown file name")
        return 1
    endif

    let g:bookmarks_sessionFile = l:sessionFile
    return 0
endfunction


" Save quickfix window height and cursor position. 
function! s:SaveWindowConfig()
    let l:line = line('.')
    let l:winheight = winheight(0)
    let l:winview = winsaveview()
    let s:windowConfigList  = [ l:winview, l:winheight ]

    if len(s:windowConfigList) < 2
        call Error("Assert. Config list len error.")
        return
    endif
endfunction


" Restore quickfix window height and cursor position. 
function! s:RestoreWindowConfig()
    silent exec("autocmd BufWinLeave,BufWipeout <buffer> :call s:SaveWindowConfig()")
    if !exists("s:windowConfigList")
        return
    endif

    if len(s:windowConfigList) < 2
        call Error("Assert. Config list len error.")
        return
    endif

    silent! exec("resize ".s:windowConfigList[1])
    call winrestview(s:windowConfigList[0])
endfunction


" Get mark file pos:
" Return: mark string: "filepath:row:column"
function! s:GetMarkFilePos()
    " Get filepath, removing curren working dir
    let tmp = expand("%")
    let rm = getcwd()."/"
    let file = substitute(tmp, rm, '', '')
    if l:file == "" | return "" | endif

    " Remove ./ on the filepath
    let file = substitute(l:file, "^./", '', '') 

    " Get line info, row and columng position.
    let row = line(".")
    let col = col(".")
    call s:Verbose(2, expand('<sfile>'), "Position: ".l:row." ".l:col)

    let qftmp = "".l:file.":".l:row.":".l:col.":"
    call s:Verbose(2, expand('<sfile>'), "Complete: ".l:qftmp)

    return l:qftmp
endfunction


" Get mark line:
" Return: mark line string:
" "filepath:row:column:.........line_text"
" or
" "filepath:row:column:         line_text"
function! s:GetMarkLine(indentNum, showIndentNum)
    " Get filepath, removing curren working dir
    let tmp = expand("%")
    let rm = getcwd()."/"
    let file = substitute(tmp, rm, '', '')
    if l:file == "" | return "" | endif

    " Remove ./ on the filepath
    let file = substitute(l:file, "^./", '', '') 

    " Get line info, row and columng position.
    let row = line(".")
    let col = col(".")
    call s:Verbose(2, expand('<sfile>'), "Position: ".l:row." ".l:col)

    " Remove leading whitespaces on the text
    let text = substitute(getline("."), "^ *", '', '') 
    call s:Verbose(2, expand('<sfile>'), "Text:     '".l:text."'")

    " Align each field
    if g:bookmarks_alignment
        let bookmark = l:file.":".l:row.":".l:col.":"
        call s:Verbose(2, expand('<sfile>'), "Bookmark: ".l:bookmark)

        let bookmark =  printf("%-".g:bookmarks_alignPadding1."s", l:bookmark)

        " Replace spaces with padding character.
        if g:bookmarks_alignmentPadding
            let bookmark  = substitute(l:bookmark, " ", g:bookmarks_alignmentPaddingChar, 'g')
        endif

        if a:indentNum == 0
            let qftmp = l:bookmark.l:text
        else
            " Add iddentation to show the function call sequence.
            let qftmp = l:bookmark . repeat(' ', a:indentNum) . ' '
            "let qftmp  = l:bookmark
            "let n = 1
            "while n < a:indentNum
                "let qftmp .= " "
                "let n += 1
            "endwhile
            if a:showIndentNum == 1
                let qftmp .= .g:bookmarks_indentNumPre . a:indentNum . g:bookmarks_indentNumPost . l:text
            else
                let qftmp .= l:text
                "let qftmp .= "   ".l:text
            endif
        endif
        call s:Verbose(2, expand('<sfile>'), "Aligned:  ".l:qftmp)
    else
        " No alignment required
        let qftmp = "".l:file.":".l:row.":".l:col.":".l:text
    endif
    call s:Verbose(2, expand('<sfile>'), "Complete: ".l:qftmp)

    return l:qftmp
endfunction


" Get last mark's filepath.
function! s:GetLastSavedFilepath()
    if exists("s:lastFilepath")
        if s:lastFilepath != ""
            call s:Verbose(2, expand('<sfile>'), s:lastFilepath)
            return s:lastFilepath
        endif
    endif

    if s:GetSessionFile() | return "" | endif

    " Save window position
    let l:winview = winsaveview()

    exec("tabedit ".g:bookmarks_sessionFile)
    normal G0"ayt:
    let l:lastFilepath = @a
    silent! exec("bdelete! ".g:bookmarks_sessionFile)

    " Restore window position
    call winrestview(l:winview)

    call s:Verbose(2, expand('<sfile>'), l:lastFilepath)
    return l:lastFilepath
endfunction


" Add line to marks session file.
function! s:AddLine(string)
    if s:GetSessionFile() | return "" | endif

    " Save window number
    let l:winNr = win_getid()
    " Save window position
    let l:winview = winsaveview()

    let l:error = 0

    silent exec("tabedit ".g:bookmarks_sessionFile)

    let l:lineNum = g:bookmarks_lineNumber

    "echom "dirMode:".g:bookmarks_dirMode." bookmarks_lineNumber:".g:bookmarks_lineNumber
    if g:bookmarks_dirMode =~ "back"
        " Backwards mode: position on previous line first
        "if l:lineNum == ""
        if l:lineNum == "G"
            let l:lineNum = line("$")
        elseif type(l:lineNum) != type(0)
            let l:lineNum = line(".")
        endif
        let l:lineNum = g:bookmarks_lineNumber - 1
    endif

    " Goto line to apend config
    if l:lineNum != ""
        if l:lineNum == "G"
            " Goto last line and append config.
            normal G
        elseif type(l:lineNum) == type(0)
            exec "normal ". l:lineNum ."G"
        else
            call s:Error("Unknown line number: '". l:lineNum ."'")
            let l:error = 1
        endif
    endif
    "echom "Put at line:".line(".")." bookmarks_lineNumber:". l:lineNum

    if !l:error
        silent put = a:string
        silent w
        silent close

        " Check value is numeric, and direction fordward
        if type(l:lineNum) == type(0) && g:bookmarks_dirMode =~ "for"
            " Fordwards mode: increase saved line position.
            let g:bookmarks_lineNumber += 1
        endif
    endif

    " Restore to previous window
    call win_gotoid(l:winNr)
    " Restore window position
    call winrestview(l:winview)
endfunction


function! s:SignLoad()
    if !exists("g:bookmarks_sessionFile")
        call s:Verbose(3, expand('<sfile>'), "Bookmarks session file not loaded.")
        return
    endif

    let file_ = expand("%")
    if l:file_  == ""
        call s:Verbose(3, expand('<sfile>'), "Cancel. File without name.")
        return
    endif

    silent exec "new ".g:bookmarks_sessionFile
    let res = search("^".l:file_.":",'c')
    close
    if res == 0
        call s:Verbose(3, expand('<sfile>'), "Cancel. Mark not found for file: ".l:file_)
        return
    endif

    " Parse the config file
    redir! > readfile.out
    let l:marks_file = readfile(g:bookmarks_sessionFile)

    for l:line in l:marks_file
        call s:Verbose(3, expand('<sfile>'), "Config line: ".l:line)

        let list = split(l:line,":")
        let file  = get(l:list, 0, "")
        let rowNr = get(l:list, 1, "")

        call s:Verbose(2, expand('<sfile>'), "Current file: :".l:file_." Config line. file:".l:file." row:".l:rowNr)

        if l:file  == "" | continue | endif
        if l:rowNr == "" | continue | endif

        if l:file == l:file_
            call s:Verbose(1, expand('<sfile>'), "Add sign on file: ".l:file." row:".l:rowNr)
            silent exec "sign place 9999 line=".l:rowNr." name=marks file=".l:file
        endif
    endfor

    redir END
    call delete('readfile.out')
endfunction


function! s:SignUnload()
    if !exists("g:bookmarks_sessionFile")
        call s:Verbose(3, expand('<sfile>'), "Bookmarks session file not loaded.")
        return
    endif

    if empty(glob(g:bookmarks_sessionFile))
        return
    endif

    " Parse the config file
    redir! > readfile.out
    let l:marks_file = readfile(g:bookmarks_sessionFile)

    for l:line in l:marks_file
        call s:Verbose(2, expand('<sfile>'), "Config line: ".l:line)

        let list = split(l:line,":")
        let file  = get(l:list, 0, "")
        let rowNr = get(l:list, 1, "")

        call s:Verbose(2, expand('<sfile>'), "Config line. file:".l:file." row:".l:rowNr)

        if l:file  == "" | continue | endif
        if l:rowNr == "" | continue | endif
        if empty(glob(l:file)) | continue | endif

        call s:Verbose(1, expand('<sfile>'), "Remove sign on file: ".l:file." row:".l:rowNr)
        silent! exec "sign unplace 9999 file=".l:file
    endfor

    redir END
    call delete('readfile.out')
endfunction


" Search for duplicated line
" Return: 0 if not found, 1 elsewhere.
function! s:IsDuplicatedBookmark(file,row)
    " Save window number
    let l:winNr = win_getid()
    " Save window position
    let l:winview = winsaveview()

    silent exec("tabedit ".g:bookmarks_sessionFile)
    " Position at file init
    call cursor(0,0)
    let l:result = 0
    if search("^".a:file.":".a:row.":") == 0
        let l:result = 1
    endif
    silent close

    " Restore to previous window
    call win_gotoid(l:winNr)
    " Restore window position
    call winrestview(l:winview)
    return l:result
endfunction


" Save current line to file on a quickfix format.
" Promt user to introduce a comment and comment separator.
" Command: Bkac
function! bookmarks#AddMarkWithComment()
    if s:GetSessionFile() | return | endif

    call s:Info("add bookmark with comment.")
    echo ""
    call s:Highlight("  Separator characters allowed: '", g:bookmarks_separatorCharacters, "'.")
    call s:Highlight(" Separator lenght: ", g:bookmarks_separatorLengh, ""jk)
    echo "  (Use two separater characters to enclose the comment)"
    let l:sep = input("  Enter separator character or leave empty: ")

    redraw

    call s:Info("add bookmark with comment.")
    if l:sep != ""
        if g:bookmarks_separatorCharacters !~ l:sep[0]
            call s:Error("Error. Unknown separator characters: ".l:sep[0])
            return
        endif

        if len(l:sep) > 1 && l:sep[0] != l:sep[1]
            call s:Error("Error. The separator characters can't differ.")
            return
        endif

        let l:mssg = "  ".repeat(l:sep, g:bookmarks_separatorLengh)
        let l:mssg .= "  Comment string"
        if len(l:sep) > 1
            let l:mssg .= "  ".repeat(l:sep, g:bookmarks_separatorLengh)
        endif
        call s:Highlight("", l:mssg, "")
    endif
    let l:comment = input("  Enter comment string: ")

    call bookmarks#AddMark(l:sep,l:comment)
endfunction


" Save current line to file on a quickfix format.
" Command: Bka
function! bookmarks#AddMark(...)
    if s:GetSessionFile() | return | endif

    let l:comment = ""
    let l:separator1 = ""
    let l:separator2 = ""
    if a:0 >= 1
        " Add user comment before bookmarks
        let n = 1

        for separatorChar in split(g:bookmarks_separatorCharacters)
            call s:Verbose(3, expand('<sfile>'), "Check separator word:".a:1." is one of: ".l:separatorChar)
            if a:1 =~ l:separatorChar
                " Add separtor string before comment.
                let l:separator1 = repeat(a:1, g:bookmarks_separatorLengh)
                call s:Verbose(3, expand('<sfile>'), "Separator found word:".a:1)
                let n = 2

                if a:1 == l:separatorChar.l:separatorChar
                    " Add separtor string after comment.
                    let l:separator2 = l:separator1
                endif
                break
            endif
        endfor

        " Concatanate all comment words.
        while l:n <= a:0
            let l:comment .= " ".{"a:".l:n}
            call s:Verbose(3, expand('<sfile>'), "Parse comment word".l:n.": ".l:comment)
            let n += 1
        endwhile

        " Remove leading and trailing withespaces.
         let l:comment = substitute(l:comment, '\v(^\s+|\s+$)', "", "")
    endif

    " Get filepath, removing curren working dir
    let tmp = expand("%")
    let rm = getcwd()."/"
    let file = substitute(tmp, rm, '', '')

    if l:file == ""
        call s:Warn("File name unknown.")
        return
    endif

    " Get row position.
    let row = line(".")

    " Search for duplicated line
    "if s:IsDuplicatedBookmark(l:file,l:row) == 1
        "call s:Warn("Line duplicated")
        "if confirm("[".s:plugin_name."] Safe again?", "&yes\n&no\n", 1) != 1 | return | endif
    "endif

    let l:qfline = s:GetMarkLine(0, 0)
    if l:qfline == "" | return | endif

    " Check if new line need to be add. 
    let l:lastFilePath = s:GetLastSavedFilepath()

    if l:lastFilePath != ""
        let l:addPrevNewLine = 0

        if g:bookmarks_lineFeedOnFileChange == 1
            if fnamemodify(l:file,':t') != fnamemodify(l:lastFilePath,':t')
                call s:Verbose(2, expand('<sfile>'), "Add new line")
                let l:addPrevNewLine = 1
            endif
        endif

        if g:bookmarks_lineFeedOnFileNameChange == 1
            if fnamemodify(l:file,':t:r') != fnamemodify(l:lastFilePath,':t:r')
                call s:Verbose(2, expand('<sfile>'), "Add new line")
                let l:addPrevNewLine = 1
            endif
        endif

        if g:bookmarks_lineFeedOnDirChange == 1
            if l:file != l:lastFilePath
                call s:Verbose(2, expand('<sfile>'), "Add new line")
                let l:addPrevNewLine = 1
            endif
        endif

        if l:addPrevNewLine
            if g:bookmarks_lineFeedAskUser == 1
                if confirm("[".s:plugin_name."] Add new line before the mark?", "&yes\n&no\n", 1) == 1
                    call s:AddLine("")
                endif
            else
                call s:AddLine("")
            endif
        endif
    endif


    " Save comment into file
    if l:separator1 != ""
        call s:Verbose(2, expand('<sfile>'), "Use separator: ".l:separator1)
        call s:AddLine("")
        call s:AddLine(l:separator1)
    endif
    if l:comment != ""
        call s:Verbose(2, expand('<sfile>'), "Use comment: ".l:comment)
        call s:AddLine(l:comment)
    endif
    if l:separator2 != ""
        call s:Verbose(2, expand('<sfile>'), "Use separator: ".l:separator2)
        call s:AddLine(l:separator2)
    endif

    " Save line into file
    call s:AddLine(l:qfline)

    let s:lastFilepath = l:file

    "call s:Info("Session file: ".g:bookmarks_sessionFile.". Save mark: ".l:file.":".l:row."...")

    " Add mark to the left margin.
    "exec "sign place 9999 line=".line(".")." name=marks file=".expand("%:p")


    "echo "" | echo l:qfline

    redraw
    echon "[" . s:plugin_name . "] "
    echon "Bookmark added to file: " . g:bookmarks_sessionFile . ", "
    echon "position: ". s:GetLinePosition(). ", "
    echon "mode: ".g:bookmarks_dirMode. ", "

    if exists("g:bookmarks_indentNum")
        echon ", indent: "
        call s:Highlight("", g:bookmarks_indentNum, "")
    endif
endfunction


" Add bookmark, indent to num position and add indentation number.
" When argument provided is '?': show current indentations number.
" When argument provided is '-': decrease current indent number and add bookmark.
" When argument provided is '+': increase current indent number and add bookmark.
" When argument provided is '=': keep previous indent number and add bookmark.
" When argument provided is '=': keep previous indent number and add bookmark.
" When no argument provided: increase current indent number and add bookmark.
" Arg1: [optional] num, indentation number to be used
" Command: Bkai
"
" Indentation Config1:
" let g:bookmarks_showIndentNum = 0
" let g:bookmarks_indentNumPre  = ""
" let g:bookmarks_indentNumPost = " "
" Examples Using Indentation Config1:
" Bkai   "file:line:column...... line_text"
" Bkai 1 "file:line:column...... line_text"
" Bkai   "file:line:column......  line_text"
" Bkai 3 "file:line:column......   line_text"
" Bkai = "file:line:column......   line_text"
" Bkai - "file:line:column......  line_text"
" Bkai _ "file:line:column......  line_text"
" Bkai 3 "file:line:column......   line_text"
" Bkai 0 "file:line:column......line_text"
"
" Indentation Config2:
" let g:bookmarks_showIndentNum = 1
" let g:bookmarks_indentNumPre  = ""
" let g:bookmarks_indentNumPost = "> "
" Examples Using Indentation Config2:
" Bkai   "file:line:column......n> line_text"
" Bkai 1 "file:line:column......1> line_text"
" Bkai   "file:line:column...... 2> line_text"
" Bkai 3 "file:line:column......  3> line_text"
" Bkai = "file:line:column......  3> line_text"
" Bkai - "file:line:column...... 2> line_text"
" Bkai _ "file:line:column......  line_text"
" Bkai 3 "file:line:column......  3> line_text"
" Bkai 0 "file:line:column......line_text"
"
function! bookmarks#AddMarkIndentNumber(num)
    if !exists("g:bookmarks_indentNum")
        let g:bookmarks_indentNum = 0
    endif

    let l:num = str2nr(a:num,10)

    if g:bookmarks_showIndentNum == 1
        let l:showIndentNum = 1
    else
        let l:showIndentNum = 0
    endif

    if l:num == 0
        " Argument is not numeric
        if a:num == "?"
            " Show current indentation number
            echo "Bookmark indentation number: ".g:bookmarks_indentNum
            return
        "elseif a:num[0] == "_"
        elseif a:num[0] == "s"
            " Increase/decreace indent, do not show the indent number.
            let l:num = str2nr(a:num[1:],10)
            if l:num == 0
                let l:num = g:bookmarks_indentNum + 1
            else
                let l:num += g:bookmarks_indentNum
            endif
            let l:showIndentNum = 0
        "elseif a:num == "" || a:num == "_" || a:num == "+"
        elseif a:num == "" || a:num == "s" || a:num == "i"
            " Increase indent by one
            let l:num = g:bookmarks_indentNum + 1
        elseif a:num[0] == "+"
            " Increase indent
            let l:num = a:num[1:]
            let l:num = g:bookmarks_indentNum + l:num
        "elseif a:num == "-"
        elseif a:num == "d"
            " Decrease indent by one
            let l:num = g:bookmarks_indentNum - 1
        elseif a:num[0] == "-"
            " Decrease indent
            let l:num = a:num[1:]
            let l:num = g:bookmarks_indentNum - l:num
        "elseif a:num[0] == "="
        elseif a:num[0] == "q"
            " Keep current indent number
            let l:num = g:bookmarks_indentNum
        "elseif a:num[0] == "@"
        elseif a:num[0] == "r"
            let l:num = 0
        else
            call s:Error("Unknown argument1: '".a:num."'")
            return
        endif
    endif

    if s:GetSessionFile() | return | endif

    " Check if numberic variable
    if type(l:num) != type(0)
        call s:Error("Assert indent number: ".l:num." (".l:num.")")
    endif


    " Add a new bookmark
    let l:qfline = s:GetMarkLine(l:num, l:showIndentNum)
    call s:AddLine(l:qfline)
    let g:bookmarks_indentNum = l:num

    "echo "" | echo l:qfline

    echon "[" . s:plugin_name . "] "
    echon "Bookmark add indented to file: " . g:bookmarks_sessionFile . ", "
    call s:Highlight("position: ", s:GetLinePosition(), ", ")
    call s:Highlight("direction: ", g:bookmarks_dirMode, ", ")

    if exists("g:bookmarks_indentNum")
        echon ", indent: "
        call s:Highlight("", g:bookmarks_indentNum, "")
    endif
endfunction


function! s:isEditBookmark()
    if s:isBookmarsFile() == 1
        return 1
    endif
    if getwinvar(winnr(), '&syntax') != 'qf'
        return 1
    endif
    return 0
endfunction


" Check if current buffer is the bookmarks session file.
" Return 1 if it is the bookmarks file, else 0.
function! s:isBookmarsFile()
    if !exists("g:bookmarks_sessionFile")
        call hi#log#Warn("Bookmarks session not found (1).")
        return 0
    endif
    if g:bookmarks_sessionFile == ""
        call hi#log#Warn("Bookmarks session not found (2).")
        return 0
    endif
    if empty(glob(g:bookmarks_sessionFile)) || !filereadable(g:bookmarks_sessionFile)
        call hi#log#Warn("Bookmarks session not found (3).")
        return 0
    endif
    "if expand("%") != g:bookmarks_sessionFile
        "call hi#log#Error("Bookmarks session file not matched: ".g:bookmarks_sessionFile)
        "return 0
    "endif
    return 1
endfunction


" Check if current window is a quickfix or linked list window bookmarks
" related.
" Return 0 if not on qf/ll window
function! s:isBookmarksQfWindow()
    if getwinvar(winnr(), '&syntax') != 'qf'
        return 0
    endif
    if !exists("g:bookmarks_sessionFile")
        return 0
    endif
    if g:bookmarks_sessionFile == ""
        return 0
    endif
    if empty(glob(g:bookmarks_sessionFile)) || !filereadable(g:bookmarks_sessionFile)
        return 0
    endif

    let l:line = line(".")
    let l:lineText = getline(".")
    let l:winId = win_getid()

    silent exec "tabedit ".g:bookmarks_sessionFile

    if expand("%") != g:bookmarks_sessionFile
        return 0
    endif

    silent exec "normal ".l:line ."G"

    let l:fileLineText = getline(".")
    if l:lineText[0:5] != l:fileLineText[0:5]
        silent close!
        call win_gotoid(a:winId)
        return 0
    endif

    silent close!
    call win_gotoid(a:winId)
    return 1
endfunction




" If current window is a quickfix or linked list window
" Edit the related bookmarks session file.
" Return: window ID of the bookmarks quickfix window
"  return 0 if not on qf/ll window
"  return -1 if bookmarks file can't be opened.
function! s:qfWindowInit()
    if getwinvar(winnr(), '&syntax') != 'qf'
        return 0
    endif
    if !exists("g:bookmarks_sessionFile")
        call hi#log#Error("Bookmarks session not found (1).")
        return -1
    endif
    if g:bookmarks_sessionFile == ""
        call hi#log#Error("Bookmarks session not found (2).")
        return -1
    endif
    if empty(glob(g:bookmarks_sessionFile)) || !filereadable(g:bookmarks_sessionFile)
        call hi#log#Error("Bookmarks session not found (3).")
        return -1
    endif

    let l:line = line(".")
    let l:lineText = getline(".")
    let l:winId = win_getid()

    silent exec "tabedit ".g:bookmarks_sessionFile

    if expand("%") != g:bookmarks_sessionFile
        call hi#log#Error("Bookmarks open failure (1).")
        return -1
    endif

    silent exec "normal ".l:line ."G"

    let l:fileLineText = getline(".")
    if l:lineText[0:5] != l:fileLineText[0:5]
        call hi#log#Error("Bookmarks line doesn't match (1).")
        silent close!
        call win_gotoid(a:winId)
        return -1
    endif
    return l:winId
endfunction


" If current window is a quickfix or linked list window
" Finish editting the bookmarks session file.
" Arg1: window ID of the bookmarks quickfix window
" Attention: s:qfWindowInit() must be called first.
function! s:qfWindowEnd(winId)
    if a:winId == 0
        return 0
    endif
    if getwinvar(winnr(), '&syntax') == 'qf'
        call hi#log#Error("ASSERT Bookmarks session not found.")
        return 1
    endif
    "let l:line = line(".")
    if expand("%") != g:bookmarks_sessionFile
        call hi#log#Error("ASSERT Bookmarks close failure.")
        return 1
    endif

    silent w!
    silent close!

    if win_gotoid(a:winId) == 0
        call hi#log#Error("Qf window not found id:".a:winId)
        return 1
    endif
    "silent exec "normal ".l:line ."G"
    "call bookmarks#Load(g:bookmarks_sessionFile)
    call bookmarks#Load()
    return 0
endfunction


" Re Indent bookmark lines
" Command: Bki
function! bookmarks#IndentBookmarksFile(num) range
    let l:num = str2nr(a:num,10)

    if g:bookmarks_showIndentNum == 1
        let l:showIndentNum = 1
    else
        let l:showIndentNum = 0
    endif

    if !exists("g:bookmarks_indentNum")
        let g:bookmarks_indentNum = 0
    endif

    if l:num == 0
        " Argument is not numeric
        if a:num == "?"
            " Show current indentation number
            echo "Bookmark indentation number: ".g:bookmarks_indentNum
            return
        elseif a:num[0] == "_"
            " Increase/decreace indent, do not show the indent number.
            let l:num = str2nr(a:num[1:],10)
            if l:num == 0
                let l:num = g:bookmarks_indentNum + 1
            else
                let l:num += g:bookmarks_indentNum
            endif
            let l:showIndentNum = 0
        elseif a:num == "" || a:num == "_" || a:num == "+"
            " Increase indent by one
            let l:num = g:bookmarks_indentNum + 1
        elseif a:num[0] == "+"
            " Increase indent
            let l:num = a:num[1:]
            let l:num = g:bookmarks_indentNum + l:num
        elseif a:num == "-"
            " Decrease indent by one
            let l:num = g:bookmarks_indentNum - 1
        elseif a:num[0] == "-"
            " Decrease indent
            let l:num = a:num[1:]
            let l:num = g:bookmarks_indentNum - l:num
        elseif a:num[0] == "="
            " Keep current indent number
            let l:num = g:bookmarks_indentNum
        else
            call s:Error("Unknown argument1: '".a:num."'")
            return
        endif
    endif

    " Check if numeric variable
    if type(l:num) != type(0)
        call s:Error("Assert indent number: ".l:num." (".l:num.")")
    endif


    let l:lines = a:lastline - a:firstline
    let l:qfWinId = s:qfWindowInit()
    if l:qfWinId < 0 | return | endif

    "if s:isBookmarsFile() == 0 | return | endif
    if s:isBookmarsFile() == 0
        call confirm("Continue?")
    endif

    let l:n = 0
    while l:n <= l:lines
        call s:RemoveLineIndent()

        "let l:paddingNum  = l:num - 1
        "let l:indent = repeat(' ',l:paddingNum).l:num."> "
        "let l:indent = repeat(' ', l:paddingNum)

        if l:showIndentNum == 1
            let l:paddingNum  = l:num - 1
            let l:indent = repeat(' ', l:paddingNum)
            let l:indent .= g:bookmarks_indentNumPre . l:num . g:bookmarks_indentNumPost
        else
            let l:paddingNum  = l:num
            let l:indent = repeat(' ', l:paddingNum)
        endif

        "file:line:column:......line_text"
        "file:line:column:......$line_text"
        if g:bookmarks_alignment == 1
            silent exec "normal 0f:f:f:eli".l:indent.""
        else
            silent exec "normal 0f:f:f:li".l:indent.""
        endif
        let l:num += 1
        let l:n += 1
        normal j
    endwhile

    call s:qfWindowEnd(l:qfWinId)

    let g:bookmarks_indentNum = l:num - 1
endfunction


" Reverse current selected lines
" Command: Bkr
function! bookmarks#ReverseLines() range
    let l:lines = a:lastline - a:firstline

    if l:lines <= 0
        call s:Error("Error. No lines selected")
        return
    endif

    let l:qfWinId = s:qfWindowInit()

    exec "normal ".a:firstline."GV".l:lines.'j"ad'

    let l:lines = @a
    let l:linesList = split(l:lines, "\n")

    call reverse(l:linesList)

    " Paste the lines again
    let n=-1
    for line in l:linesList
        silent put = l:line
        let n+=1
    endfor

    if l:qfWinId >= 0
        call s:qfWindowEnd(l:qfWinId)
    endif

    " Keep text selected
    exec "normal V".l:n."k0"
endfunction


" Re Indent bookmark lines
function! bookmarks#IndentReverseBookmarksFile(num) range
    let l:num = str2nr(a:num,10)

    if g:bookmarks_showIndentNum == 1
        let l:showIndentNum = 1
    else
        let l:showIndentNum = 0
    endif

    if !exists("g:bookmarks_indentNum")
        let g:bookmarks_indentNum = 0
    endif


    if l:num == 0
        " Argument is not numeric
        if a:num == "?"
            " Show current indentation number
            echo "Bookmark indentation number: ".g:bookmarks_indentNum
            return
        elseif a:num[0] == "_"
            " Increase/decreace indent, do not show the indent number.
            let l:num = str2nr(a:num[1:],10)
            if l:num == 0
                let l:num = g:bookmarks_indentNum + 1
            else
                let l:num += g:bookmarks_indentNum
            endif
            let l:showIndentNum = 0
        elseif a:num == "" || a:num == "_" || a:num == "+"
            " Increase indent by one
            let l:num = g:bookmarks_indentNum + 1
        elseif a:num[0] == "+"
            " Increase indent
            let l:incNum = a:num[1:]
            if l:incNum == ""
                let l:incNum = 1
            endif
            let l:num = g:bookmarks_indentNum + l:incNum
        elseif a:num == "-"
            " Decrease indent by one
            let l:num = g:bookmarks_indentNum - 1
        elseif a:num[0] == "-"
            " Decrease indent
            let l:num = a:num[1:]
            let l:num = g:bookmarks_indentNum - l:num
        elseif a:num[0] == "="
            " Keep current indent number
            let l:num = g:bookmarks_indentNum
        else
            call s:Error("Unknown argument1: '".a:num."'")
            return
        endif
    endif

    " Check if numberic variable
    if type(l:num) != type(0)
        call s:Error("Assert indent number: ".l:num." (".l:num.")")
    endif

    let l:lines = a:lastline - a:firstline
    silent exec "normal ".l:lines."j"

    let l:qfWinId = s:qfWindowInit()
    if l:qfWinId < 0 | return | endif

    "if s:isBookmarsFile() == 0 | return | endif
    if s:isBookmarsFile() == 0
        call confirm("Continue?")
    endif

    let l:n = 0
    while l:n <= l:lines
        call s:RemoveLineIndent()

        if l:showIndentNum == 1
            let l:paddingNum  = l:num - 1
            let l:indent = repeat(' ', l:paddingNum)
            let l:indent .= g:bookmarks_indentNumPre . l:num . g:bookmarks_indentNumPost
        else
            let l:paddingNum  = l:num
            let l:indent = repeat(' ', l:paddingNum)
        endif

        if g:bookmarks_alignment == 1
            "silent exec "normal 0" . g:bookmarks_alignPadding1 . "li" . l:indent . ""
            silent exec "normal 0f:f:f:wi" . l:indent .""
        else
            silent exec "normal 0f:f:f:li" . l:indent . ""
        endif
        let l:num += 1
        let l:n += 1
        normal k
    endwhile
    call s:qfWindowEnd(l:qfWinId)

    let g:bookmarks_indentNum = l:num - 1
endfunction


" Remove bookmarks indentation.
function! s:RemoveLineIndent()

    if g:bookmarks_showIndentNum == 1
        " Line Format: file:line:col:...1> text
        " Line Format: file:line:col:...(1) text
        silent! exec "s/\.".g:bookmarks_indentNumPre."1".g:bookmarks_indentNumPost."/./"

        " Line Format: file:line:col:...   33> text
        " Line Format: file:line:col:...   (3) text
        silent! exec "s/\.\\s\\+".g:bookmarks_indentNumPre."[0-9]\\+".g:bookmarks_indentNumPost."/./"

        " Line Format: file:line:col: n> text
        " Line Format: file:line:col: (n) text
        silent! exec "s/:\\s\\+.".g:bookmarks_indentNumPre."[0-9]\\+".g:bookmarks_indentNumPost."/:/"
    else
        " Line Format: file:line:col:...   > text
        " Line Format: file:line:col:...text
        silent! exec "s/\.\\s\\+".g:bookmarks_indentNumPre.g:bookmarks_indentNumPost."/./"
        "silent! exec "s/\.\\s\\+".g:bookmarks_indentNumPre.g:bookmarks_indentNumPost."/./"

        " Line Format: file:line:col: > text
        silent! exec "s/:\\s\\+.".g:bookmarks_indentNumPre.g:bookmarks_indentNumPost."/:/"
        "silent! exec "s/:\\s\\+.".g:bookmarks_indentNumPre.g:bookmarks_indentNumPost."/:/"
    endif

    " Line Format: file:line:col:...  text
    " Line Format: file:line:col:  text
    " Remove dots after :
    silent! exec "s/:\.\+/:/"
    " Remove spaces after :
    silent! exec "s/:\s\+/:/"
    "silent! exec "s/\\.\\s\\+/./"

    " Line Format: file:line:col:  text
    "silent! exec "s/:\\s\\+/:/"
endfunction


" Remove bookmarks indentation.
" Command: Bkir
function! bookmarks#RemoveIndentBookmarksFile() range
    let l:qfWinId = s:qfWindowInit()
    if l:qfWinId < 0 | return | endif
    "if s:isBookmarsFile() == 0 | return | endif
    if s:isBookmarsFile() == 0
        call confirm("Continue?")
    endif

    " Remove indentation on lines with format:

    " Line Format: file:line:col:...1> text
    silent! exec a:firstline.",".a:lastline."s/\.1.*> /./"

    " Line Format: file:line:col:... n> text
    silent! exec a:firstline.",".a:lastline."s/\.\\s\\+.*> /./"

    " Line Format: file:line:col: n> text
    silent! exec a:firstline.",".a:lastline."s/:\\s\\+.*> /:/"

    " Line Format: file:line:col:...  text
    silent! exec a:firstline.",".a:lastline."s/\\.\\s\\+/./"

    " Line Format: file:line:col:  text
    silent! exec a:firstline.",".a:lastline."s/:\\s\\+/:/"

    call s:qfWindowEnd(l:qfWinId)
endfunction


" Get bookmarks indentation number on current line.
function! s:GetIndentationNumber()
    let l:qfWinId = s:qfWindowInit()
    if l:qfWinId < 0 | return "" | endif
    "if s:isBookmarsFile() == 0 | return "" | endif
    if s:isBookmarsFile() == 0
        call confirm("Continue?")
    endif

    normal 0f vwh"zy
    let l:indent = @z

    call s:qfWindowEnd(l:qfWinId)
    return len(l:indent)
endfunction


" Show bookmarks indentation number on current line.
" Command: Bkin
"function! bookmarks#GetIndentationNumber(indent)
function! bookmarks#GetIndentationNumber()
    "if a:indent == "?"
    "elseif a:indent == ""
        let l:indent = s:GetIndentationNumber()
        if l:indent == ""
            return
        endif
        call s:Highlight("Indenttion number: ", l:indent, "")
    "else
        "let l:num = str2nr(a:num,10)
        "if l:num == 0
            "call s:Error("Error. Indentation number must be a number.")
            "return
        "endif

        "echon "Indenttion changed to number: "
        "echohl WarningMsg
        "echon g:
        "echohl None
    "endif
endfunction


" Set current bookmark line indentation level as the last indentation level.
" Command: BkiN
function! bookmarks#SetCurrentAsIndentationNumber()
    let l:indent = s:GetIndentationNumber()
    if l:indent == ""
        return
    endif
    let g:bookmarks_indentNum = l:indent
    echo "Set indent number: ". g:bookmarks_indentNum
endfunction


" Change direction
" Arg1: [mode]. f:fordward or b:backward.
"  Toogle direction when no argument passed (ex: Bkm).
"  Show current direction when argument is ? (ex: Bkm ?).
" Command: Bkm
function! bookmarks#SetDirectionMode(mode)
    if a:mode == "?"
        call s:Highlight("[" . s:plugin_name . "] Current bookmarks direction mode: ", g:bookmarks_dirMode, "")
        return
    elseif a:mode == ""
        if g:bookmarks_dirMode =~ "f"
            let g:bookmarks_dirMode = "backward"
        else
            let g:bookmarks_dirMode = "fordward"
        endif
    elseif a:mode == "f"
        let g:bookmarks_dirMode = "fordward"
    elseif a:mode == "b"
        let g:bookmarks_dirMode = "backward"
    else
        call s:Error("Unkown option: '".a:mode."' use b or f")
        return
    endif
    call s:Highlight("[" . s:plugin_name . "] Direction mode changed to: ", g:bookmarks_dirMode, "")
endfunction


function! s:GetLinePosition()
    if g:bookmarks_lineNumber == ""
        let l:lineNumber = "current line"
    elseif g:bookmarks_lineNumber == "G"
        let l:lineNumber = "last line"
    else
        if g:bookmarks_lineNumber == line('$')
            let l:lineNumber = "last line"
        else
            let l:lineNumber = g:bookmarks_lineNumber
        endif
    endif
    return l:lineNumber
endfunction


" Change line number on bookmarks file where inserting the bookmark
" Arg1: line, line numer, G for last line.
"   if empty, show current line number configured.
" Command: Bkpl
function! bookmarks#PositionOnLine(line)
    let l:qfWinId = s:qfWindowInit()
    if l:qfWinId < 0
        "call s:Error("Not on a bookmarks file or bookmarks quickfix window")
        return
    endif

    if a:line == "?"
        if exists("g:bookmarks_indentNum")
            call s:Highlight2("[" . s:plugin_name . "] Current bookmarks position: ", s:GetLinePosition(), ", indent: ", g:bookmarks_indentNum, "")
        else
            call s:HighlightN("[" . s:plugin_name . "] Current bookmarks position: ", s:GetLinePosition(), ", ")
        endif

        call s:qfWindowEnd(l:qfWinId)
        return
    endif

    if s:isBookmarsFile() == 0
        "call s:Error("Not on a bookmarks file or bookmarks quickfix window")
        "return
        call confirm("Continue?")
    endif

    if a:line != ""
        silent exec("normal ".a:line."G")
    endif

    let g:bookmarks_lineNumber = line('.')

    call s:qfWindowEnd(l:qfWinId)

    silent call bookmarks#SetCurrentAsIndentationNumber()

    if exists("g:bookmarks_indentNum")
        call s:Highlight2("[" . s:plugin_name . "] Changed bookmarks position: ", s:GetLinePosition(), ", indent: ", g:bookmarks_indentNum, "")
    else
        call s:Highlight("[" . s:plugin_name . "] Changed bookmarks position: ", s:GetLinePosition(), ", ")
    endif
endfunction


" Delete mark placed on current position.
" Command: Bkd
function! bookmarks#Delete()
    if !exists("g:bookmarks_sessionFile")
        call s:Verbose(3, expand('<sfile>'), "Bookmarks session file not loaded.")
        return
    endif
    "let s:verbose = 4

    let file = expand("%")
    let rowNr = line(".")

    if confirm("[".s:plugin_name."] Delete current mark?","&yes\n&no",1) != 1
        return
    endif

    "Remove all signs on current file
    silent! exec "sign unplace * file=".expand("%:p")

    call s:Verbose(2, expand('<sfile>'), "Search ".g:bookmarks_sessionFile." and remove: ".l:file.":".l:rowNr.":[0-9].*:")

    " Remove sign from file.
    silent exec "new ".g:bookmarks_sessionFile
    silent exec "g/".l:file.":".l:rowNr.":[0-9].*:/d"
    w!
    close

    " Load signs again on current file
    if g:bookmarks_loadSignsOnFileDelete
        call s:SignLoad()
    endif
    "let s:verbose = 0
    return
endfunction


" Remove last marks
" Command: Bkdl
function! bookmarks#RmLastMark()
    if s:GetSessionFile() | return "" | endif

    " Save window position
    let l:winview = winsaveview()

    silent exec("new ".g:bookmarks_sessionFile)
    normal G0"ayy

    let string = @a
    echo "Last line: ".l:string

    if confirm("[".s:plugin_name."] Remove line?","&yes\n&no",1) == 1
        silent exec("normal Gdd")
        w!
        echo "Last line removed"
    endif

    silent! exec("bdelete! ".g:bookmarks_sessionFile)

    " Restore window position
    call winrestview(l:winview)
endfunction


" Copy line information in qf format into default register
" Command: Bky
function! bookmarks#YankLine()
    " Yank into default register
    let l:line = s:GetMarkLine(0,0)
    let @" = l:line

    " Add yanked line into yank buffer.
    if !exists("s:bookmarks_yankList")
        let s:bookmarks_yankList = []
    endif

    if g:bookmarks_yankBuffer_mode == "insert"
        " insert new value at start of list.
        call insert(s:bookmarks_yankList, l:line)
    else
        " add new value at end of list.
        call add(s:bookmarks_yankList, l:line)
    endif

    let l:len = len(s:bookmarks_yankList)

    "call s:Info("Copied to system clipboard and bookmark's yank buffer (yank buffer: lines:".l:len.", mode:".g:bookmarks_yankBuffer_mode.")")
    echon "[" . s:plugin_name . "] Yanked. Yank buffer: lines: "
    echohl WarningMsg | echon l:len | echohl None
    echon ", mode: "
    echohl WarningMsg | echon g:bookmarks_yankBuffer_mode | echohl None
endfunction


" Select yank buffer mode to insert new value: insert (on top), append (on bottom) (ex: Bkym i, ex2: Bkym insert).
" Toogle yank buffer mode when no argument passed (ex: Bkym).
" Show yank buffer mode when argument is ? (ex: Bkym ?).
" Arg1: mode, insert or append (abbridged to: i or a)
" Command: Bkym
function! bookmarks#YankBufferMode(mode)
    if a:mode == ""
        if g:bookmarks_yankBuffer_mode == "insert"
            let g:bookmarks_yankBuffer_mode = "append"
        else
            let g:bookmarks_yankBuffer_mode = "insert"
        endif

    elseif a:mode == "?"
        if g:bookmarks_yankBuffer_mode == "insert"
            let l:text = " (insert at buffer start)"
        else
            let l:text = " (add on buffer end)"
        endif
        "echo "Yank buffer mode: ".g:bookmarks_yankBuffer_mode.l:text
        echon "[" . s:plugin_name . "] Yank buffer mode: "
        echohl WarningMsg | echon g:bookmarks_yankBuffer_mode | echohl None
        return

    elseif a:mode == "insert" || a:mode == "append" || a:mode == "i" || a:mode == "a"
        if a:mode == "i"
            let l:mode = "insert"
        elseif a:mode == "a"
            let l:mode = "append"
        else
            let l:mode = a:mode
        endif
        let g:bookmarks_yankBuffer_mode = l:mode

    else
        call s:Warn("Error. Unknown option ".a:mode)
    endif

    "echo "Yank buffer mode changed to: ".g:bookmarks_yankBuffer_mode
    echon "[" . s:plugin_name . "] Yank buffer mode changed to: "
    echohl WarningMsg | echon g:bookmarks_yankBuffer_mode | echohl None
endfunction


" Paste all lines on yank buffer.
" Command: Bkp
function! bookmarks#PasteLastYankedLines(flags)
    if !exists("s:bookmarks_yankList")
        call s:Warn("Error. Yank buffer empty.")
        return
    endif

    let l:qfWinId = s:qfWindowInit()
    if l:qfWinId < 0
        call s:Error("Not on a bookmarks file or bookmarks quickfix window")
        return
    endif

    if a:flags =~ "pasteBeforeLine"
        silent exec "normal k"
    endif

    let n=-1
    for line in s:bookmarks_yankList
        silent put = l:line
        let n+=1
    endfor

    if a:flags =~ "textSelection"
        exec "normal V".l:n."k0"
    endif

    if a:flags =~ "emptyBuffer"
        unlet s:bookmarks_yankList
    endif

    call s:qfWindowEnd(l:qfWinId)
endfunction


" Empty the yank buffer.
" Command: Bky0, Bkp0
function! bookmarks#EmptyYankedLines()
    if !exists("s:bookmarks_yankList")
        call s:Warn("Error. Yank buffer empty.")
        return
    endif
    let s:bookmarks_yankListBackup = s:bookmarks_yankList
    unlet s:bookmarks_yankList
    echo "Bookmarks buffer empty done."
endfunction


" Recover the previous yank buffer.
" Command: BkyR
function! bookmarks#RecoverPreviousYankedLines()
    if !exists("s:bookmarks_yankListBackup")
        call s:Warn("Error. Yank backup buffer not found.")
        return
    endif

    if exists("s:bookmarks_yankList")
        if confirm("[".s:plugin_name."] ATTENTION! Current bookmarks will be overwriten with previous saved bookmarks. Proceed?", "&yes\n&no\n", 2) == 2
            return
        endif
        let l:bookmarks_yankList = s:bookmarks_yankList
    endif

    let s:bookmarks_yankList = s:bookmarks_yankListBackup
    echo "Bookmarks buffer recover done."

    if exists("l:bookmarks_yankList")
        let s:bookmarks_yankListBackup = l:bookmarks_yankList
    endif
endfunction


" Show the yank buffer.
" Command: Bkysh
function! bookmarks#ShowYankBuffer(name)
    if a:name == "main"
        if !exists("s:bookmarks_yankList")
            call s:Warn("Error. '".a:name."' yank buffer not found.")
            return
        endif
        let l:bufferList = s:bookmarks_yankList
    elseif a:name == "backup"
        if !exists("s:bookmarks_yankListBackup")
            call s:Warn("Error. '".a:name."' yank buffer not found.")
            return
        endif
        let l:bufferList = s:bookmarks_yankListBackup
    else
        call s:Err("Error. Unknown parameter ".a:name)
        return
    endif

    if exists("s:bookmarks_yankList")
        let l:yankListLen = len(s:bookmarks_yankList)
    else
        let l:yankListLen = 0
    endif

    call s:Info(" Yank buffer config:")
    call s:Highlight(" - Lines on buffer:     ", l:yankListLen, "")
    call s:Highlight(" - Insert mode:         ", g:bookmarks_yankBuffer_mode, "")
    echo " "

    call s:Info(" Yank buffer: '".a:name."'")
    let l:n = 1
    for line in l:bufferList
        echo " ".l:n.") ".l:line
        let l:n += 1
    endfor
    echo " "
endfunction


" Reverse the yank buffer content.
" Command: Bkyr
function! bookmarks#ReversYankBuffer()
    if !exists("s:bookmarks_yankList")
        call s:Warn("Error. '".a:name."' yank buffer not found.")
        return
    endif
    call reverse(s:bookmarks_yankList)
    call s:Info(" Yank buffer reverse done")
endfunction


" Show the yank buffer.
" Command: Bkyshp
"function! bookmarks#ShowYankedLines()
    "if !exists("s:bookmarks_yankList")
        "call s:Warn("Error. Yank backup buffer not found.")
        "return
    "endif

    "call s:Info(" yank buffer:")
    "let l:n = 1
    "for line in s:bookmarks_yankList
        "echo l:n." ".l:line
        "let l:n += 1
    "endfor
"endfunction


" Copy file and position information in qf format into default register
" Command: BkY
function! bookmarks#YankFilePos()
    " Yank into default register
    let @" = s:GetMarkFilePos()
    call s:Info("Copied to system clipboard: ".@")
endfunction


" Unload current session file.
" Command: BkU
function! bookmarks#Unload()
    if !exists("g:bookmarks_sessionFile")
        call s:Warn("Error. Input file not defined")
        return
    endif

    if confirm("[".s:plugin_name."] Unload session file: ".g:bookmarks_sessionFile,"&yes\n&no",1) != 1
        return
    endif
    " Remove all signs on left margin.
    call s:SignUnload()

    unlet g:bookmarks_sessionFile
    "call s:Info("Session unloaded")
endfunction


" Load session file, show on quickfix window. 
" Command: Bkl
function! bookmarks#Load(...)
    let sessionFile = ""

    if a:0 >= 1
        " Unload previous marks session.
        if exists("g:bookmarks_sessionFile")
            if g:bookmarks_sessionFile != "" && g:bookmarks_sessionFile != a:1
                call bookmarks#Unload()
            endif
        endif
        " Assign/replace marks session file.
        "let g:bookmarks_sessionFile = a:1
        let g:bookmarks_sessionFile = substitute(a:1,'\s\+$','','g')
        echo "Use marks file: ".g:bookmarks_sessionFile
    endif

    if s:GetSessionFile() | return | endif

    if empty(glob(g:bookmarks_sessionFile))
        call s:Warn("Bookmarks file empty: ".g:bookmarks_sessionFile)
        return
    endif

    if g:bookmarks_loadSignsOnBookmarksLoad
        call s:SignLoad()
    endif

    " Get window height
    let wlen = winheight(0) " window lenght

    " Prevent displaying full path.
    exec("cd ".getcwd())

    " Load file on qf/ll window
    cal s:Verbose(1, expand('<sfile>'), "Load quickfix from ./".g:bookmarks_sessionFile." file")
    call LocListSetOpen()
    "lgetexpr system("cat ".g:bookmarks_sessionFile) | lwindow | set cursorline
    exec "lgetfile " . g:bookmarks_sessionFile
    lwindow
    setlocal cursorline
    wincmd j

    " Resize qf/ll window
    let blen = line('$') " buffer lenght
    let maxlen = l:wlen/2
    if l:blen < l:maxlen
        exe "resize ".l:blen
        exe "normal! gg"
    endif

    " Fold context
    hi Folded term=NONE cterm=NONE gui=NONE
    let foldExpr="[1234567890] col [123456789]"
    setlocal foldexpr=(getline(v:lnum)=~l:foldExpr)?0:(getline(v:lnum-1)=~l:foldExpr)\|\|(getline(v:lnum+1)=~l:foldExpr)?1:2
    setlocal foldmethod=expr 
    setlocal foldtext="..."
    setlocal fillchars="vert:|,fold: "
    setlocal foldlevel=20 
    setlocal foldcolumn=4

    if g:bookmarks_lineNumber == ""
    elseif g:bookmarks_lineNumber == "G"
        exe "normal! G"
    else
        exec "normal ".g:bookmarks_lineNumber ."G"
    endif
    call s:RestoreWindowConfig()
    let w:marks_qfwindow = 1

    "let l:qfBufferName = g:bookmarks_sessionFile
    "silent! exec "0file | file " . g:qfBufferName
    "silent exec "silent! autocmd! WinEnter ".l:qfBufferName." call s:QfMapKeys()"
    "silent exec "silent! autocmd! WinLeave ".l:qfBufferName." call s:QfUnmapKeys()"
    "call s:QfMapKeys()
    "silent! autocmd! WinLeave "[Location List]" call s:QfUnmapKeys()
endfunction


" Load session file, show on quickfix window. 
" Load all signs on current open file.
" Command: Bkl
function! bookmarks#LoadSigns(...)
    let sessionFile = ""

    if a:0 >= 1
        " Unload previous marks session.
        if exists("g:bookmarks_sessionFile")
            if g:bookmarks_sessionFile != "" && g:bookmarks_sessionFile != a:1
                call bookmarks#Unload()
            endif
        endif
        " Assign/replace marks session file.
        let g:bookmarks_sessionFile = a:1
        echo "Use marks file: ".g:bookmarks_sessionFile
    endif

    if s:GetSessionFile() | return | endif

    if empty(glob(g:bookmarks_sessionFile))
        call s:Warn("Bookmarks file empty: ".g:bookmarks_sessionFile)
        return
    endif

    call s:SignLoad()

    " Get window height
    let wlen = winheight(0) " window lenght

    " Prevent displaying full path.
    exec("cd ".getcwd())

    " Load file on qf/ll window
    cal s:Verbose(1, expand('<sfile>'), "Load content from: ".g:bookmarks_sessionFile." file")
    call LocListSetOpen()
    lgetexpr system("cat ".g:bookmarks_sessionFile) | lwindow | set cursorline
    wincmd j

    " Resize qf/ll window
    let blen = line('$') " buffer lenght
    let maxlen = l:wlen/2
    if l:blen < l:maxlen
        exe "resize ".l:blen
        exe "normal! gg"
    endif

    " Fold context
    hi Folded term=NONE cterm=NONE gui=NONE
    let foldExpr="[1234567890] col [123456789]"
    setlocal foldexpr=(getline(v:lnum)=~l:foldExpr)?0:(getline(v:lnum-1)=~l:foldExpr)\|\|(getline(v:lnum+1)=~l:foldExpr)?1:2
    setlocal foldmethod=expr 
    setlocal foldtext="..."
    setlocal fillchars="vert:|,fold: "
    setlocal foldlevel=20 
    setlocal foldcolumn=4

    exe "normal! G"
    call s:RestoreWindowConfig()
    let w:marks_qfwindow = 1

    "let l:qfBufferName = g:bookmarks_sessionFile
    "silent! exec "0file | file " . g:qfBufferName
    "silent exec "silent! autocmd! WinEnter ".l:qfBufferName." call s:QfMapKeys()"
    "silent exec "silent! autocmd! WinLeave ".l:qfBufferName." call s:QfUnmapKeys()"
endfunction


" Show the session filename loaded.
" Command: Bksh
function! bookmarks#Show(mode)
    if s:GetSessionFile() | return | endif

    if empty(glob(g:bookmarks_sessionFile))
        call s:Error("Config file empty or not found ".g:bookmarks_sessionFile)
        unlet g:bookmarks_sessionFile
        return 1
    endif

    if g:bookmarks_dirMode =~ "for"
        let l:text = " (insert after last bookmark)"
    else
        let l:text = " (insert before last bookmark)"
    endif

    if g:bookmarks_yankBuffer_mode == "insert"
        let l:text1 = " (insert at yank buffer start)"
    else
        let l:text1 = " (add on yank buffer end)"
    endif

    "call s:Info("Bookmarks file loaded: ".g:bookmarks_sessionFile)
    if a:mode == "" || a:mode =~ "file_config"
        call s:Info("Configuration:")
        echo "  Bookmark's file config:"
        call s:Highlight("  - Bookmarks' file:     ", g:bookmarks_sessionFile, "")
        call s:Highlight("  - Insert direction:    ", g:bookmarks_dirMode, l:text)
        call s:Highlight("  - Insert position:     ", s:GetLinePosition(), "")

        if exists("g:bookmarks_indentNum")
            call s:Highlight("  - Content indentation: ", g:bookmarks_indentNum, "")
        endif

    elseif a:mode =~ "file_pos_indent"
        call s:Info("Configuration:")
        call s:Highlight("  - Insert position:     ", s:GetLinePosition(), "")

        if exists("g:bookmarks_indentNum")
            call s:Highlight("  - Content indentation: ", g:bookmarks_indentNum, "")
        endif
    endif

    if a:mode == "" || a:mode =~ "buffer_config"
        echo "  Bookmark's yank buffer config:"
        if exists("s:bookmarks_yankList")
            call s:Highlight("  - Lines on buffer:     ", len(s:bookmarks_yankList), "")
        else
            call s:Highlight("  - Lines on buffer:     ", "0", "")
        endif
        call s:Highlight("  - Insert mode:         ", g:bookmarks_yankBuffer_mode, l:text1)
    endif
endfunction


" Open session file on new tab.
" Command: Bke
function! bookmarks#Edit()
    if s:GetSessionFile() | return | endif

    if empty(glob(g:bookmarks_sessionFile))
        call s:Warn("Bookmarks session file empty or not found: ".g:bookmarks_sessionFile)
    endif

    cal s:Verbose(1, expand('<sfile>'), "Bookmarks show: ".g:bookmarks_sessionFile)
    exec "tabedit ".g:bookmarks_sessionFile
    set cms=\|\|\ %s
    set ft= 
endfunction


" Change file format to meet the qf format
" Used when lines yanked from qf buffer to file to be loaded afterwards in qf
" Command: Bkqf2f
function! bookmarks#QfToFile()
    exec("%s#|#:#g")
    exec("%s# col #:#g")
endfunction


" Jump to next mark
" Command: Bkn
"function! bookmarks#Next()
    "exec "sign jump 9999 file=".expand("%:p")
"endfunction


" Jump to previous mark
" Command: 
" TODO not working.
"function! bookmarks#Next()
    "exec "sign jump 9999 file=".expand("%:p")
"endfunction


function! bookmarks#QfNormalExec(cmd)
    let l:qfWinId = s:qfWindowInit()
    if l:qfWinId < 0 | return | endif

    silent exec "normal ".a:cmd

    call s:qfWindowEnd(l:qfWinId)
endfunction


" Map keys when entering the quickfix window.
function! s:QfMapKeys()
    if !s:isBookmarksQfWindow() | return | endif

    " Set the custom quickifix mappings.
    silent! nmap dd :call bookmarks#QfNormalExec("dd")<CR>
    silent! nmap p  :call bookmarks#QfNormalExec("p")<CR>
endfunction


" Map keys when exiting the quickfix window.
function! s:UnmapKeys()
    if !s:isBookmarksQfWindow() | return | endif

    let l:qfWinId = s:qfWindowInit()
    if l:qfWinId < 0 | return | endif

    " Remove the custom quickifix mappings.
    silent! nunmap dd
    silent! nunmap p
endfunction


"------------------------------------------------
" PUML Functions:
"------------------------------------------------
" 
" Command: Bkpu
function! bookmarks#Puml()
endfunction


"------------------------------------------------
" Help And Menus Functions:
"------------------------------------------------
" Show plugin command help menu.
" Command: Bkh
function! bookmarks#Help()
    let l:text  = ""
    let l:text .= "[".s:plugin_name."] help (v".g:bookmarks_version."): \n"
    let l:text .= "  \n"
    let l:text .= "Abridged command help:\n"
    let l:text .= "\n"
    let l:text .= "- Add bookmarks:\n"
    let l:text .= "    Bka [SEP] [COMMENTS] : add new mark to bookmarks session file (SEP: ".g:bookmarks_separatorCharacters.").\n"
    let l:text .= "    Bkai [OPT]           : add new mark and indent the text (OPT: ?/number/d/i/q/s/r).\n"
    let l:text .= "\n"
    let l:text .= "- Remove bookmarks:\n"
    let l:text .= "    Bkd                  : delete bookmark on cursor position.\n"
    let l:text .= "    Bku                  : delete last saved bookmark.\n"
    let l:text .= "\n"
    let l:text .= "- Manage bookmarks session:\n"
    let l:text .= "    Bksh                 : show marks session file name.\n"
    let l:text .= "    Bkl [FILE]           : load bookmarks session marks into quickfix.\n"
    let l:text .= "    BkU                  : unload bookmarks session file.\n"
    let l:text .= "\n"
    let l:text .= "- Edit the saved bookmarks (only on bookmarks' file or quickfix window):\n"
    let l:text .= "    Bke                  : open marks session file on new tab.\n"
    let l:text .= "    [range]Bkrv          : reverse the selected lines (last line on top, first line on bottom).\n"
    let l:text .= "    [range]Bki [OPT]     : indent bookmarks file (OPT: ?/num/-/+/=).\n"
    let l:text .= "    [range]BkI [OPT]     : indent bookmarks file in reverse order (OPT: ?/num/d/i/q).\n"
    let l:text .= "    [range]Bkirm         : remove indentation on bookmarks file.\n"
    let l:text .= "    Bkin                 : show current bookmark line indentation level number.\n"
    let l:text .= "    BkiN                 : set current bookmark line indentation level number as the new indentation number.\n"
    let l:text .= "\n"
    let l:text .= "- Settings (bookmarks' file settings):\n"
    let l:text .= "    Bkpl [LINE]          : position on line number. Set indentation number to the current line indentation.\n"
    let l:text .= "                           position on current line (and current indentation) when no line provided.\n"
    let l:text .= "    Bkm [MODE]           : change/show direction mode (f:fordwards, b:backwards).\n"
    let l:text .= "                           toogle current mode when no argument found.\n"
    let l:text .= "                           show current mode when argument is ?.\n"
    let l:text .= "\n"
    let l:text .= "- Yank/Paste commands:\n"
    let l:text .= "    Bky                  : yank bookmark (file, position and line text) into system clipboard.\n"
    let l:text .= "                           add the bookmark to the yank buffer too.\n"
    let l:text .= "    BkY                  : yank bookmark (file and position only) into system clipboard.\n"
    let l:text .= "\n"
    let l:text .= "- Yank buffer commands:\n"
    let l:text .= "    Bkym [MODE]          : set yank mode (insert/append).\n"
    let l:text .= "                           toogle current mode when no argument found.\n"
    let l:text .= "                           show current mode when argument is ?.\n"
    let l:text .= "    Bkp                  : paste all bookmarks previosly yanked.\n"
    let l:text .= "    BkP                  : paste all bookmarks previosly yanked on previous line.\n"
    let l:text .= "    Bky0                 : empty all bookmarks previosly yanked.\n"
    let l:text .= "    Bkp0                 : empty all bookmarks previosly yanked.\n"
    let l:text .= "    BkyR                 : recover all previous bookmarks on yank buffer.\n"
    let l:text .= "    Bkyr                 : reverse the order on all bookmarks on yank buffer.\n"
    let l:text .= "    Bkysh                : show main yank buffer.\n"
    let l:text .= "    Bkyshp               : show previous yank buffer.\n"
    let l:text .= "\n"
    let l:text .= "- Others:\n"
    let l:text .= "    Bkqf2f               : replace qf file format to save as bookmarks file.\n"
    let l:text .= "    Bkv LEVEL            : Change plugin verbose level.\n"
    let l:text .= "\n"
    let l:text .= "Options hepl:\n"
    let l:text .= "    SEP: use separator characater. Characters allowed ".g:bookmarks_separatorCharacters."\n"
    let l:text .= "\n"
    let l:text .= "    OPT ?: show indentation configuration.\n"
    let l:text .= "    OPT number: add number to the current indentation and add bookmarks.\n"
    let l:text .= "    OPT d: decrease indentation and add bookmark indented.\n"
    let l:text .= "    OPT =: keep previous indentation and add bookmark indented.\n"
    let l:text .= "    OPT r: reset indentation number to 0 and add bookmark.\n"
    let l:text .= "    OPT s: increase indentation number and add bookmark indented without indentation number (if active).\n"
    let l:text .= "\n"
    let l:text .= "----------------------------------------------------------------------------------------------------------------------------------\n"
    let l:text .= "\n"
    let l:text .= "EXAMPLES:\n"
    let l:text .= "\n"
    let l:text .= ":Bka\n"
    let l:text .= "  Add new bookmark on current position.\n"
    let l:text .= "  Result:\n"
    let l:text .= "  filepath:line:column:...... current line text\n"
    let l:text .= "\n"
    let l:text .= ":Bka Comment text\n"
    let l:text .= "  Add new bookmark with a previous comment line.\n"
    let l:text .= "  Result:\n"
    let l:text .= "  Comment text"
    let l:text .= "  filepath:line:column:...... current line text\n"
    let l:text .= "\n"
    let l:text .= ":Bka == Title text with separator up and down\n"
    let l:text .= "  Add new bookmark with title and separators from current line.\n"
    let l:text .= "  Result:\n"
    let l:text .= "  =========================================\n"
    let l:text .= "  Title text with separator up and down\n"
    let l:text .= "  =========================================\n"
    let l:text .= "  filepath:line:column:...... current line text\n"
    let l:text .= "\n"
    let l:text .= ":Bka ## Title text with separator up and down\n"
    let l:text .= "  Add new bookmark with title and separators from current line.\n"
    let l:text .= "  Result:\n"
    let l:text .= "  #########################################\n"
    let l:text .= "  Title text with separator up and down\n"
    let l:text .= "  #########################################\n"
    let l:text .= "  filepath:line:column:...... current line text\n"
    let l:text .= "\n"
    let l:text .= ":Bka - Title text with one separator\n"
    let l:text .= "  Add new bookmark with title and separators from current line.\n"
    let l:text .= "  Result:\n"
    let l:text .= "  -----------------------------------------\n"
    let l:text .= "  Title text with one separator\n"
    let l:text .= "  filepath:line:column:...... current line text\n"
    let l:text .= "\n"
    let l:text .= ":Bkai 3\n"
    let l:text .= "  Add new bookmark with indentation.\n"
    let l:text .= "  Result:\n"
    let l:text .= "  filepath:line:column:......    current line text 1\n"
    let l:text .= "\n"
    let l:text .= ":Bkai \n"
    let l:text .= "  Add new bookmark and increase previous indentation (indentation will be 5 spaces).\n"
    let l:text .= "  Result:\n"
    let l:text .= "  filepath:line:column:......    previous line text 1\n"
    let l:text .= "  filepath:line:column:......     current line text\n"
    let l:text .= "\n"
    let l:text .= ":Bkai q\n"
    let l:text .= "  Add new bookmark and keep previous indentation (indentation will be 5 spaces).\n"
    let l:text .= "  Result:\n"
    let l:text .= "  filepath:line:column:......    previous line text 1\n"
    let l:text .= "  filepath:line:column:......     previous line text 2\n"
    let l:text .= "  filepath:line:column:......     current line text\n"
    let l:text .= "\n"
    let l:text .= ":Bkai d\n"
    let l:text .= "  Add new bookmark and decrease previous indentation (indentation will be 4 spaces).\n"
    let l:text .= "  Result:\n"
    let l:text .= "  filepath:line:column:......    previous line text 1\n"
    let l:text .= "  filepath:line:column:......     previous line text 2\n"
    let l:text .= "  filepath:line:column:......     previous line text 3\n"
    let l:text .= "  filepath:line:column:......    current line text\n"
    let l:text .= "\n"
    let l:text .= ":Bkai r\n"
    let l:text .= "  Add new bookmark and decrease previous indentation (indentation will be 0 spaces).\n"
    let l:text .= "  Result:\n"
    let l:text .= "  filepath:line:column:......    previous line text 1\n"
    let l:text .= "  filepath:line:column:......     previous line text 2\n"
    let l:text .= "  filepath:line:column:......     previous line text 3\n"
    let l:text .= "  filepath:line:column:......    previous line text\n"
    let l:text .= "  filepath:line:column:......current line text\n"
    let l:text .= "\n"

    redraw
    call s:WindowSplitMenu(4)
    call s:WindowSplit()
    silent put = l:text
    silent! exec '0file | file svnTools_plugin_help'
    normal ggdd
    call s:WindowSplitEnd()
endfunction


" Create menu items for the specified modes.
function! bookmarks#CreateMenus(modes, submenu, target, desc, cmd)
    " Build up a map command like
    let plug = a:target
    let plug_start = 'noremap <silent> ' . ' :call Bookmarks("'
    let plug_end = '", "' . a:target . '")<cr>'

    " Build up a menu command like
    let menuRoot = get(['', 'Bookmarks', '&Bookmarks', "&Plugin.&Bookmarks".a:submenu], 3, '')
    let menu_command = 'menu ' . l:menuRoot . '.' . escape(a:desc, ' ')

    if strlen(a:cmd)
        let menu_command .= '<Tab>' . a:cmd
    endif

    let menu_command .= ' ' . (strlen(a:cmd) ? plug : a:target)
    "let menu_command .= ' ' . (strlen(a:cmd) ? a:target)

    call s:Verbose(1, expand('<sfile>'), l:menu_command)

    " Execute the commands built above for each requested mode.
    for mode in (a:modes == '') ? [''] : split(a:modes, '\zs')
        if strlen(a:cmd)
            execute mode . plug_start . mode . plug_end
            call s:Verbose(1, expand('<sfile>'), "execute ". mode . plug_start . mode . plug_end)
        endif
        " Check if the user wants the menu to be displayed.
        if g:bookmarks_mode != 0
            execute mode . menu_command
        endif
    endfor
endfunction


"- Release tools ------------------------------------------------------------
"

" Create a vimball release with the plugin files.
" Commands: Bkvba
function! bookmarks#NewVimballRelease()
    let text  = ""
    let text .= "plugin/bookmarks.vim\n"
    let text .= "autoload/bookmarks.vim\n"

    silent tabedit
    silent put = l:text
    silent! exec '0file | file vimball_files'
    silent normal ggdd

    let l:plugin_name = substitute(s:plugin_name, ".vim", "", "g")
    let l:releaseName = l:plugin_name."_".g:bookmarks_version.".vmb"

    let l:workingDir = getcwd()
    silent cd ~/.vim
    silent exec "1,$MkVimball! ".l:releaseName." ./"
    silent exec "vertical new ".l:releaseName
    silent exec "cd ".l:workingDir
endfunction


"- initializations ------------------------------------------------------------

let  s:plugin = expand('<sfile>')
let  s:plugin_path = expand('<sfile>:p:h')
let  s:plugin_name = expand('<sfile>:t')

call s:Initialize()

