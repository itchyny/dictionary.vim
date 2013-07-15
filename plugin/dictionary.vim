" =============================================================================
" Filename: plugin/dictionary.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/07/16 08:41:06.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=customlist,s:complete
      \ Dictionary call s:new(<q-args>)

let s:path = expand('<sfile>:p:h')
let s:exe = printf('%s/dictionary', s:path)
let s:mfile = printf('%s/dictionary.m', s:path)
let s:gcc = executable('llvm-gcc') ? 'llvm-gcc' : 'gcc'
let s:opt = '-O5 -framework CoreServices -framework Foundation'
try
  if !executable(s:exe) || getftime(s:exe) < getftime(s:mfile)
    if executable(s:gcc)
      call vimproc#system(printf('%s -o %s %s %s &',
            \                     s:gcc, s:exe, s:opt, s:mfile))
    endif
  endif
catch
endtry

let s:options = [ '-horizontal', '-vertical', '-here', '-newtab', '-below',
      \ '-cursor-word' ]
let s:noconflict = [
      \ [ '-horizontal', '-vertical', '-here', '-newtab' ],
      \ [ '-here', '-below' ],
      \ [ '-newtab', '-below' ],
      \ ]

function! s:complete(arglead, cmdline, cursorpos)
  try
    let options = copy(s:options)
    if a:arglead != ''
      let options = sort(filter(copy(s:options), 'stridx(v:val, a:arglead) != -1'))
      if len(options) == 0
        let arglead = substitute(a:arglead, '^-\+', '', '')
        let options = sort(filter(copy(s:options), 'stridx(v:val, arglead) != -1'))
        if len(options) == 0
          try
            let arglead = substitute(a:arglead, '\(.\)', '.*\1', 'g') . '.*'
            let options = sort(filter(copy(s:options), 'v:val =~? arglead'))
          catch
            let options = copy(s:options)
          endtry
        endif
      endif
    endif
    let d = {}
    for opt in options
      let d[opt] = 0
    endfor
    for opt in options
      if d[opt] == 0
        for ncf in s:noconflict
          let flg = 0
          for n in ncf
            let flg = flg || stridx(a:cmdline, n) >= 0
            if flg
              break
            endif
          endfor
          if flg
            for n in ncf
              let d[n] = 1
            endfor
          endif
        endfor
      endif
    endfor
    return sort(filter(options,
          \ 'd[v:val] == 0 && stridx(a:cmdline, v:val) == -1'))
  catch
    return []
  endtry
endfunction

function! s:new(args)
  if s:check_mac() | return | endif
  if s:check_exe() | call s:check_vimproc() | return | endif
  if s:check_vimproc() | return | endif
  let [isnewbuffer, command, words] = s:parse(a:args)
  try | silent execute command | catch | return | endtry
  call setline(1, join(words, ' '))
  call cursor(1, 1)
  startinsert!
  call s:au()
  call s:map()
  call s:initdict()
  setlocal buftype=nofile noswapfile
        \ bufhidden=hide nobuflisted nofoldenable foldcolumn=0
        \ nolist wrap completefunc= omnifunc=
        \ filetype=dictionary
endfunction

function! s:parse(args)
  let args = split(a:args, '\s\+')
  let isnewbuffer = bufname('%') != '' || &l:filetype != '' || &modified
        \ || winheight(0) > 9 * &lines / 10
  let command = 'new'
  let below = ''
  let words = []
  for arg in args
    if arg == '-horizontal'
      let command = 'new'
      let isnewbuffer = 1
    elseif arg == '-vertical'
      let command = 'vnew'
      let isnewbuffer = 1
    elseif arg == '-here' && !&modified
      let command = 'new | wincmd p | quit | wincmd p'
    elseif arg == '-newtab'
      let command = 'tabnew'
      let isnewbuffer = 1
    elseif arg == '-below'
      let below = 'below '
    elseif arg == '-cursor-word'
      let words = [s:cursorword()]
    else
      call add(words, arg)
    endif
  endfor
  let command = 'if isnewbuffer | ' . below . command . ' | endif'
  return [isnewbuffer, command, words]
endfunction

function! s:au()
  augroup Dictionary
    autocmd CursorMovedI <buffer> call s:update()
    autocmd CursorHoldI <buffer> call s:check()
    autocmd BufLeave <buffer> call s:restore()
    autocmd BufEnter <buffer> call s:updatetime()
  augroup END
