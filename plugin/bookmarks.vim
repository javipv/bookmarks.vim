" Script Name: boomarks.vim
 "Description: enhanced bookmarks: 
" - Allows to load bookmarks on quickifix window. 
" - Save bookmarks to file.
" - Load bookmarks from file.
" - Edit saved bookmarks, add comments..
" - Show bookmarks comments on quickfix window.
" - Indent bookmarks to better display the code flow when used to mark lins on
"   code files.
" - Save marks to file or as config line on the file.
"
" Copyright:   (C) 2019-2021
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:  <javierpuigdevall@gmail.com>
"
" Dependencies: jpLib.vim
"
" NOTES:
"
" Version:      1.0.0
" Changes:
"   - Fix: allow Bki Bkr commands even if no bookmarks file configured.
"   - New: Bkedit command to edit the plugin files.
"   - Fix: indenting line with payload starting witch character $
" 1.0.0 	Wed, 2 Jun 21.     JPuigdevall
"   - First release published

if exists('g:loaded_bookmarks')
    finish
endif

let g:loaded_bookmarks = 1
let s:save_cpo = &cpo
set cpo&vim

let s:leader = exists('g:mapleader') ? g:mapleader : ''

let g:bookmarks_version = "1.0.0"


"- configuration --------------------------------------------------------------
"

let g:bookmarks_fileDflt                  =  get(g:, 'bookmarks_fileDflt', "vim_bookmarks.ll")
let g:bookmarks_mode                      =  get(g:, 'bookmarks_mode', 3) " Display menu on gvim

" Alignment Config:
" Align the bookmarks columns, 
" Exmple not aligned: 
"   "/dir1:line:column line_text"
"   "/dir1/dir2/file:line:column line_text"
" Exmple aligned:
"   "/dir1:line:column................... line_text"
"   "/dir1/dir2/file:line:column......... line_text"
let g:bookmarks_alignment                 =  get(g:, 'bookmarks_alignment', 1)

" Start the "line_text" field on this column.
let g:bookmarks_alignPadding1             =  get(g:, 'bookmarks_alignPadding1', 95)

" Set to 1 to use padding character.
let g:bookmarks_alignmentPadding          =  get(g:, 'bookmarks_alignmentPadding', 1)

" Define the padding character, default is '.'
let g:bookmarks_alignmentPaddingChar      =  get(g:, 'bookmarks_alignmentPaddingChar', "\.")

" Comment Separator Config:
" Example using config: bookmarks_separatorLengh=40 and bookmarks_separatorCharacters='=':
"   "========================================"
" Separator lenght:
let g:bookmarks_separatorLengh            =  get(g:, 'bookmarks_separatorLengh', 80)
" Separator characters:
let g:bookmarks_separatorCharacters       =  get(g:, 'bookmarks_separatorCharacters', "= - # _ . *")

" Save To File Config:
let g:bookmarks_lineNumber                =  get(g:, 'bookmarks_lineNumber', "G")
" Direction modes allowed: fordward (insert new value before last line), backward (insert new value after last line)
let g:bookmarks_dirMode                   =  get(g:, 'bookmarks_dirMode', "fordward")

" Line Feed Config:
let g:bookmarks_lineFeedAskUser           =  get(g:, 'bookmarks_lineFeedAskUser', 0)
let g:bookmarks_lineFeedOnDirChange       =  get(g:, 'bookmarks_lineFeedOnDirChange', 1)
let g:bookmarks_lineFeedOnFileChange      =  get(g:, 'bookmarks_lineFeedOnFileChange', 0)
let g:bookmarks_lineFeedOnFileNameChange  =  get(g:, 'bookmarks_lineFeedOnFileNameChange', 0)

" Indentation Format Config1:
let g:bookmarks_showIndentNum             =  get(g:, 'bookmarks_showIndentNum', 0)
let g:bookmarks_indentNumPre              =  get(g:, 'bookmarks_indentNumPre', "")
let g:bookmarks_indentNumPost             =  get(g:, 'bookmarks_indentNumPost', " ")

" Indentation Format Config2:
"let g:bookmarks_showIndentNum             =  get(g:, 'bookmarks_showIndentNum', 1)
"let g:bookmarks_indentNumPre              =  get(g:, 'bookmarks_indentNumPre', "")
"let g:bookmarks_indentNumPost             =  get(g:, 'bookmarks_indentNumPost', "> ")

" Yank Buffer Config:
" Modes allowed: insert (insert new value on top), append (append new value at the end)
let g:bookmarks_yankBuffer_mode           =  get(g:, 'bookmarks_yankBuffer_mode', "insert")

