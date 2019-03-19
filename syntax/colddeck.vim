" Vim syntax file
" FileType:     colddeck
" Author:       fcpg
" Version:      1.0
" ---------------------------------------------------------------------

syntax clear
syntax case match


" Syntax

syn match   cdeckLine      /\v^.+$/ contains=cdeckCommand,cdeckComment
syn match   cdeckCommand   /\v^[^#]+/ contains=cdeckCmdRef,cdeckCmdFunc,cdeckCmdOp,cdeckCmdStr,cdeckResult contained
syn match   cdeckCmdRef    /\vR\d+/ contained
syn match   cdeckCmdFunc   /\v\@%(sum|min|max|avg|prod)/ contained
syn match   cdeckCmdOp     /[+*/%~|:^;<>=!?]/ contained
syn region  cdeckCmdStr    matchgroup=cdeckCmdDelim start="\[" end="\]" contained contains=cdeckCmdStr keepend extend oneline
syn match   cdeckComment   /\v#.*/ contains=cdeckResult contained

syn match   cdeckHiddenLine         /\v^.+##.*$/ contains=cdeckHiddenCommand,cdeckHidingComment
syn match   cdeckHiddenCommand      /\v^[^#]+/ contains=cdeckResult contained
syn match   cdeckHidingComment      /\v##.*/ contains=cdeckResult,cdeckHidingCommentMark contained
syn match   cdeckHidingCommentMark  /##/ contained

exe 'syn match  cdeckResult   /\V\s\zs'.get(g:, 'cdeck_rchar', '>').'\.\+\$/ contains=cdeckResSep contained'
exe 'syn match  cdeckResSep   /\V'.get(g:, 'cdeck_rchar', '>').'/ contained'


" Highlights

hi cdeckInvisible guifg=bg guibg=bg ctermbg=bg ctermfg=bg

hi link    cdeckCommand   Normal
hi link    cdeckCmdRef    Identifier
hi link    cdeckCmdFunc   Function
hi link    cdeckCmdOp     Operator
hi link    cdeckCmdStr    String
hi link    cdeckCmdDelim  Delimiter
hi link    cdeckComment   Title
hi link    cdeckResult    Special
hi link    cdeckResSep    Comment

hi link    cdeckHiddenCommand      cdeckInvisible
hi link    cdeckHidingComment      cdeckComment
hi link    cdeckHidingCommentMark  Comment

let b:current_syntax = "colddeck"