endfunction

function! s:initdict()
  let b:dictionary = { 'input': '', 'history': [] }
  let b:dictionary.jump_history = []
  let b:dictionary.jump_history_index = 0
endfunction

function! s:update()
  setlocal completefunc= omnifunc=
  let word = getline(1)
  if exists('b:dictionary.proc')
    call s:check()
    try
      call b:dictionary.proc.kill(15)
      call b:dictionary.proc.waitpid()
    catch
    endtry
  endif
  try
    let b:dictionary.proc = vimproc#pgroup_open(printf('%s "%s"', s:exe, word))
    call b:dictionary.proc.stdin.close()
    call b:dictionary.proc.stderr.close()
  catch
    if !exists('b:dictionary')
      call s:initdict()
    endif
  endtry
  call s:updatetime()
endfunction

function! s:void()
  silent call feedkeys(mode() ==# 'i' ? "\<C-g>\<ESC>" : "g\<ESC>", 'n')
endfunction

function! s:check()
  try
    if !exists('b:dictionary.proc') || b:dictionary.proc.stdout.eof
      return
    endif
    let result = split(b:dictionary.proc.stdout.read(), "\n")
    let word = getline(1)
    let newword = substitute(word, ' $', '', '')
    if len(result) == 0 && b:dictionary.input ==# newword && newword !=# ''
      call s:void()
      return
    endif
    let b:dictionary.input = newword
    let curpos = getpos('.')
    silent % delete _
    call setline(1, word)
    call setline(2, result)
    try
      call b:dictionary.proc.stdout.close()
      call b:dictionary.proc.stderr.close()
      call b:dictionary.proc.waitpid()
    catch
    endtry
    unlet b:dictionary.proc
    call cursor(1, 1)
    startinsert!
    if curpos[1] == 1
      call setpos('.', curpos)
    endif
  catch
  endtry
endfunction

function! s:updatetime()
  if !exists('s:updatetime')
    let s:updatetime = &updatetime
  endif
  set updatetime=50
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
  nnoremap <buffer><silent> <Plug>(dictionary_jump_back)
        \ :<C-u>call <SID>back()<CR>
  nnoremap <buffer><silent> <Plug>(dictionary_exit)
        \ :<C-u>bdelete!<CR>
  nmap <buffer> <C-]> <Plug>(dictionary_jump)
  nmap <buffer> <C-t> <Plug>(dictionary_jump_back)
  nmap <buffer> q <Plug>(dictionary_exit)
endfunction

function! s:with(word)
  call setline(1, a:word)
  call cursor(1, 1)
  startinsert!
  let curpos = getpos('.')
  if curpos[1] == 1
    call setpos('.', curpos)
  endif
endfunction

function! s:jump()
  try
    let prev_word = substitute(getline(1), ' $', '', '')
    call insert(b:dictionary.jump_history, prev_word, b:dictionary.jump_history_index)
    let b:dictionary.jump_history_index += 1
    let word = s:cursorword()
    call s:with(word)
  catch
    call s:with('')
  endtry
endfunction

function! s:back()
  try
    if len(b:dictionary.jump_history) && b:dictionary.jump_history_index
      let b:dictionary.jump_history_index -= 1
      call s:with(b:dictionary.jump_history[b:dictionary.jump_history_index])
    else
      call s:with('')
    endif
  catch
    call s:with('')
  endtry
endfunction

function! s:cursorword()
  try
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
    if line[i - 1] =~# '^[=()\[\]{}.,; :#<>/"]'
      if i < len(line) | let i += 1 | else | let i -= 1 | endif
    endif
    return line[max([0, i - 1])]
  catch
    return ''
  endtry
endfunction

function! s:error(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl None
endfunction

function! s:check_mac()
  if !(has('mac') || has('macunix') || has('guimacvim'))
    call s:error("dictionary.vim: Mac required.")
    return 1
  endif
  return 0
endfunction

function! s:check_exe()
  if !executable(s:exe)
    call s:error("dictionary.vim: The dictionary executable is not created.")
    if !executable('gcc')
      call s:error("dictionary.vim: gcc is not available. (This plugin requires gcc.)")
    endif
    return 1
  endif
  return 0
endfunction

function! s:check_vimproc()
  if !exists('*vimproc#pgroup_open')
    call s:error("dictionary.vim: vimproc not found.")
    return 1
  endif
  return 0
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
