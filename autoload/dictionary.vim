" =============================================================================
" Filename: autoload/dictionary.vim
" Author: itchyny
" License: MIT License
" Last Change: 2019/10/28 15:56:00.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:path = expand('<sfile>:p:h')
let s:mfile = printf('%s/dictionary.m', s:path)
let s:exepath = substitute(get(g:, 'dictionary_executable_path', s:path), '/*$', '', '')
let s:exename = get(g:, 'dictionary_executable_name', 'dictionary')
let s:exe = expand(printf('%s/%s', s:exepath, s:exename))
let s:gccdefault = executable('llvm-gcc') ? 'llvm-gcc' : 'gcc'
let s:gcc = get(g:, 'dictionary_compile_command', s:gccdefault)
let s:optdefault = '-O3 -framework CoreServices -framework Foundation'
let s:opt = get(g:, 'dictionary_compile_option', s:optdefault)
try
  if !executable(s:exe) || getftime(s:exe) < getftime(s:mfile)
    if executable(s:gcc)
      call system(printf('%s -o %s %s %s &', s:gcc, s:exe, s:opt, s:mfile))
    endif
  endif
catch
endtry

function! dictionary#new(args) abort
  if s:check_mac() | return | endif
  if s:check_exe() | return | endif
  let [isnewbuffer, command, words] = s:parse(a:args)
  try | silent execute command | catch | return | endtry
  call setline(1, join(words, ' '))
  call cursor(1, 1)
  startinsert!
  call s:autocmd()
  call s:mapping()
  let b:dictionary = {
        \ 'input': '',
        \ 'jump_history': [],
        \ 'jump_history_index': 0,
        \ 'latest_channel_id': -1,
        \ 'current_channel_id': -1,
        \ }
  setlocal buftype=nofile noswapfile
        \ bufhidden=hide nobuflisted nofoldenable foldcolumn=0
        \ nolist wrap completefunc=DictionaryComplete omnifunc=
        \ filetype=dictionary completefunc=DictionaryComplete omnifunc=
endfunction

function! s:search_buffer() abort
  let bufs = filter(tabpagebuflist(), "getbufvar(v:val, '&ft') ==# 'dictionary'")
  if len(bufs)
    return { 'command': bufwinnr(bufs[0]) . 'wincmd w' }
  else
    return {}
  endif
endfunction

function! s:parse(args) abort
  let args = split(a:args, '\s\+')
  let isnewbuffer = bufname('%') !=# '' || &l:filetype !=# '' || &modified
        \ || winheight(0) > 9 * &lines / 10
  let name = " `=s:buffername('dictionary')`"
  let command = 'new'
  let below = ''
  let words = []
  let addname = 1
  for arg in args
    if arg =~? '^-*horizontal$'
      let command = 'new'
      let isnewbuffer = 1
    elseif arg =~? '^-*vertical$'
      let command = 'vnew'
      let isnewbuffer = 1
    elseif arg =~? '^-*here$'
      let command = 'try | edit' . name . ' | catch | new' . name . ' | endtry'
      let addname = 0
    elseif arg =~? '^-*here!$'
      let command = 'edit!'
    elseif arg =~? '^-*newtab$'
      let command = 'tabnew'
      let isnewbuffer = 1
    elseif arg =~? '^-*below$'
      if command ==# 'tabnew'
        let command = 'new'
      endif
      let below = 'below '
    elseif arg =~? '^-*no-duplicate$'
      let command = get(s:search_buffer(), 'command', command)
      let addname = command !~# 'wincmd'
      let isnewbuffer = 1
    elseif arg =~? '^-*cursor-word$'
      let words = [s:cursorword()]
    else
      call add(words, arg)
    endif
  endfor
  let cmd1 = below . command . (addname ? name : '')
  let cmd2 = 'edit' . name
  let command = 'if isnewbuffer | ' . cmd1 . ' | else | ' . cmd2 . '| endif'
  return [isnewbuffer, command, words]
endfunction

let s:options = [ '-horizontal', '-vertical', '-here', '-newtab', '-below',
      \ '-no-duplicate', '-cursor-word' ]
let s:noconflict = [
      \ [ '-horizontal', '-vertical', '-here', '-newtab' ],
      \ [ '-here', '-below' ],
      \ [ '-newtab', '-below' ],
      \ ]

function! dictionary#complete(arglead, cmdline, ...) abort
  try
    let options = copy(s:options)
    if a:arglead !=# ''
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
    return sort(filter(options, 'd[v:val] == 0 && stridx(a:cmdline, v:val) == -1'))
  catch
    return s:options
  endtry
endfunction

function! s:buffername(name) abort
  let buflist = []
  for i in range(tabpagenr('$'))
   call extend(buflist, tabpagebuflist(i + 1))
  endfor
  let matcher = 'bufname(v:val) =~# ("\\[" . a:name . "\\( \\d\\+\\)\\?\\]") && index(buflist, v:val) >= 0'
  let substituter = 'substitute(bufname(v:val), ".*\\(\\d\\+\\).*", "\\1", "") + 0'
  let bufs = map(filter(range(1, bufnr('$')), matcher), substituter)
  let index = 0
  while index(bufs, index) >= 0 | let index += 1 | endwhile
  return '[' . a:name . (len(bufs) && index ? ' ' . index : '') . ']'
