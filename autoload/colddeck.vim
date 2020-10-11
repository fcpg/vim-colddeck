" colddeck.vim - column-dc spreadsheet

let s:save_cpo = &cpo
set cpo&vim

"------------
" Debug {{{1
"------------

let g:cdeck_debug = 1
if 0
append
  " comment out all dbg calls
  :g,\c^\s*call <Sid>Dbg(,s/call/"call/
  " uncomment
  :g,\c^\s*"call <Sid>Dbg(,s/"call/call/
.
endif


"--------------
" Options {{{1
"--------------

" Defaults
let s:def_rcol     = 78
let s:def_prec     = 2
let s:def_precmd   = ''
let s:def_autoahc  = 1
let s:def_dcerr    = 0

" Errors
let s:err_notavail        = get(g:, 'cdeck_err_notavail', '[N/A]')
let s:err_valref_notfound = printf('[%s]',
      \ get(g:, 'cdeck_err_valref_notfound', 'value ref not found (yet)'))
let s:err_vimexpr = printf('[%s]',
      \ get(g:, 'cdeck_err_vim_expr', 'vim expression error'))

" Library of dc macros
"   - stored in '*' array
"   - input expected in '(' array
"   - output goes in ')' array (though these macros don't depend on it)
"
" 0: expand ranges
" 1: pop number and execute 'Y' macro that many times ('fold', kinda)
" 2: sum over stack with num of elems on top
" 3: multiply over stack with num of elems on top
" 4: find min over stack with num of elems on top
" 5: find max over stack with num of elems on top
" 6: compute average over stack with num of elems on top
let s:dc_lib_cmd = join([
      \ '[SEdSSSI[lI;(xlI1+dsIlE!<X]dSXxLIs-LXs-LELS-1+]',  '0:*',
      \ '[[dSI0<YLI1-d1<X]dSXxs-LYs-LXs-]',                 '1:*',
      \ '[[+]SY1;*x]',                                      '2:*',
      \ '[[*]SY1;*x]',                                      '3:*',
      \ '[[dSArdSBlAlB[r]SR<Rs-LAs-LBs-LRs-]SY1;*x]',       '4:*',
      \ '[[dSArdSBlAlB[r]SR>Rs-LAs-LBs-LRs-]SY1;*x]',       '5:*',
      \ '[dSN[+]SY1;*xLN/]',                                '6:*',
      \])

" Macros invocation
let s:dc_range = ' 0;*x'
let s:dc_sum   = ' 2;*x'
let s:dc_prod  = ' 3;*x'
let s:dc_min   = ' 4;*x'
let s:dc_max   = ' 5;*x'
let s:dc_avg   = ' 6;*x'

" Default value '[]' in 's' register
let s:dc_defval_cmd = '[[]]s+'

" '[True]' string in '?' (for user convenience, not used internally)
let s:dc_truereg_cmd = '[[True]]s?'


"----------------
" Functions {{{1
"----------------

" colddeck#ParseLine()
"
" Parse a single line from current buffer
" 
" Args:
"   - line number
" Returns:
"   - dict:
"     - 'cmd': command
"     - 'rem': comment
"
function! colddeck#ParseLine(linenr) abort
  let ret  = {'cmd': '', 'rem': ''}
  let rcol = get(b:, 'cdeck_rcol', get(g:, 'cdeck_rcol', s:def_rcol))
  let line = getline(a:linenr)
  " trim results
  let line_nores = substitute(strpart(line, 0, rcol), '\s*$', '', '')
  let mlist      = matchlist(line_nores, '\v\c^([^#]*)(#%(.*\S)?)?\s*$')
  let cmdpart    = substitute(get(mlist, 1, ''), '\s\+$', ' ', '')
  let ret['rem'] = get(mlist, 2, '')
  if cmdpart =~ '^\s*$'
    " store an empty string
    let tmpcmd = '[]'
  else
    let tmpcmd = cmdpart
    " expand `$+num` refs
    let tmpcmd = substitute(tmpcmd,
          \ '\$\(\d\+\)',
          \ '\=get(b:cdeck_results, submatch(1), "VALREF_ERROR")',
          \ 'g')
    if tmpcmd =~ 'VALREF_ERROR'
      " expansion error, ignore this line
      let tmpcmd = s:err_valref_notfound
    endif
    " expand backticks
    try
      let tmpcmd = substitute(tmpcmd,
            \ '`\([^`]*\)`',
            \ '\=string(eval(submatch(1)))',
            \ 'g')
    catch
      " eval error, ignore this line
      let tmpcmd = s:err_vimexpr
    endtry
    " expand `R+num:R+num` ref ranges
    let tmpcmd = substitute(tmpcmd,
          \ '\CR\(\d\+\):R\(\d\+\)',
          \ ' \1 \2 ' . s:dc_range,
          \ 'g')
    " expand `@sum`
    let tmpcmd = substitute(tmpcmd, '\C@sum', s:dc_sum, 'g')
    " expand `@prod`
    let tmpcmd = substitute(tmpcmd, '\C@prod', s:dc_prod, 'g')
    " expand `@min`
    let tmpcmd = substitute(tmpcmd, '\C@min', s:dc_min, 'g')
    " expand `@max`
    let tmpcmd = substitute(tmpcmd, '\C@max', s:dc_max, 'g')
    " expand `@avg`
    let tmpcmd = substitute(tmpcmd, '\C@avg', s:dc_avg, 'g')
    " expand `R+num` refs
    let tmpcmd = substitute(tmpcmd, '\C\vR(\d+)', ' \1;(x', 'g')
    " expand relative refs
    let tmpcmd = substitute(tmpcmd, '\C\vR([+-]\d+)',
          \ '\=" ".('.a:linenr.'+submatch(1)).";(x"', 'g')
  endif
  " store cmd as string into array '(', indexed by line num
  let ret['cmd'] = printf('[%s]%s:(', tmpcmd, a:linenr)
  "call <Sid>Dbg("parsed line (#, cmd, rem):", a:linenr, ret['cmd'], ret['rem'])
  return ret
endfun


" colddeck#CalcBuffer()
"
" Evaluate values and commands, then insert results after rcol
"
function! colddeck#CalcBuffer() abort
  let rcol   = get(b:, 'cdeck_rcol',    get(g:, 'cdeck_rcol',    s:def_rcol))
  let prec   = get(b:, 'cdeck_prec',    get(g:, 'cdeck_prec',    s:def_prec))
  let precmd = get(b:, 'cdeck_precmd',  get(g:, 'cdeck_precmd',  s:def_precmd))
  let autoac = get(b:, 'cdeck_autoahc', get(g:, 'cdeck_autoahc', s:def_autoahc))
  let rchar  = get(g:, 'cdeck_rchar', '>')
  let dcpath = get(g:, 'cdeck_dc_path', 'dc')
  let dc_init_cmd  = join([
        \ prec."k",
        \ s:dc_defval_cmd,
        \ s:dc_truereg_cmd,
        \ precmd,
        \ "c",
        \], '')
  let dc_store_cmd = ""
  let dc_calc_cmd  = ""
  let dc_show_cmd  = ""
  let dc_cmd = ""
  let lastlinenr = line('$')
  let bufmodified = &modified

  let curpos = getcurpos()

  " clear previous results
  call colddeck#RemoveResults()

  " parse buffer and build dc cmdline
  let linenr = 1
  while linenr <= lastlinenr
    let parsedline    = colddeck#ParseLine(linenr)
    let dc_store_cmd .= parsedline['cmd']
    let dc_calc_cmd  .= "c".linenr.';(xz0=+'.linenr.':) '
    let dc_show_cmd   = linenr.';)' . dc_show_cmd
    let linenr += 1
  endwhile

  " execute in dc
  let dc_cmd = join([
        \ s:dc_lib_cmd,
        \ dc_init_cmd,
        \ dc_store_cmd,
        \ dc_calc_cmd,
        \ "c",
        \ dc_show_cmd,
        \ "f",
        \])
  "call <Sid>Dbg("dc_cmd:", dc_cmd)
  let dc = dcpath .
        \ (!get(b:, 'cdeck_dcerr', get(g:, 'cdeck_dcerr', s:def_dcerr))
        \   ? ' 2>/dev/null'
        \   : '')
  let dc_result = systemlist(dc, dc_cmd)
  "call <Sid>Dbg("dc_result:", string(dc_result))

  " insert new results
  let linenr = 1
  let b:cdeck_results = {}
  while linenr <= lastlinenr
    let curline    = getline(linenr)
    let linelen    = strwidth(curline)
    let fillcount  = max([rcol - linelen, 1])
    let lineresult = get(dc_result, linenr - 1, s:err_notavail)
    if !empty(lineresult)
      let updatedline = substitute(curline,
            \ '$',
            \ printf('\=repeat(" ", %d)."%s %s"',
            \   fillcount, rchar, escape(lineresult, '"')),
            \ "")
      call setline(linenr, updatedline)
    endif
    let b:cdeck_results[linenr] = lineresult
    let linenr += 1
  endwhile

  " auto-align 'hiding comments'
  if autoac
    call colddeck#AlignHidingComments()
  endif

  " restore cursor pos
  call setpos('.', curpos)

  " Ignore results insertion for modified status
  let &modified = bufmodified
endfun


" colddeck#RemoveResults()
"
" Remove results from buffer (text after rcol)
"
function! colddeck#RemoveResults() abort
  let bufmodified = &modified
  let curpos = getcurpos()
  let rcol = get(b:, 'cdeck_rcol', get(g:, 'cdeck_rcol', s:def_rcol))
  silent exe '%s/\v^.*\S\zs\s*%(%'.rcol.'v.*\S.*)$//e'
  call setpos('.', curpos)
  let &modified = bufmodified
endfun


" colddeck#MoveRcol()
"
" Move result column
"
" Args:
"   - number (absolute position), with '+/-' prefix for relative motion
"
function! colddeck#MoveRcol(col) abort
  call colddeck#RemoveResults()
  if a:col[0] =~ '[+-]'
    " relative motion
    let cur_rcol = get(b:, 'cdeck_rcol', get(g:, 'cdeck_rcol', s:def_rcol))
    let b:cdeck_rcol = cur_rcol + str2nr(a:col)
  else
    let b:cdeck_rcol = a:col
  endif
  call colddeck#CalcBuffer()
endfun


" colddeck#AlignHidingComments()
"
" Right-align 'hiding comments' near results
"
function! colddeck#AlignHidingComments() abort
  let bufmodified = &modified
  let rcol = get(b:, 'cdeck_rcol', get(g:, 'cdeck_rcol', s:def_rcol))
  silent exe '%s/\v(##.*\S)(\s+)\ze%'.rcol.'v./\2\1/e'
  let &modified = bufmodified
endfun


" Autocmds {{{2
"---------------

" colddeck#SetAutoCalc()
"
" Add events to insert results automatically
" (currently, only on InsertLeave)
"
function! colddeck#SetAutoCalc() abort
  if !get(b:, 'cdeck_auto_', 0)
    autocmd InsertLeave <buffer>  call colddeck#CalcBuffer()
    let b:cdeck_auto_ = 1
  endif
endfun


" colddeck#UnsetAutoCalc()
"
" Delete events that inserted results automatically
"
function! colddeck#UnsetAutoCalc() abort
  if get(b:, 'cdeck_auto_', 0)
    autocmd! InsertLeave <buffer>
    let b:cdeck_auto_ = 0
  endif
endfun


" Debug {{{2
"------------
function! s:Dbg(msg, ...) abort
  if g:cdeck_debug
    let m = a:msg
    if a:0
      let m .= " [".join(a:000, "] [")."]"
    endif
    echom m
  endif
endfun


let &cpo = s:save_cpo
