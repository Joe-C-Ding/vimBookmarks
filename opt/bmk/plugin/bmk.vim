" bmk.vim	vim: ts=8 sw=4 fdm=marker
" Language:	Simple bookmarks system for vim
" Maintainer:	Joe Ding
" Version:	1.2
" Last Change:	2025-04-17 18:31:18

if &cp || v:version < 800 || exists("g:loaded_bmk")
    finish
endif
let g:loaded_bmk = 1

let s:keepcpo = &cpo
set cpo&vim

" options	{{{1
" g:vbookmarks_omitpath controls how single-letter bookmarks show, the larger
" this option number the shorter the path shows.
"   if 0, full path is shown, which is the way to show the normal bookmarks.
"   if 1, only the last directory and the file's name is shown.
"   if 2, only file's name is shown.
" default value is 0.
if !exists("g:vbookmarks_omitpath")
    let g:vbookmarks_omitpath = 0
endif

" mappings	{{{1
nnoremap <silent>   m`	m`:call AddBmkHere('')<CR>
nnoremap <silent>   '`	:call OpenBmk('')<CR>

for l in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    exec 'nnoremap <silent>  m'.l.' m'.l.':call AddBmkHere("'.l.'")<CR>'
    exec 'nnoremap <silent> '''.l.' :call OpenBmk("'.l.'")<CR>'
endfor

" commands	{{{1
command ListBookmarks	:call ListBmk()
function! ListBmk() abort	" {{{2
    call s:LoadDict()

    if empty(s:bmkdict)
	echo "ListBookmarks: No bookmark is recorded yet."
	return
    endif

    let templist = items(s:bmkdict)->sort({a,b -> a[0]<b[0] ? -1 : 1})

    " omit file's path for single-letter-marks
    for i in templist
	if g:vbookmarks_omitpath && strlen(i[0]) == 1
	    let l:fname = fnamemodify(i[1].file, ":t:r")
	    if g:vbookmarks_omitpath == 1
		let l:fname = fnamemodify(i[1].file, ":h:t") .. '/' .. l:fname
	    endif
	else
	    let l:fname = i[1].file
	endif

	echo i[0] '->' l:fname
    endfor
endfunction
" }}}2

" functions	{{{1
let s:bookmarks = expand("<sfile>:p:h") . '/../vimbookmarks.bmk'
let s:modify = 0
let s:bmkdict = {}

function! OpenBmk(name)    " {{{2
    call s:LoadDict()

    if a:name == ""
	let l:name = input("Open bookmark (empty cancels)? ", "",
			\"custom,BmkOpenComplete")
	if empty(l:name) | return | endif
    else
	let l:name = a:name
    endif

    if !has_key(s:bmkdict, l:name)
	redraw | echo 'non-exist bookmark: "'.l:name.'"'
	return
    endif

    let l:bmk = s:bmkdict[l:name]
    if file_readable(bmk.file) || isdirectory(bmk.file)
	exec "e" bmk.file
	call cursor(bmk.line, bmk.column)

    else
	redraw
	echo 'file no longer exisits: "'.l:name.'" -> '.l:bmk.file
	let yn = input("remove this bookmark [y]/n/e? ")
	if yn =~? 'e\%[dit]'
	    let l:file = input('update bookmark (empty cancels): ', l:bmk.file, 'file')
	    if !empty(l:file)
		let l:bmk.file = l:file
		call s:SaveDict()
		call OpenBmk(l:name)
		redraw | echo 'bookmark updated: "'.l:name.'"'
	    endif
	elseif empty(yn) || yn =~? 'y\%[es]'
	    call s:RemoveBmk(l:name)
	endif
    endif
endfunction

function! AddBmkHere(name) " {{{2
    if a:name == ""
	let l:name = input("New bookmark name (empty cancels)? ","",
			\"custom,BmkAddComplete")
	if empty(l:name) | return | endif
    else
	let l:name = a:name
    endif

    let pos = getpos(".")
    call s:AddBmk(l:name, expand("%:p"), pos[1], pos[2])
endfunction

function! s:LoadDict()	" {{{3
    if filereadable(s:bookmarks) && getftime(s:bookmarks) > s:modify
	let s:bmkdict = js_decode(join(readfile(s:bookmarks), "\n"))
	let s:modify = getftime(s:bookmarks)
    end
endfunction

function! s:SaveDict()	" {{{3
    call writefile([js_encode(s:bmkdict)], s:bookmarks)
    let s:modify = getftime(s:bookmarks)
endfunction

function! s:AddBmk(name, file, line, column) " {{{3
    call s:LoadDict()	" always update current data

    if has_key(s:bmkdict, a:name)
	redraw
	echo 'exist bookmark: "'.a:name.'" -> '.s:bmkdict[a:name].file
	let yn = input("update [y]/n? ")
	if !empty(yn) && yn !~ 'y\%[es]'
	    return
	endif
    endif

    let s:bmkdict[a:name] = #{file: a:file, line:a:line, column:a:column}
    call s:SaveDict()   " otherwise save every changes to the file

    redraw | echo 'bookmark added: "'.a:name.'"'
endfunction

" commands	{{{1
command -nargs=? -complete=custom,BmkOpenComplete
	    \ RemoveBookmark	:call <SID>RemoveBmk(<f-args>)

function! s:RemoveBmk(name) abort	" {{{2
    if a:name == ""
	let l:name = input("Remove bookmark (empty cancels)? ","",
			\"custom,BmkOpenComplete")
	if empty(l:name) | return | endif
    else
	let l:name = a:name
    endif

    call s:LoadDict()
    if has_key(s:bmkdict, l:name)
	call remove(s:bmkdict, l:name)
	silent call s:SaveDict()
	redraw | echo 'bookmark removed: "'.l:name.'"'
    else
	echo 'non-exist bookmark: "'.l:name.'"'
    endif
endfunction

" functions for completions	" {{{3
function! BmkOpenComplete(ArgLead, CmdLine, CursorPos)
    call s:LoadDict()
    return keys(s:bmkdict)->join("\n")
endfunction

function! BmkAddComplete(ArgLead, CmdLine, CursorPos)
    return expand("%:t:r")
endfunction
" }}}1

" clean up
let &cpo = s:keepcpo
unlet s:keepcpo
