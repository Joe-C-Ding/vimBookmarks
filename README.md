# vimBookmarks
simple bookmarks plugin for vim

中文说明在[这里](https://github.com/Joe-C-Ding/joe-c-ding.github.io/issues/1)

## Featrue
Vim comes with marks system itself, which is very useful.  All the marks will be written to viminfo file when vim quiting, but if you have more than one vim instance running, viminfo will be overwriten by the one who quits later, and many information will lose including those of marks.

This plugin
- use a file to sync all bookmarks among all vim instances. It reads that file before performing actions, and writes it immediately if any change is made.
- compatible with vim internal mark A-Z. (of corse for current instance of vim if more than one is runing) 
- named bookmarks is available. 26 marks are not enough rignt? :)

If you are not familiar with vim marks, see `:h mark-motions` for details.

## Key mappings and commands
map/cmd | action
----|----
mX | to add bookmarks named X at current cursor position of this file.  `X` can be any uppercase letter, means `A-Z`. (this also set vim mark X at the same position too)
'X | to jump to the bookmark X.
m` | to create a named bookmarks interactivly.  `<Tab>` may be used to perform completion of current filename when asking you to enter the bookmark's name. (this also set vim mark ` too)
'` | to jump to a named bookmarks. `<Tab>` to perform completion.
:ListBookmarks | list all bookmarks

## Installation
This plugin is desinged as a package of vim.

Just clone it into
- `~/.vim/pack` for unix-like system or
- `~/vimfiles/pack` for Windows system

and enable this plugin see below.

## Enable/disable plugin
Adding 
```vim-script
packadd! bmk
```
into your vimrc file to enable this plugin. You should know how to disable it now :)

## Dependency
*required* Vim version is >= 9.1.

This plugin is rewrighten in new vim 9 script. And `class` is used, which is introdued from 9.1.
Packages is introduced into vim from 8.0. And this plugin also depends on functions `js_encode` and `js_decode`, which is introduced from 8.0.

if your Vim version is >= 8.0, there is a commit taged vim8 can be used. It is the last version before upgrated to vim 9.
Now this 2 version has the exactly the same features. However Vim 9 has come, the new the better! :)

More about using vim packages see vim's document `:h packages`.
