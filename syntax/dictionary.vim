" =============================================================================
" Filename: syntax/dictionary.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 07:23:38.
" =============================================================================

scriptencoding utf-8

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

syntax region DictionaryName start='\%2l' end='$'
      \ keepend contains=DictionaryPronounceNoHead
syntax match DictionaryNumber '^\d\+\($\|\s\)'
syntax region DictionaryPronounce start='^|' end='|\s*$'
      \ keepend containedin=DictionaryName oneline
syntax region DictionaryPronounce start='^/' end='/;\?\s*$'
      \ keepend containedin=DictionaryName oneline
syntax match DictionaryPronounceNoHead '/.\{-}/;\?'
      \ keepend containedin=DictionaryName,DictionaryGrammerLine contained oneline
syntax match DictionaryName '^\S\+\s*\n|.*|\s*$'
      \ contains=DictionaryPronounce
syntax match DictionaryName '^\S\+\s*\n/.*/;\?'
      \ contains=DictionaryPronounceNoHead
syntax match DictionaryGroup '\(^\(\d\+\| *•\) \)\@<=[A-Z][a-z]\+ \(& [A-Z][a-z]\+\)*'
syntax match DictionaryGrammer '^\(\(pro\)\?noun\|adjective\|det\|verb\|adverb\|abbreviation\|preposition\|suffix\|prefix\|conjunction\|symb\)$'
      \ containedin=DictionaryName
syntax match DictionaryGrammerNoHead '\<\(\(pro\)\?noun\|adjective\|det\|verb\|adverb\|abbreviation\|preposition\|suffix\|prefix\|conjunction\|symb\)\>'
      \ containedin=DictionaryGrammerLine contained
syntax match DictionaryGrammerLine '^\(\(pro\)\?noun\|adjective\|det\|verb\|adverb\|abbreviation\|preposition\|suffix\|prefix\|conjunction\|symb\)\>.*$\|\(^\(\d\+\| *[a-z]\.\) \)\@<=[A-Z]\+\>'
      \ containedin=DictionaryName
syntax match DictionaryGrammer '^\(nombre\|adjetivo\|adverbio\|adeverbio\|pronombre\|verbo\).*$'
      \ containedin=DictionaryName
syntax match DictionaryGrammer '^\(Substantiv\|Adjektiv\|Adverb\|Suffix\|Präposition\|Zahlwort\|Interjektion\|Präfix\|Pronomen\|Artikel\|Abkürzung\|\S\+ Verb\|Konjunktion\|Eigenname\)\>.*$'
      \ containedin=DictionaryName
syntax match DictionaryGrammerNoHead '\(代\?名　\?詞\|形容詞\|[自他助]\?動　\?詞\|副　\?詞\|前置詞\|接[尾頭]辞\|間投詞\|冠　\?詞\|接続詞\|\<[UC]\+\>\)'
      \ containedin=DictionaryGrammerLine contained
syntax match DictionaryGrammer '^\(代\?名　\?詞\|形容詞\|[自他助]\?動　\?詞\|副　\?詞\|前置詞\|接[尾頭]辞\|間投詞\|冠　\?詞\|接続詞\)'
      \ containedin=DictionaryName
syntax match DictionaryGrammer '^\(名\(　\?詞\)\?\|形\(容詞\)\?\|[自他助]\?動　\?詞\|副\(　\?詞\)\?\|前\(置詞\)\?\|代\(名詞\)\?\|接[尾頭]辞\|間\(投詞\)\?\|冠\(　\?詞\)\?\|接\(続詞\)\?\|\<[UC]\+\>\)$'
      \ containedin=DictionaryName
syntax match DictionaryGrammerLine '^\(代\?名　\?詞\|形容詞\|[自他助]\?動　\?詞\|副　\?詞\|前置詞\|接[尾頭]辞\|間投詞\|冠　\?詞\|接続詞\|U \|C \).*'
      \ containedin=DictionaryName
syntax match DictionaryGrammer '^\(动\|介\|量\|数\|连\)$'
      \ containedin=DictionaryName
syntax match DictionaryName '^\S\+\s*\n^\(\(pro\)\?noun\|adjective\|det\|verb\|adverb\|abbreviation\|preposition\|suffix\|prefix\|conjunction\|symb\)\>'
      \ contains=DictionaryGrammer
syntax match DictionaryName '^\(-\a\|～\|～́\|～̀\|複\).*\|^\a\+\s/\S\+/.*$'
      \ contains=DictionaryGrammer,DictionaryPronounceNoHead,DictionarySemicolon,DictionaryComment
syntax match DictionaryComment '^\(DERIVATIVES\|ORIGIN\|PHRASES\)\|｟.\{-}｠\|〖.\{-}〗\|〘.\{-}〙'
syntax match DictionarySemicolon ';'

highlight default link DictionaryName Identifier
highlight default link DictionaryNumber Number
highlight default link DictionaryPronounce Comment
highlight default link DictionaryPronounceNoHead DictionaryPronounce
highlight default link DictionaryGroup String
highlight default link DictionaryGrammer Type
highlight default link DictionaryGrammerNoHead DictionaryGrammer
highlight default link DictionaryComment Comment
highlight default link DictionarySemicolon Normal

let b:current_syntax = 'dictionary'

let &cpo = s:save_cpo
unlet s:save_cpo
