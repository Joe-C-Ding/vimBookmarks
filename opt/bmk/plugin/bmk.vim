" bmk.vim	vim: ts=8 sw=4 fdm=marker
" Language:	Simple bookmarks system for vim
" Maintainer:	Joe Ding
" Version:	1.0
" Last Change:	2020-04-10 17:27:00

if &cp || v:version < 800 || exists("g:loaded_bmk")
    finish
endif
let g:loaded_bmk = 1

let s:keepcpo = &cpo
set cpo&vim

" options	{{{1
" if g:vbookmarks_omitpath is true, then for single-letter bookmarks only the
" corresponding files name are shown, the paths are ignored.
if !exists("g:vbookmarks_omitpath")
    let g:vbookmarks_omitpath = 0
endif

" mappings	{{{1
nnoremap <silent>   m`	m`:call AddBmkHere('')<CR>
nnoremap <silent>   '`	:call OpenBmk('')<CR>

let s:letters = split("A B C D E F G H I J K L M N O P Q R S T U V W X Y Z")
for l in s:letters
    exec 'nnoremap <silent>  m'.l.' m'.l.':call AddBmkHere("'.l.'")<CR>'
    exec "nnoremap <silent> \'".l.' :call OpenBmk("'.l.'")<CR>'
endfor
unlet s:letters

" commands	{{{1
command -nargs=0 ListBookmarks	:call ListBmk()

" functions	{{{1
let s:bookmarks = expand("<sfile>:p:h") . '/../vimbookmarks.bmk'
let s:bmkdict = {}

function! LoadDict()	" {{{2
    if filereadable(s:bookmarks)
	let lines = readfile(s:bookmarks)
    else
	let lines = ['{}']
    end
    let s:bmkdict = js_decode(join(lines, "\n"))
endfunction

function! SaveDict()	" {{{2
    call writefile([js_encode(s:bmkdict)], s:bookmarks)
endfunction

function! AddBmk(name, file, line, column) " {{{2
    silent call LoadDict()	" always update current data

    if has_key(s:bmkdict, a:name)
	redraw
	echo 'exist bookmark: "'.a:name.'" -> '.s:bmkdict[a:name].file
	let yn = input("update [y]/n? ")
	if yn != '' && yn !~ 'y\%[es]'
	    " if no changes are needed, code below will be skipped
	    return
	endif
    endif

    let s:bmkdict[a:name] = {'file': a:file, 'line':a:line, 'column':a:column}
    redraw | echo 'bookmark added: "'.a:name.'"'

    silent call SaveDict()   " otherwise save every changes to the file
endfunction

function! RemoveBmk(name)  " {{{2
    silent call LoadDict()

    if has_key(s:bmkdict, a:name)
	call remove(s:bmkdict, a:name)
	redraw | echo 'bookmark removed: "'.a:name.'"'
	silent call SaveDict()
    endif
endfunction

function! OpenBmk(name)    " {{{2
    silent call LoadDict()

    let name = a:name
    if a:name == ""
	let name = input("Open bookmark [keep empty to cancel]? ",
		    \"", "custom,BmkOpenComplete")
	if name == "" | return | endif
    endif

    if !has_key(s:bmkdict, name)
	redraw | echo 'non-exist bookmark: "'.name.'"'
	return
    endif

    let bmk = s:bmkdict[name]
    if file_readable(bmk.file) || isdirectory(bmk.file)
	exec "e " . bmk.file
	call cursor(bmk.line, bmk.column)

    else
	redraw
	echo 'file no longer exisits: "'.name.'" -> '.s:bmkdict[name].file
	let yn = input("remove this bookmark [y]/n? ")
	if yn != '' && yn !~ 'y\%[es]'
	    return
	endif
	silent call RemoveBmk(name)
    endif
endfunction

function! AddBmkHere(name) " {{{2
    let name = a:name
    if a:name == ""
	let name = input("New bookmark name [keep empty to cancel]? ",
		    \"", "custom,BmkAddComplete")
	if name == "" | return | endif
    endif

    let pos = getpos(".")
    call AddBmk(name, expand("%:p"), pos[1], pos[2])
endfunction

" functions for commands    " {{{2
function! ListBmk() " {{{3
    silent call LoadDict()

    if empty(s:bmkdict)
	echohl WarningMsg
	echo "ListBookmarks: No bookmark is recorded yet."
	echohl None
	return
    endif

    let templist = items(s:bmkdict)->sort({a,b -> a[0]<b[0] ? -1 : 1})

    " omit file's path for single-letter-marks
    for i in templist
	if g:vbookmarks_omitpath && strlen(i[0]) == 1
	    let fname = fnamemodify(i[1].file, ":t:r")
	else
	    let fname = i[1].file
	endif

	echo i[0] '->' fname
    endfor
endfunction

" functions for completions	" {{{2
function! BmkOpenComplete(ArgLead, CmdLine, CursorPos)	" {{{3
    return keys(s:bmkdict)->join("\n")
endfunction

" complete for AddBmkHere
function! BmkAddComplete(ArgLead, CmdLine, CursorPos)	" {{{3
    return expand("%:t:r")
endfunction
" }}}1

" clean up
let &cpo = s:keepcpo
unlet s:keepcpo