" Mark Config:
let g:bookmarks_loadSignsOnFileOpen       =  get(g:, 'bookmarks_loadSignsOnFileOpen', 0)
let g:bookmarks_loadSignsOnFileDelete     =  get(g:, 'bookmarks_loadSignsOnFileDelete', 1)
let g:bookmarks_loadSignsOnBookmarksLoad  =  get(g:, 'bookmarks_loadSignsOnBookmarksLoad', 0)


"- commands -------------------------------------------------------------------

" Add bookmark (add comment/title too if required)
" Bookmark Format: "file:row:column...........text"
"
"     Bka Examples:
"     :Bka   "file:line:column...... line_text"
"
"     :Bka == This is a title comment  
"       "================================================================================================================================================================"
"       "This is a title comment"
"       "================================================================================================================================================================"
"       "file:line:column...... line_text"
"
"     :Bka - This is a comment:  
"       "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
"       "This is a comment:"
"       "file:line:column...... line_text"
"       
"     :Bka - This is a new title comment:  
"       "################################################################################################################################################################"
"       "This is a new title comment:"
"       "################################################################################################################################################################"
"       "file:line:column...... line_text"
"
command! -nargs=* Bka            call bookmarks#AddMark(<f-args>)

" Bookmark Format: "file:row:column...........text"
command! -nargs=* Bkac           call bookmarks#AddMarkWithComment()


" Indentation examples for commands Bki and Bkif 
"     Indentation Config1:
"     let g:bookmarks_showIndentNum = 0
"     let g:bookmarks_indentNumPre  = ""
"     let g:bookmarks_indentNumPost = " "
"
"     Examples Using Indentation Config1:
"     :Bki   "file:line:column...... line_text"
"     :Bki 1 "file:line:column...... line_text"
"     :Bki   "file:line:column......  line_text"
"     :Bki 3 "file:line:column......   line_text"
"     :Bki = "file:line:column......   line_text"
"     :Bki - "file:line:column......  line_text"
"     :Bki _ "file:line:column......  line_text"
"     :Bki 3 "file:line:column......   line_text"
"     :Bki 0 "file:line:column......line_text"
"
"     Indentation Config2:
"     let g:bookmarks_showIndentNum = 1
"     let g:bookmarks_indentNumPre  = ""
"     let g:bookmarks_indentNumPost = "> "
"
"     Examples Using Indentation Config2:
"     Bki   "file:line:column......n> line_text"
"     Bki 1 "file:line:column......1> line_text"
"     Bki   "file:line:column...... 2> line_text"
"     Bki 3 "file:line:column......  3> line_text"
"     Bki = "file:line:column......  3> line_text"
"     Bki - "file:line:column...... 2> line_text"
"     Bki _ "file:line:column......  line_text"
"     Bki 3 "file:line:column......  3> line_text"
"     Bki 0 "file:line:column......line_text"

" Add bookmark with indentation.
command! -nargs=? Bkai            call bookmarks#AddMarkIndentNumber("<args>")

command! -nargs=? -range Bki <line1>,<line2>call bookmarks#IndentBookmarksFile("<args>")
" Indent bookmarks file in reverse order, from last line to first
command! -nargs=? -range BkI <line1>,<line2>call bookmarks#IndentReverseBookmarksFile(<f-args>)

" Remove bookmarks indentation.
command! -nargs=0 -range Bkirm <line1>,<line2>call bookmarks#RemoveIndentBookmarksFile()

" Show bookmarks indentation number on current line.
command! -nargs=0 Bkin call bookmarks#GetIndentationNumber()

" Set current indentation level on current bookmark as the last indentation level.
command! -nargs=0 BkiN call bookmarks#SetCurrentAsIndentationNumber()

" Change/showw direction mode (f:fordward, b:backward)
command! -nargs=? Bkm call bookmarks#SetDirectionMode("<args>")

" Change line number on bookmarks file where inserting the bookmark
" Set current indentation level on current bookmark as the last indentation level.
command! -nargs=? Bkpl call bookmarks#PositionOnLine("<args>")

" Set line position and movement direction.
"command! -nargs=* Bkpm call bookmarks#ChangePositionAndMode(<f-args>)

" Delete mark placed on current position.
command! -nargs=0 Bkd            call bookmarks#Delete()

" Undo. Delete last bookmark
command! -nargs=0 Bku            call bookmarks#RmLastMark()

" Reverse current selected lines
command! -nargs=0 -range Bkrv  <line1>,<line2>call bookmarks#ReverseLines()


" Yank current line to std register with as bookmark
" Format: "file:row:column...........text"
command! -nargs=0 Bky            call bookmarks#YankLine()

" Select yank buffer mode to insert new value: insert (on top), append (on bottom).
command! -nargs=? Bkym           call bookmarks#YankBufferMode("<args>")

" Paste all previous lines yanked
command! -nargs=0 Bkp            call bookmarks#PasteLastYankedLines("textSelection emptyBuffer")
command! -nargs=0 BkP            call bookmarks#PasteLastYankedLines("textSelection emptyBuffer pasteBeforeLine")

