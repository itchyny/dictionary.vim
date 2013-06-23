" =============================================================================
" Filename: syntax/dictionary.vim
" Version: 0.0
" Author: itchyny
" License: MIT License
" Last Change: 2013/06/23 18:44:23.
" =============================================================================

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

syntax region DictionaryName start='\%2l' end='$'
      \ keepend contains=DictionaryPronounceNoHead
syntax region Dictionary start='\%3l' end='\%999l' keepend
syntax match DictionaryNumber '^\d\+\($\|\s\)'
      \ containedin=Dictionary contained
syntax region DictionaryPronounce start='^|' end='|\s*$'
      \ keepend containedin=Dictionary,DictionaryName contained oneline
syntax region DictionaryPronounce start='^/' end='/\s*$'
      \ keepend containedin=Dictionary,DictionaryName contained oneline
syntax match DictionaryPronounceNoHead '/.\{-}/'
      \ keepend containedin=Dictionary,DictionaryName contained oneline
syntax match DictionaryName '^\S\+\s*\n|.*|\s*$'
      \ containedin=Dictionary contained contains=DictionaryPronounce
syntax match DictionaryName '^\S\+\s*\n/.*/\s*$'
      \ containedin=Dictionary contained contains=DictionaryPronounce
syntax match DictionaryGroup '^[A-Z][a-z]\+ $'
      \ containedin=Dictionary contained
syntax match DictionaryGrammer '^\(noun\|adjective\|verb\|adverb\)'
      \ containedin=Dictionary,DictionaryName contained
syntax match DictionaryGrammer '^\(名詞\|形容詞\|[自他]\?動詞\|副詞\)'
      \ containedin=Dictionary,DictionaryName contained
syntax match DictionaryName '^\S\+\s*\n^\(noun\|adjective\|verb\|adverb\)'
      \ containedin=Dictionary contained contains=DictionaryGrammer
syntax match DictionaryName '^\(～\|～́\|～̀\).*'
      \ containedin=Dictionary contained
      \ contains=DictionaryGrammer,DictionaryPronounceNoHead,DictionarySemicolon,DictionaryComment 
syntax match DictionaryComment '^DERIVATIVES\|｟.\{-}｠\|〖.\{-}〗\|〘.\{-}〙'
      \ containedin=Dictionary contained
syntax match DictionarySemicolon ';'
      \ containedin=Dictionary contained

highlight default link DictionaryName Identifier
highlight default link DictionaryNumber Number
highlight default link DictionaryPronounce Comment
highlight default link DictionaryPronounceNoHead DictionaryPronounce
highlight default link DictionaryGroup String
highlight default link DictionaryGrammer Type
highlight default link DictionaryComment Comment
highlight default link DictionarySemicolon Normal

let b:current_syntax = 'dictionary'