endfunction

function! s:autocmd() abort
  augroup Dictionary
    autocmd CursorMovedI <buffer> call s:update()
  augroup END
endfunction

function! DictionaryComplete(findstart, ...) abort
  return a:findstart ? -1 : []
endfunction

function! s:update() abort
  let word = s:get_word()
  if b:dictionary.input ==# word
    return
  endif
  let b:dictionary.latest_channel_id = ch_info(job_getchannel(job_start(
        \ printf('%s "%s" </dev/null', s:exe, word),
        \ { 'out_cb': function('s:stdout'),
        \   'exit_cb': function('s:exit') }))).id
endfunction

function! s:stdout(ch, msg)
  if !has_key(b:, 'dictionary')
    return
  endif
  let curpos = getpos('.')
  let channel_id = ch_info(a:ch).id
  if b:dictionary.current_channel_id != channel_id
    if b:dictionary.latest_channel_id == b:dictionary.current_channel_id
      return
    else
      let b:dictionary.current_channel_id = channel_id
      let word = getline(1)
      silent % delete _
      call setline(1, word)
    endif
  endif
  let b:dictionary.input = s:get_word()
  call setline(line('$') + 1, split(a:msg, "\n"))
  call cursor(1, 1)
  startinsert!
  if curpos[1] == 1
    call setpos('.', curpos)
  endif
endfunction

function! s:exit(job, status) abort
  if !has_key(b:, 'dictionary')
    return
  endif
  if s:get_word() ==# ''
    let b:dictionary.input = ''
    let b:dictionary.current_channel_id = -1
    let b:dictionary.latest_channel_id = -1
    silent % delete _
  endif
endfunction

function! s:get_word() abort
  return substitute(getline(1), ' *$', '', '')
endfunction

function! s:mapping() abort
  if &l:filetype ==# 'dictionary'
    return
  endif
  let save_cpo = &cpo
  set cpo&vim
  nnoremap <buffer><silent> <Plug>(dictionary_jump)
        \ :<C-u>call <SID>jump()<CR>
  nnoremap <buffer><silent> <Plug>(dictionary_jump_back)
        \ :<C-u>call <SID>back()<CR>
  nnoremap <buffer><silent> <Plug>(dictionary_exit)
        \ :<C-u>bdelete!<CR>
  inoremap <buffer><silent> <Plug>(dictionary_nop)
        \ <Nop>
  nmap <buffer> <C-]> <Plug>(dictionary_jump)
  nmap <buffer> <C-t> <Plug>(dictionary_jump_back)
  nmap <buffer> q <Plug>(dictionary_exit)
  imap <buffer> <CR> <Plug>(dictionary_nop)
  let &cpo = save_cpo
endfunction

function! s:with(word) abort
  call setline(1, a:word)
  call cursor(1, 1)
  startinsert!
  let curpos = getpos('.')
  if curpos[1] == 1
    call setpos('.', curpos)
  endif
endfunction

function! s:jump() abort
  try
    let prev_word = s:get_word()
    call insert(b:dictionary.jump_history, prev_word, b:dictionary.jump_history_index)
    let b:dictionary.jump_history_index += 1
    let word = s:cursorword()
    call s:with(word)
  catch
    call s:with('')
  endtry
endfunction

function! s:back() abort
  try
    if len(b:dictionary.jump_history) && b:dictionary.jump_history_index
      let b:dictionary.jump_history_index -= max([v:count, 1])
      let b:dictionary.jump_history_index = max([b:dictionary.jump_history_index, 0])
      call s:with(b:dictionary.jump_history[b:dictionary.jump_history_index])
    else
      call s:with('')
    endif
  catch
    call s:with('')
  endtry
endfunction

function! s:cursorword() abort
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

function! s:error(msg) abort
  echohl ErrorMsg
  echomsg 'dictionary.vim: '.a:msg
  echohl None
endfunction

function! s:check_mac() abort
  if !(has('mac') || has('macunix') || has('gui_mac') || system('uname') =~? '^darwin')
    call s:error('Mac is required.')
    return 1
  endif
  return 0
endfunction

function! s:check_exe() abort
  if !executable(s:exe)
    call s:error('The dictionary executable is not created.')
    try
      if !isdirectory(expand(s:exepath))
        call mkdir(expand(s:exepath), 'p')
      endif
      if executable(s:gcc)
        call system(printf('%s -o %s %s %s &', s:gcc, s:exe, s:opt, s:mfile))
      endif
    catch
    endtry
    if !exists('g:dictionary_compile_option') && !executable('gcc')
      call s:error('gcc is not available. (This plugin requires gcc.)')
    endif
    return 1
  endif
  return 0
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
