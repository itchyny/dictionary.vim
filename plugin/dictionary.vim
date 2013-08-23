" =============================================================================
" Filename: plugin/dictionary.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/08/23 19:50:39.
" =============================================================================

if exists('g:loaded_dictionary') && g:loaded_dictionary
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -complete=customlist,s:complete
      \ Dictionary call dictionary#new(<q-args>)

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
    return sort(filter(options, 'd[v:val] == 0 && stridx(a:cmdline, v:val) == -1'))
  catch
    return s:options
  endtry
endfunction

let g:loaded_dictionary = 1

let &cpo = s:save_cpo
unlet s:save_cpo
