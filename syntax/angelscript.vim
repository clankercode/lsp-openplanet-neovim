" SPDX-License-Identifier: Unlicense OR CC0-1.0
if exists("b:current_syntax")
  finish
endif
" AngelScript shares C comments, strings, numbers and control flow.
runtime! syntax/c.vim
unlet! b:current_syntax
syn keyword angelscriptType bool int int8 int16 int32 int64 uint uint8 uint16 uint32 uint64 float double string auto void
syn keyword angelscriptStructure class interface enum namespace mixin funcdef typedef
syn keyword angelscriptStorage const private protected shared external final abstract override property
syn keyword angelscriptStatement cast is in out inout super this null true false
syn match angelscriptHandle "@"
syn match angelscriptPreProc "^\s*#.*$"
hi def link angelscriptType Type
hi def link angelscriptStructure Structure
hi def link angelscriptStorage StorageClass
hi def link angelscriptStatement Statement
hi def link angelscriptHandle Operator
hi def link angelscriptPreProc PreProc
let b:current_syntax = "angelscript"
