# bookmarks.vim
Enhanced bookmarks

## Description

Save line under cursor to a bookmark's file (:Bka).

The bookmark's format will be:

filepath:line:column:...... current line text

This bookmark's file can later be opened (:Bke) or loaded into a quickfix window (:Bkl) for quick access to the bookmarks.

Use :Bkh to see the latest command set.

Primary used when inspecting programs to save the code flow, saving bookmarks to lines of code where the code flow changes, like function calls, if statements, etc.

There are several enhanced options to save code indented in order to depict the code flow on different levels.

## Install 

Minimum version: Vim 7.0+

Recomended version: Vim 8.0+

Binaries: ag (silver searcher) or grep needed to open the filter window.

## Install vimball:

download bookmarks_1.0.0.vmb

vim bookmarks_1.0.0.vmb

:so %
:q
