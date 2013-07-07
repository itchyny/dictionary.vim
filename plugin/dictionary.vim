" =============================================================================
" Filename: plugin/dictionary.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/07/07 09:28:25.
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
let s:history = []
let s:history_index = 0
try
  if !executable(s:exe) || getftime(s:exe) < getftime(s:mfile)
    if executable(s:gcc)
      call vimproc#system(printf('%s -o %s %s %s &',
            \                     s:gcc, s:exe, s:opt, s:mfile))
    endif
  endif
catch
endtry

function! s:complete(arglead, cmdline, cursorpos)
  try
    let opts = [ '-horizontal', '-vertical', '-here', '-newtab', '-below',
          \ '-cursor-word' ]
    let options = opts
    let noconflict = [
          \ [ '-horizontal', '-vertical', '-here', '-newtab' ],
          \ [ '-here', '-below' ],
          \ [ '-newtab', '-below' ],
          \ ]
    if a:arglead != ''
      let options = sort(filter(copy(opts), 'stridx(v:val, a:arglead) != -1'))
      if len(options) == 0
        let arglead = substitute(a:arglead, '^-\+', '', '')
        let options = sort(filter(copy(opts), 'stridx(v:val, arglead) != -1'))
        if len(options) == 0
          try
            let arglead = substitute(a:arglead, '\(.\)', '.*\1', 'g') . '.*'
            let options = sort(filter(copy(opts), 'v:val =~? arglead'))
          catch
            let options = opts
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
        for ncf in noconflict
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
  setlocal buftype=nofile noswapfile
        \ bufhidden=hide nobuflisted nofoldenable foldcolumn=0
        \ nolist wrap concealcursor=nvic completefunc= omnifunc=
        \ filetype=dictionary
  let b:dictionary = { 'input': '', 'history': [] }
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
    autocmd!
    autocmd CursorMovedI <buffer> call s:update()
    autocmd CursorHoldI <buffer> call s:check()
    autocmd BufLeave <buffer> call s:restore()
  augroup END
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

function! s:void()
  silent call feedkeys(mode() ==# 'i' ? "\<C-g>\<ESC>" : "g\<ESC>", 'n')
endfunction

function! s:check()
  if !exists('b:proc') || b:proc.stdout.eof
    return
  endif
  let result = split(b:proc.stdout.read(), "\n")
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
    call b:proc.stdout.close()
    call b:proc.stderr.close()
    call b:proc.waitpid()
  catch
  endtry
  unlet b:proc
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
  nnoremap <buffer><silent> <Plug>(dictionary_jump_back)
        \ :<C-u>call <SID>back()<CR>
  nnoremap <buffer><silent> <Plug>(dictionary_exit)
        \ :<C-u>bdelete!<CR>
  nmap <buffer> <C-]> <Plug>(dictionary_jump)
  nmap <buffer> <C-[> <Plug>(dictionary_jump_back)
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
  let prev_word = substitute(getline(1), ' $', '', '')
  if get(s:history, s:history_index - 1, '') !=# prev_word
    call insert(s:history, prev_word, s:history_index)
    let s:history_index += 1
  endif
  let word = s:cursorword()
  call insert(s:history, word, s:history_index)
  let s:history_index += 1
  call s:with(word)
  " echo s:history
endfunction

function! s:back()
  " try
    if len(s:history) && s:history_index
      let s:history_index -= 1
      call s:with(s:history[s:history_index])
    else
      call s:with('')
    endif
  " catch
  " endtry
  " call s:with('')
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