" Empty the yank buffer.
command! -nargs=0 Bky0           call bookmarks#EmptyYankedLines()
command! -nargs=0 Bkp0           call bookmarks#EmptyYankedLines()

" Recover the previous yank buffer.
command! -nargs=0 BkyR           call bookmarks#RecoverPreviousYankedLines()

" Show the yank buffer.
command! -nargs=0 Bkysh          call bookmarks#ShowYankBuffer("main")
command! -nargs=0 Bkyshp         call bookmarks#ShowYankBuffer("backup")

" Reverse the yank buffer content.
command! -nargs=0 Bkyr           call bookmarks#ReversYankBuffer()

" Yank current bookmark to std register.
" Format: "file:row:column"
command! -nargs=0 BkY            call bookmarks#YankFilePos()

" Load a bookmarks file
" Show current bookmarks on a linked list window.
command! -nargs=? -complete=file Bkl call bookmarks#Load(<f-args>)

" Unlaod current bookmarks file.
command! -nargs=0 BkU            call bookmarks#Unload()

" Edit bookmarks file on new tab.
command! -nargs=0 Bke            call bookmarks#Edit()

" Show the bookmarks file name.
command! -nargs=0 Bksh           call bookmarks#Show("")

" Change log level
command! -nargs=? Bkv            call bookmarks#Verbose("<args>")

" Show bookmark commands help.
command! -nargs=0 Bkh            call bookmarks#Help()

" Replace qf file format to save as bookmarks file."
command! -nargs=0 Bkqf2f         call bookmarks#QfToFile()

" Release functions:
" Create a new vimball release
command! -nargs=0  Bkvba         call bookmarks#NewVimballRelease()

" PUML Functions:
" TODO: allow to convert bookmarks to UML files 
"command! -nargs=0 Bkpu          call bookmarks#Puml()

" Edit plugin functions:
command! -nargs=0  Bkedit        call bookmarks#EditPlugin()


"- mappings -------------------------------------------------------------------

" Save bookmark without indentation.
nnoremap <leader>ba :Bka <CR>

" Save bookmark without indentation, add comment.
nnoremap <leader>bc :Bkac<CR>

" Save bookmark, reset indentation.
nnoremap <leader>br :Bkai r<CR>

" Save bookmark, increase indentation.
nnoremap <leader>bi :Bkai i<CR>

" Save bookmark, decrement indentation.
nnoremap <leader>bd :Bkai d<CR>

" Save bookmark, keep same indentation.
nnoremap <leader>bq :Bkai q<CR>


"if !hasmapto('Bkif', 'n')
    "autocmd Filetype qf nnoremap <buffer> >>        :call bookmarks#IndentBookmarksFile("<args>")<CR>
    "autocmd Filetype qf nnoremap <buffer> >>        :Bkif +<CR>
    "autocmd Filetype qf nnoremap <buffer> <<        :Bkif -<CR>
"endif

"if !hasmapto('Bki', 'n')
    "nnoremap <unique> <leader>bi :Bki <CR>
"endif

if !hasmapto('Bky', 'n')
    nnoremap <unique> <leader>by :Bky <CR>
endif

if !hasmapto('BkY', 'n')
    nnoremap <unique> <leader>bY :BkY <CR>
endif


"- abbreviations -------------------------------------------------------------------
" DEBUG functions: reload plugin
cnoreabbrev _bkrl    <C-R>=bookmarks#Reload()<CR>


