" =============================================================================
" Filename: syntax/dictionary.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/06/24 13:18:26.
" =============================================================================

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

syntax region DictionaryName start='\%2l' end='$'
      \ keepend contains=DictionaryPronounceNoHead
syntax match DictionaryNumber '^\d\+\($\|\s\)'
syntax region DictionaryPronounce start='^|' end='|\s*$'
      \ keepend containedin=DictionaryName oneline
syntax region DictionaryPronounce start='^/' end='/\s*$'
      \ keepend containedin=DictionaryName oneline
syntax match DictionaryPronounceNoHead '/.\{-}/'
      \ keepend containedin=DictionaryName contained oneline
syntax match DictionaryName '^\S\+\s*\n|.*|\s*$'
      \ contains=DictionaryPronounce
syntax match DictionaryName '^\S\+\s*\n/.*/\s*$'
      \ contains=DictionaryPronounce
syntax match DictionaryGroup '^[A-Z][a-z]\+ $'
syntax match DictionaryGrammer '^\(noun\|adjective\|verb\|adverb\)$'
      \ containedin=DictionaryName
syntax match DictionaryGrammer '^\(名詞\|形容詞\|[自他]\?動詞\|副詞\|U\|C\)$'
      \ containedin=DictionaryName
syntax match DictionaryName '^\S\+\s*\n^\(noun\|adjective\|verb\|adverb\)'
      \ contains=DictionaryGrammer
syntax match DictionaryName '^\(-\a\|～\|～́\|～̀\).*'
      \ contains=DictionaryGrammer,DictionaryPronounceNoHead,DictionarySemicolon,DictionaryComment 
syntax match DictionaryComment '^DERIVATIVES\|｟.\{-}｠\|〖.\{-}〗\|〘.\{-}〙'
syntax match DictionarySemicolon ';'

highlight default link DictionaryName Identifier
highlight default link DictionaryNumber Number
highlight default link DictionaryPronounce Comment
highlight default link DictionaryPronounceNoHead DictionaryPronounce
highlight default link DictionaryGroup String
highlight default link DictionaryGrammer Type
highlight default link DictionaryComment Comment
highlight default link DictionarySemicolon Normal

let b:current_syntax = 'dictionary'

