vim9script noclear

# Language:	Simple bookmarks system for vim
# Maintainer:	Joe Ding
# Last Change:	2025-04-18 23:59:16

if exists("g:loaded_bmk") || &cp || v:version < 901
    finish
endif
g:loaded_bmk = 1

# options	{{{1
# g:vbookmarks_omitpath controls how single-letter bookmarks show, the larger
# this option number the shorter the path shows.
#   if 0, full path is shown, which is the way to show the normal bookmarks.
#   if 1, only the last directory and the file's name is shown.
#   if 2, only file's name is shown.
# the default value is 0.
if !exists("g:vbookmarks_omitpath")
    g:vbookmarks_omitpath = 0
endif

# interface	{{{1
# mappings	{{{2
nnoremap <silent>   m`	m`<ScriptCmd>AddBmkHere('')<CR>
nnoremap <silent>   '`	<ScriptCmd>OpenBmk('')<CR>

for l in "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    exec $"nnoremap <silent>  m{l} m{l}<ScriptCmd>AddBmkHere('{l}')<CR>"
    exec $"nnoremap <silent> '{l} <ScriptCmd>OpenBmk('{l}')<CR>"
endfor

# commands	{{{2
command ListBookmarks	ListBmk()
command -nargs=? -complete=custom,BmkOpenComplete
	    \ RemoveBookmark	RemoveBmk(<f-args>)

# implements	{{{1
class BmkDict	# {{{2
    # variables		{{{3
    #   _bmk: string
    #	    The file to store bookmarks.
    #	_modify: number
    #	    The last modify time of `_bmk`
    #	_dict: dict<dict>
    #	    The bookmarks dictionary.  A bookmark records the cursor position
    #	    (line, column) in a file.  Each entry in this dictionary is also a 
    #	    dict and has the form:
    #		{file: string, line: number, column: number}
    static const _bmk: string = $'{expand("<script>:p:h:h")}/vimbookmarks.bmk'
    static var _modify: number = 0
    static var _dict: dict<dict<any>>

    static def LoadDict()	# {{{3
	if filereadable(_bmk) && getftime(_bmk) > _modify
	    _dict = readfile(_bmk)->join("\n")->js_decode()
	    _modify = getftime(_bmk)
	endif
    enddef

    static def SaveDict()	# {{{3
	writefile([js_encode(_dict)], _bmk)
	_modify = getftime(_bmk)
    enddef

    static def GetBmk(name: string): dict<any>	# {{{3
	LoadDict()
	return _dict->has_key(name) ? _dict[name] : null_dict
    enddef

    static def GetBmkKeys(): list<string>	# {{{3
	LoadDict()
	return _dict->keys()
    enddef

    static def GetBmkList(): list<list<any>>	# {{{3
	LoadDict()
	return _dict->items()->sort((a, b) => a[0] < b[0] ? -1 : 1)
    enddef

    static def AddBmk(name: string,	# {{{3
	    file: string, line: number, column: number)
	LoadDict()	# always update current data

	if _dict->has_key(name)
	    redraw
	    echo $'exist bookmark: "{name}" -> {_dict[name].file}'
	    var yn = input("update [y]/n? ")
	    if !empty(yn) && yn !~? 'y\%[es]'
		return
	    endif
	endif

	_dict[name] = {file: file, line: line, column: column}
	SaveDict()

	redraw | echo $'bookmark added: "{name}"'
    enddef

    static def RemoveBmk(name: string): dict<any>	# {{{3
	LoadDict()
	var bmk = _dict->has_key(name) ? _dict->remove(name) : null_dict
	SaveDict()
	return bmk
    enddef
endclass

# functions	{{{2
def OpenBmk(name: string)    # {{{3
    var bname = name
    if empty(name)
	bname = input("Open bookmark (empty cancels)? ", "",
	    $"custom,{expand('<SID>')}BmkOpenComplete")
	if empty(bname) | return | endif
    endif

    var bmk = BmkDict.GetBmk(bname)
    if empty(bmk)
	redraw | echo $'non-exist bookmark: "{bname}".'
	return
    endif

    if filereadable(bmk.file) || isdirectory(bmk.file)
	exec "e" bmk.file
	cursor(bmk.line, bmk.column)

    else
	redraw
	echo $'file no longer exisits: "{bname}" -> {bmk.file}'
	var yn = input("remove this bookmark [y]/n/e? ")
	if yn =~? 'e\%[dit]'
	    var file = input('update bookmark (empty cancels): ', bmk.file, 'file')
	    if !empty(file)
		bmk.file = file
		BmkDict.SaveDict()
		OpenBmk(bname)
		redraw | echo $'bookmark updated: "{bname}.'
	    endif
	elseif empty(yn) || yn =~? 'y\%[es]'
	    BmkDict.RemoveBmk(bname)
	endif
    endif
enddef

def AddBmkHere(name: string)	# {{{3
    var bname = name
    if empty(name)
	bname = input("New bookmark name (empty cancels)? ", "",
	    $"custom,{expand('<SID>')}BmkAddComplete")
	if empty(bname) | return | endif
    endif

    var pos = getpos(".")
    BmkDict.AddBmk(bname, expand("%:p"), pos[1], pos[2])
enddef

def ListBmk()	# {{{3
    var bmks = BmkDict.GetBmkList()

    if empty(bmks)
	echo "ListBookmarks: No bookmark is recorded yet."
	return
    endif

    for [key, val] in bmks
	var fname = val.file

	# omit file's path for single-letter-marks
	if g:vbookmarks_omitpath && strlen(key) == 1
	    fname = fnamemodify(val.file, ":t:r")
	    if g:vbookmarks_omitpath == 1
		fname = $'{fnamemodify(val.file, ":h:t")}/{fname}'
	    endif
	endif

	echo $'{key} -> {fname}'
    endfor
enddef

def RemoveBmk(name: string)	# {{{3
    var bname = name
    if empty(name)
	bname = input("Remove bookmark (empty cancels)? ", "",
	    $"custom,{expand('<SID>')}BmkOpenComplete")
	if empty(bname) | return | endif
    endif

    if empty(BmkDict.RemoveBmk(bname))
	echohl WarningMsg
	echo $'non-exist bookmark: "{bname}".'
	echohl None
    else
	echo $'bookmark removed: "{bname}".'
    endif
enddef

# functions for completions	" {{{3
def BmkOpenComplete(Arg: string, Cmd: string, Pos: number): string
    return BmkDict.GetBmkKeys()->join("\n")
enddef

def BmkAddComplete(Arg: string, Cmd: string, Pos: number): string
    return expand("%:t:r")
enddef
#}}}1

#defcompile
# bmk.vim	vim: ts=8 sw=4 fdm=marker