"- menus -------------------------------------------------------------------
"
if has("gui_running")
    call bookmarks#CreateMenus('cn' , '.&Add'        , ':Bka [SEPARATOR] [COMMENTS]'   , 'Add new bookmark'                   , ':Bka [SEPARATOR] [COMMENTS]')
    call bookmarks#CreateMenus('cn' , '.&Add'        , ':Bkai [OPT]'  , 'Add indented bookmarks (OPT: ?/num/-/+/=)'           , ':Bkai [OPT]')

    call bookmarks#CreateMenus('cn' , '.&Remove'     , ':Bkd'   , 'Remove mark on cursor position'                            , ':Bkd')
    call bookmarks#CreateMenus('cn' , '.&Remove'     , ':Bku'   , 'Remove last bookmark'                                      , ':Bku')

    call bookmarks#CreateMenus('cn' , '.&Config'     , ':Bksh'  , 'Show bookmarks file name'                                  , ':Bksh')
    call bookmarks#CreateMenus('cn' , '.&Config'     , ':Bkl'   , 'Load bookmarks file into quickfix'                         , ':Bkl [FILE]')
    call bookmarks#CreateMenus('cn' , '.&Config'     , ':BkU'   , 'Remove session file'                                       , ':BkU')
    call bookmarks#CreateMenus('cn' , '.&Config'     , ':Bke'   , 'Edit bookmarks file'                                       , ':Bke')

    call bookmarks#CreateMenus('cn' , '.&Config'     , ':Bkrv'  , 'Reverse selected lines'                                    , ':Bkrv')
    call bookmarks#CreateMenus('cn' , '.&Indent'     , ':Bki'   , 'Indent bookmarks file (OPT: ?/num/-/+/=)'                  , ':Bki [OPT]')
    call bookmarks#CreateMenus('cnv', '.&Indent'     , ':BkI'   , 'Indent bookmarks file in reverse order (OPT: ?/num/-/+/=)' , ':BkI [OPT]')
    call bookmarks#CreateMenus('cn' , '.&Indent'     , ':Bkirm' , 'Remove indentation on bookmarks file'                      , ':Bkirm')
    call bookmarks#CreateMenus('cn' , '.&Indent'     , ':Bkin'  , 'Show current line indentation level number'                , ':Bkin')
    call bookmarks#CreateMenus('cn' , '.&Indent'     , ':BkiN'  , 'Set current line indentation as saved indentation level'   , ':BkiN')


    call bookmarks#CreateMenus('cn' , '.&Setting'    , ':Bkpl'  , 'Position on line number'                                   , ':Bkpl [LINE]')
    call bookmarks#CreateMenus('cn' , '.&Setting'    , ':Bkm'   , 'change/show direction mode (f:fordwards, b:backwards)'     , ':Bkm [MODE]')

    call bookmarks#CreateMenus('cn' , '.&Yank/Paste' , ':BkY'   , 'yank file, position and line mark'                         , ':Bky')
    call bookmarks#CreateMenus('cn' , '.&Yank/Paste' , ':Bky'   , 'yank line mark'                                            , ':BkY')
    call bookmarks#CreateMenus('cn' , '.&Yank/Paste' , ':Bkym [MODE]'  , 'set yank mode (insert/append)'                             , ':Bkym')
    call bookmarks#CreateMenus('cn' , '.&Yank/Paste' , ':Bkp'   , 'paste all yanked lines, empty buffer'                      , ':Bkp')
    call bookmarks#CreateMenus('cn' , '.&Yank/Paste' , ':BkP'   , 'paste all yanked lines on previous line, empty buffer'     , ':BkP')
    call bookmarks#CreateMenus('cn' , '.&Yank/Paste' , ':Bkp0'  , 'empty all yanked lines'                                    , ':Bkp0')
    call bookmarks#CreateMenus('cn' , '.&Yank/Paste' , ':BkpR'  , 'recover all previous yanked lines'                         , ':BkyR')
    call bookmarks#CreateMenus('cn' , '.&Yank/Paste' , ':Bkysh' , 'show main yank buffer'                                     , ':Bkysh')
    call bookmarks#CreateMenus('cn' , '.&Yank/Paste' , ':Bkyshp', 'show previous yank buffer'                                 , ':Bkyshp')
    call bookmarks#CreateMenus('cn' , '.&Yank/Paste' , ':Bkyr'  , 'reverse the yank buffer content'                           , ':Bkyr')

    call bookmarks#CreateMenus('cn' , '.&Others'     , ':Bkqtf' , 'Replace qf format to save on marks file'                   , ':Bkqtf')
    call bookmarks#CreateMenus('cn' , '.&Others'     , ':Bkv'   , 'Change log level verbosity'                                , ':Bkv LEVEL')

    call bookmarks#CreateMenus('n'  , '' , ':' , '-Sep-'                                     , '')

    call bookmarks#CreateMenus('n'  , ''             , ':Bka'    , 'Add bookmark'                                              , s:leader.'ba')
    call bookmarks#CreateMenus('n'  , ''             , ':Bkai i' , 'Add bookmark indented, increase previous indentation'      , s:leader.'bi')
    call bookmarks#CreateMenus('n'  , ''             , ':Bkai d' , 'Add bookmark indented, decrease previous indentation'      , s:leader.'bd')
    call bookmarks#CreateMenus('n'  , ''             , ':Bkai q' , 'Add bookmark indented, keep previous indentation'          , s:leader.'bq')
    call bookmarks#CreateMenus('n'  , ''             , ':Bkai r' , 'Add bookmark, reset indentation to 0'                      , s:leader.'br')
    call bookmarks#CreateMenus('n'  , ''             , ':Bky'    , 'Yank file, position and line mark'                         , s:leader.'by')
    call bookmarks#CreateMenus('n'  , ''             , ':BkY'    , 'Yank line mark'                                            , s:leader.'bY')

    call bookmarks#CreateMenus('n'  , '' , ':' , '-Sep2-'                                     , '')

    call bookmarks#CreateMenus('cn' , ''             , ':Bkh'   , 'Show command help'                                         , ':Bkh')
endif

let &cpo = s:save_cpo
unlet s:save_cpo
