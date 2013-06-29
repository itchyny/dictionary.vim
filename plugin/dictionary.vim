" =============================================================================
" Filename: plugin/dictionary.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/06/30 03:19:13.
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
  call s:map()
  setlocal buftype=nofile noswapfile
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
    silent call feedkeys(mode() ==# 'i' ? "\<C-g>\<ESC>" : "g\<ESC>", 'n')
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

function! s:map()
  if &l:filetype ==# 'dictionary'
    return
  endif
  nnoremap <buffer><silent> <Plug>(dictionary_jump)
        \ :<C-u>call <SID>jump()<CR>
  nmap <buffer> <C-]> <Plug>(dictionary_jump)
endfunction

function! s:jump()
  let curpos = getpos('.')
  let c = curpos[2]
  let line = split(getline(curpos[1]), '\<\|\>')
  let i = 0
  while c > 0 && i < len(line)
    let c -= strlen(line[i])
    let i += 1
  endwhile
  if i > len(line)
    let i -= 1
  elseif i < 1
    let i += 1
  endif
  if line[i - 1] =~# '^[()\[\].,]'
    if i < 2 | let i += 1 | else | let i -= 1 | endif
  endif
  call setline(1, line[max([0, i - 1])])
  call cursor(1, 1)
  startinsert!
  if curpos[1] == 1
    call setpos('.', curpos)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

