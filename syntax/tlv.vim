" Vim syntax script
" Language: TLV (Transaction-Level Verilog)
" Author: Peter Odding <peter@peterodding.com>
" Last Change: March 13, 2015
" URL: https://github.com/xolox/vim-tlv-mode
"
" Notes about this syntax mode: {{{1
"
" Region types: {{{2
"
" TLV files have three types of code blocks (regions) with special markers in
" the first column to mark the start of each region:
"
" - \SV marks System Verilog regions
" - \TLV marks Transaction-Level Verilog regions
" - \SV_plus marks System Verilog regions with embedded TLV signal references
"
" The default region is \SV although the TLV compiler prefers an explicit
" region marker on the second line of TLV files.
"
" Highlight group links: {{{2
"
" In the development of this syntax mode and the 'tlv' color scheme I have
" several goals that I find hard to align with each other:
"
" 1. The TLV syntax mode has a lot of syntax items with distinct purposes that
"    should have distinct styling.
"
" 2. I want the syntax mode to work well with a variety of popular color
"    schemes (some distributed with Vim, others distributed separately).
"
" The trick here is to pick generic highlighting groups that already have
" distinct highlighting in popular color schemes. However there really aren't
" a lot of those. I've resorted to reading through some popular color schemes
" to find the "common subset" of generic highlighting groups that seem safe to
" use.
"
" This explains why some of the highlight group links defined in this syntax
" script don't make any sense semantically: My only real goal is to use
" generic yet distinctly highlighted groups for the distinct syntax items.
"
" }}}1

" Allow overriding/disabling of this syntax script.
if exists('b:current_syntax')
  finish
endif

" As documented above the default region type is SV code so to begin with we
" load the System Verilog syntax script here (as our top level syntax mode).
runtime! syntax/systemverilog.vim

" Also load any customizations defined by the user.
runtime! after/syntax/systemverilog.vim

" The "verilogOperator" group is linked to "Special" by the syntax script
" "syntax/systemverilog.vim" but that causes operators in \SV code blocks to
" be highlighted differently from operators in \TLV code blocks which gives a
" kind of confused appearance, so we (ab)use the power of highlight group
" linking to "correct" this.
highlight link verilogOperator Operator

" The TLV processing chain runs M4 as an independent preprocessor before any
" other processing takes place so M4 macros can be used anywhere (although
" they are intended to provide functionality for \TLV and \SV_plus regions).
" To keep things simple we will highlight M4 macros anywhere.
let g:main_syntax = 'tlv'
runtime! syntax/m4.vim
runtime! after/syntax/m4.vim

" The first line of a TLV file indicates the file type, we'll highlight this
" similarly to UNIX shebang lines in other Vim syntax modes.
syntax match tlvFileTypeIndicator /\%^\\\(m4_\)\?TLV_version.*/
highlight def link tlvFileTypeIndicator Special

" Load the M4 syntax items into a group that we can embed into a syntax region
" that we will define a bit further down.
try
  syntax include @M4 syntax/m4.vim
  " If the user defined customizations to the syntax highlighting we will
  " load those customizations into the same syntax group as well.
  syntax include @M4 after/syntax/m4.vim
catch /E484/
  " Ignore missing /after/ scripts (they should be optional after all :-).
endtry

" Define the syntax group that contains TLV code.
syntax region tlvTlvRegion matchgroup=tlvTlvMarker start=/^\\TLV$/ end=/^\\/me=s-1 keepend contains=@M4
highlight def link tlvTlvMarker Special

" Define the syntax group that contains literal SystemVerilog code with TLV signal references.
syntax region tlvSvPlusRegion matchgroup=tlvSvPlusMarker start=/^\\SV_plus$/ end=/^\\/me=s-1 keepend contains=@M4
highlight def link tlvSvPlusMarker Special

" The \SV marker at the start of a line terminates the preceding \TLV or
" \SV_plus code block. We want this to be highlighted the same as the \TLV and
" \SV_plus markers.
syntax match tlvSvMarker /^\\SV$/
highlight def link tlvSvMarker Special

" Tabs in \TLV and \SV_plus code blocks are highlighted as errors (because they are :-).
syntax match tlvTabsForbidden /\t/ contained containedin=tlvTlvRegion,tlvSvPlusRegion
highlight def link tlvTabsForbidden ErrorMsg

" Comments in \TLV code blocks.
syntax match tlvComment @//.*@ contained containedin=tlvTlvRegion
highlight def link tlvComment Comment

" M4 macros with a custom syntax (?).
syntax match tlvCustomM4MacroSyntax /\<[mM]4+\?\w\+/ contained containedin=tlvTlvRegion
highlight def link tlvCustomM4MacroSyntax PreProc

" "Line type characters" in \TLV and \SV_plus code blocks. Note that this
" directive needs to come after "tlvOperator" to override "tlvOperator".
syntax match tlvLineTypeCharacter /^[^ \\]/ contained containedin=tlvTlvRegion,tlvSvPlusRegion
highlight def link tlvLineTypeCharacter WarningMsg

" "Behavioral hierarchy" lines in \TLV code blocks.
syntax match tlvBehavioralHierarchy />[A-Za-z0-9_]\+/ contained containedin=tlvTlvRegion
highlight def link tlvBehavioralHierarchy Statement

" "Pipelines" in \TLV code blocks.
syntax match tlvPipeline /|[A-Za-z0-9_]\+/ contained containedin=tlvTlvRegion
highlight def link tlvPipeline Repeat

" "Stage" markers in \TLV code blocks.
syntax match tlvStage /\(^\s\+\)\@<=@-\?\d\+/ contained containedin=tlvTlvRegion
highlight def link tlvStage Conditional

" "Alignment" markers in \TLV code blocks.
syntax match tlvAlignment /#[+-]\d\+/ contained containedin=tlvTlvRegion
highlight def link tlvAlignment Number

" "Pipe signals" in \TLV code blocks.
syntax match tlvPipeSignal /$[A-Za-z_][A-Za-z_0-9]*/ contained containedin=tlvTlvRegion
highlight def link tlvPipeSignal Identifier

" SV signals or types in \TLV code blocks.
syntax match tlvSignalOrType /*[A-Za-z_][A-Za-z_0-9]*/ contained containedin=tlvTlvRegion,tlvSvPlusRegion
highlight def link tlvSignalOrType Type

" Vim syntax scripts are expected to set this variable once they're loaded.
let b:current_syntax = 'tlv'

" vim: ts=2 sw=2 et
