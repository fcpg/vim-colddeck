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

"---------------
" Mappings {{{1
"---------------

if !get(g:, 'cdeck_nomaps', 0)
  nnoremap <buffer>  <silent>  <Localleader>x  :<C-u>CDCalc<cr>
  nnoremap <buffer>  <silent>  <Localleader>c  :<C-u>CDClear<cr>
  nnoremap <buffer>  <silent>  <Localleader>a  :<C-u>CDToggleAutocalc<cr>
  nnoremap <buffer>  <silent>  <Localleader>A  :<C-u>CDAlignHidingComments<cr>

  nnoremap <buffer>  <silent>  <Localleader>h  :<C-u>CDToggleHidingComments<cr>
  nnoremap <buffer>  <silent>  <Localleader><
        \ :<C-u>CDMoveRCol <C-r>=empty(v:count)? "-5" : v:count<cr><cr>
  nnoremap <buffer>  <silent>  <Localleader>>
        \ :<C-u>CDMoveRCol <C-r>=empty(v:count)? "+5" : v:count<cr><cr>
  nnoremap <buffer>  <silent>  <Localleader>$  :<C-u>call search('\v^.*\zs\S\ze%<'.
        \ (get(b:, "cdeck_rcol", get(g:, "cdeck_rcol", 78))+1) . 'v.',
        \ '',
        \ line('.'))<cr>
endif
