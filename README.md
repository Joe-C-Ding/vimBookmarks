# vimBookmarks
simple bookmarks plugin for vim

## installation
This plugin is desinged as a package of vim.

Just clone it into
- `~/.vim/pack` for unix-like system or
- `~/vimfiles/pack` for Windows system
and enable this plugin see below.

## enable/disable plugin
Adding 
```vim-script
packadd! bmk
```
into your vimrc file to enable this plugin.You should know how to disable it now :)

## dependency
*required* vim version is >= 8.0
Packages is introduced into vim from 8.0, and this plugin depends on functions `js_encode` and `js_decode`, which is also introduced from 8.0.

More about using vim packages see vim's document `:h packages`, or visit the online version
