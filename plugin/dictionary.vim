" =============================================================================
" Filename: plugin/dictionary.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/06/26 09:45:53.
" =============================================================================

if !(has('mac') || has('macunix') || has('guimacvim'))
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* Dictionary call s:new(<q-args>)

let s:path = expand('<sfile>:p:h')
let s:exe = printf('%s/dictionary', s:path)
let s:mfile = printf('%s/dictionary.m', s:path)
let s:gcc = executable('llvm-gcc') ? 'llvm-gcc' : 'gcc'
let s:opt = '-O5 -framework CoreServices -framework Foundation'
if !executable(s:exe) || getftime(s:exe) < getftime(s:mfile)
  if executable(s:gcc)
    call vimproc#system(printf('%s -o %s %s %s &', s:gcc, s:exe, s:opt, s:mfile))
  endif
endif

function! s:new(...)
  if !executable(s:exe)
    return
  endif
  new
  call setline(1, a:0 ? a:000[0] : '')
  call cursor(1, 1)
  startinsert!
  augroup Dictionary
    autocmd!
    autocmd CursorMovedI <buffer> call s:update()
    autocmd CursorHoldI <buffer> call s:check()
    autocmd BufLeave <buffer> call s:restore()
  augroup END
  setlocal buftype=nofile noswapfile wrap
        \ bufhidden=hide nobuflisted nofoldenable foldcolumn=0
        \ nolist wrap concealcursor=nvic completefunc= omnifunc=
        \ filetype=dictionary
  let b:input = ''
endfunction

function! s:update()
  setlocal completefunc= omnifunc=
  let word = getline(1)
  if exists('b:proc')
    call s:check()
    try
      call b:proc.kill(15)
      call b:proc.waitpid()
    catch
    endtry
  endif
  try
    let b:proc = vimproc#pgroup_open(printf('%s "%s"', s:exe, word))
    call b:proc.stdin.close()
    call b:proc.stderr.close()
  catch
  endtry
  if !exists('s:updatetime')
    let s:updatetime = &updatetime
  endif
  set updatetime=50
endfunction

function! s:check()
  if !exists('b:proc') || b:proc.stdout.eof
    return
  endif
  let result = split(b:proc.stdout.read(), "\n")
  let word = getline(1)
  let newword = substitute(word, ' $', '', '')
  if len(result) == 0 && b:input ==# newword && newword !=# ''
    return
  endif
  let b:input = newword
  let curpos = getpos('.')
  silent % delete _
  call setline(1, word)
  call setline(2, result)
  call b:proc.stdout.close()
  call b:proc.stderr.close()
  call b:proc.waitpid()
  call cursor(1, 1)
  startinsert!
  if curpos[1] == 1
    call setpos('.', curpos)
  endif
endfunction

function! s:restore()
  try
    if exists('s:updatetime')
      let &updatetime = s:updatetime
    endif
    unlet s:updatetime
  catch
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

