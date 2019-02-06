" bmk.vim	vim: ts=8 sw=4 ff=unix fdm=marker
" Language:	Simple bookmarks system for vim
" Maintainer:	Joe Ding
" Version:	0.9.9
" Last Change:	2019-02-06 16:30:11

if &cp || v:version < 800 || exists("g:loaded_bmk")
    finish
endif
let g:loaded_bmk = 1

let s:keepcpo = &cpo
set cpo&vim

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
let s:bufnumber = -1

function! LoadDict()	" {{{2
    if s:bufnumber < 0	" first time we need to load it from file
	silent exec 'split ' . s:bookmarks
	setl bufhidden=hide nobuflisted noswapfile
	hide

	" and this file will stay in memory for after use
	let s:bufnumber = bufnr(s:bookmarks)
    else
	silent exec 'split ' . s:bookmarks
	e!	" reload the file.
	hide
    endif

    let lines = getbufline(s:bufnumber, 1, "$")
    if empty(lines) || lines == ['']
	let lines = ['{}']
    endif
    let s:bmkdict = js_decode(join(lines, "\n"))
endfunction

function! SaveDict()	" {{{2
    let json = js_encode(s:bmkdict)
    silent exec "split " . s:bookmarks

    %d_	" this deletes all contents in that file
    call setline(1, json)
    w	" and updates them with new ones
    hide
endfunction

function! AddBmk(name, file, line, column) " {{{2
    silent call LoadDict()	" always update current data

    if has_key(s:bmkdict, a:name)
	echo 'exist bookmark: "'.a:name.'" -> '.s:bmkdict[a:name].file
	let yn = input("update [y]/n? ")
	if yn != '' && yn !~ 'y\%[es]'
	    " if no changes are needed, code below will be skipped
	    return
	endif
    endif

    let s:bmkdict[a:name] = {'file': a:file, 'line':a:line, 'column':a:column}
    echo 'bookmark added: "'.a:name.'"'

    silent call SaveDict()   " otherwise save every changes to the file
endfunction

function! RemvoeBmk(name)  " {{{2
    silent call LoadDict()

    if !has_key(s:bmkdict, a:name)
	return
    endif
    call remove(s:bmkdict, a:name)
    echo 'bookmark removed: "'.a:name.'"'

    silent call SaveDict()
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
	echo 'noexist bookmark: "'.name.'"'
	return
    endif

    let bmk = s:bmkdict[name]
    if glob(bmk.file) == ""
	echo 'file no longer exisits: "'.name.'" -> '.s:bmkdict[name].file
	let yn = input("remove this bookmark [y]/n? ")
	if yn != '' && yn !~ 'y\%[es]'
	    return
	endif
	silent call RemvoeBmk(name)

    else
	exec "e " . bmk.file
	call cursor(bmk.line, bmk.column)
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
function! BmkCompare(i1, i2)	" {{{3
    return a:i1[0] < a:i2[0] ? -1 : 1
endfunction

function! ListBmk() " {{{3
    silent call LoadDict()

    let templist = items(s:bmkdict)
    call sort(templist, "BmkCompare")

    for i in templist
	echo i[0]." -> ".i[1].file
    endfor
endfunction

" functions for completions	" {{{2
function! BmkOpenComplete(ArgLead, CmdLine, CursorPos)	" {{{3
    let comp = keys(s:bmkdict)
    return join(comp, "\n")
endfunction

function! BmkAddComplete(ArgLead, CmdLine, CursorPos)	" {{{3
    " complete for AddBmkHere
    return expand("%:t:r")
endfunction
" }}}1

" clean up
let &cpo = s:keepcpo
unlet s:keepcpo
