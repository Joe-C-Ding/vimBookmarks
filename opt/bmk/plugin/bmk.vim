" bmk.vim	vim: ts=8 sw=4 ff=unix fdm=marker
" Language:	Simple bookmarks system for vim
" Maintainer:	Joe Ding
" Version:	0.95
" Last Change:	2017-10-26 17:42:09

if &cp || exists("g:loaded_bmk")
    finish
endif
let g:loaded_bmk = 1

let s:keepcpo = &cpo
set cpo&vim

" mappings	{{{1
nnoremap <silent>   m`	:call AddBmkHere('')<CR>
nnoremap <silent>   '`	:call OpenBmk('')<CR>

let letters = split("A B C D E F G H I J K L M N O P Q R S T U V W X Y Z")
for l in letters
    exec 'nnoremap <silent>  m'.l.' :call AddBmkHere("'.l.'")<CR>'
    exec "nnoremap <silent> \'".l.' :call OpenBmk("'.l.'")<CR>'
endfor


" functions	{{{1
let s:bookmarks = expand("<sfile>:p:h") . '/../vimbookmarks.bmk'
let s:bmkdict = {}
let s:bufnumber = -1

function! LoadDict()	" {{{2
    if s:bufnumber < 0
	exec "split +hide " . s:bookmarks
	let s:bufnumber = bufnr(s:bookmarks)
    endif
    let lines = getbufline(s:bufnumber, 1, "$")
    let s:bmkdict = js_decode(join(lines, "\n"))
endfunction

function! SaveDict()	" {{{2
    let json = js_encode(s:bmkdict)
    exec "split " . s:bookmarks

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
	if yn != '' || yn !~ 'y\%[es]'
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

    silent call SaveDict()
endfunction

function! OpenBmk(name)    " {{{2
    let name = a:name
    if a:name == ""
	let name = input("Open bookmark [keep empty to cancel]? ")
	if name == "" | return | endif
    endif

    silent call LoadDict()
    if !has_key(s:bmkdict, name)
	echo 'noexist bookmark: "'.name.'"'
	return
    endif

    let bmk = s:bmkdict[name]
    if glob(bmk.file) == ""
	echo 'file no longer exisits: "'.name.'" -> '.s:bmkdict[name].file
	let yn = input("remove this bookmark [y]/n? ")
	if yn != '' || yn !~ 'y\%[es]'
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
	let name = input("New bookmark name [keep empty to cancel]? ")
	if name == "" | return | endif
    endif

    let pos = getpos(".")
    call AddBmk(name, expand("%:p"), pos[1], pos[2])
endfunction

function! BmkCompare(i1, i2)
    return a:i1[0] < a:i2[0] ? -1 : 1
endfunction

command -nargs=0 ListBookmarks	:call ListBmk()
function! ListBmk()
    silent call LoadDict()

    let templist = items(s:bmkdict)
    call sort(templist, "BmkCompare")

    for i in templist
	echo i[0]." -> ".i[1].file
    endfor
endfunction

" }}}1
" clean up
let &cpo = s:keepcpo
unlet s:keepcpo
