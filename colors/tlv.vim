" Vim color scheme
" Author: Peter Odding <peter@peterodding.com>
" Last Change: March 13, 2015
" URL: https://github.com/xolox/vim-tlv-mode
"
" This color scheme is bundled with the vim-tlv-mode plug-in and implements
" the recommended color scheme for TLV syntax highlighting. It was
" specifically designed to be used for editing TLV code and is not really
" intended as a general purpose color scheme, for example it doesn't define
" styles for all of Vim's generic syntax highlighting groups.

highlight clear

" Regular text.
highlight Normal guifg=#000000 guibg=#FFFFFF

" Selected text.
highlight Visual guibg=#DDDDDD

" Text folding.
highlight Folded guifg=#AAAAAA guibg=#DDDDDD
highlight FoldColumn guifg=#555555 guibg=#DDDDDD

" Cursor line/column highlighting.
highlight CursorLine guibg=#EEEEEE
highlight CursorColumn guibg=#EEEEEE

" Used by e.g. the NERDTree plug-in.
highlight Directory guifg=#444444

" Starting from "highlight clear" the "Operator" group is already highlighted
" however the recommended color scheme for TLV code does not highlight
" operators so we reset the styling.
highlight Operator guifg=#000000 guibg=#FFFFFF

" Source code comments.
highlight Comment guifg=#C00000

" Code block markers (\SV, \TLV, \SV_plus).
highlight Special guifg=#0A00C8

" Tabs in \TLV and \SV_plus code blocks.
highlight ErrorMsg guifg=#FFFFFF guibg=#FF0000

" Line type markers in \TLV blocks.
highlight WarningMsg gui=bold guifg=#FF0000

" M4 macros.
highlight PreProc gui=bold guifg=#000000

" "Behavioral hierarchy" lines in \TLV blocks
" (tlvBehavioralHierarchy is linked to Statement).
highlight Statement gui=NONE guifg=#20A0C0

" "Pipelines" in \TLV blocks
" (tlvPipeline is linked to Repeat).
highlight Repeat guifg=#FFC000

" "Stage" markers in \TLV blocks
" (tlvStage is linked to Conditional).
highlight Conditional gui=italic guifg=#4d8600

" "Alignment" markers in \TLV blocks
" (tlvAlignment is linked to Number).
highlight Number guifg=#00d05e

" "Pipe signals" in \TLV code blocks
" (tlvPipeSignal is linked to Identifier).
highlight Identifier guifg=#7030A0

" SV signals or types in \TLV code blocks
" (tlvSignalOrType is linked to Type).
highlight Type gui=NONE guifg=#595959

" Make the :colorscheme command (without any arguments) print the name of our
" color scheme instead of a previously loaded color scheme.
let g:colors_name = 'tlv'
