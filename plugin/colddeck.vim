" colddeck.vim - column-dc spreadsheet

let s:save_cpo = &cpo
set cpo&vim

"---------------
" Commands {{{1
"---------------

" Re-calculate values and insert results
command! -bar CDCalc
      \ call colddeck#CalcBuffer()

" Clear results
command! -bar CDClear
      \ call colddeck#RemoveResults()

" Toggle autocalc (auto-insertion of results when leaving insert mode)
command! -bar CDToggleAutocalc
      \  if !get(b:, 'cdeck_auto_', 0)
      \|   call colddeck#SetAutoCalc()
      \|   echo "AutoCalc ON"
      \| else
      \|   call colddeck#UnsetAutoCalc()
      \|   echo "AutoCalc OFF"
      \| endif

" Move the result column (absolute pos, or relative with +/- prefix)
command! -bar -nargs=1 CDMoveRCol
      \ call colddeck#MoveRcol(<q-args>)

" Right-align 'hiding comments' near results
command! -bar CDAlignHidingComments
      \ call colddeck#AlignHidingComments()

" Toggle normal/hiding comments
let s:keeppa = exists(':keeppattern') ? 'keeppa' : ''
command! -bar CDToggleHidingComments
      \  if getline('.') =~ '##'
      \|   silent exe s:keeppa 's/##/# /e'
      \| else
      \|   silent exe s:keeppa 's/# /##/e'
      \| endif



"---------------
" Autocmds {{{1
"---------------

" Discard results before saving file, put them back afterwards
" Can be global or buffer-locxl
augroup CDeckSave
  au!
  autocmd BufWritePre *.cdeck
        \  if !get(b:, 'cdeck_saveresults', get(g:, 'cdeck_saveresults', 0))
        \|   call colddeck#RemoveResults()
        \| endif
  autocmd BufWritePost *.cdeck
        \  if !get(b:, 'cdeck_saveresults', get(g:, 'cdeck_saveresults', 0))
        \|   call colddeck#CalcBuffer()
        \| endif
augroup END

" Activate autocalc for cdeck filetype if option is set
" Global only
augroup CDeckFiletype
  au!
  if get(g:, 'cdeck_autocalc', 1)
    autocmd FileType colddeck  call colddeck#CalcBuffer()
  endif
augroup END


let &cpo = s:save_cpo
