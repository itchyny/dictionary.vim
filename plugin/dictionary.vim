" =============================================================================
" Filename: plugin/dictionary.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/12/14 14:21:42.
" =============================================================================

if exists('g:loaded_dictionary') || v:version < 702
  finish
endif
let g:loaded_dictionary = 1

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=customlist,dictionary#complete
      \ Dictionary call dictionary#new(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
