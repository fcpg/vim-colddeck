" Vim filetype plugin file
" Language: colddeck

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let b:undo_ftplugin = "setl cc< nu< | unlet! b:cdeck_results"

let &l:cc = get(g:, 'cdeck_rcol', 78)
setl nu

let b:cdeck_results = {}

if get(b:, 'cdeck_autocalc', get(g:, 'cdeck_autocalc', 1))
  call colddeck#SetAutoCalc()
endif

