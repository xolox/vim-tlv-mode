" Vim file type detection script
" Language: TLV (Transaction-Level Verilog)
" Author: Peter Odding <peter@peterodding.com>
" Last Change: March 8, 2015
" URL: https://github.com/xolox/vim-tlv-mode

" Detection based on filename extensions.
autocmd BufNewFile,BufRead *.tlv set filetype=tlv

" Detection based on file contents (the first line).
autocmd BufNewFile,BufRead * call s:DetectTLV()

function! s:DetectTLV()
  if getline(1) =~ '^\\\(m4_\)\?TLV_version \d'
    set filetype=tlv
  endif
endfunction

" vim: ts=2 sw=2 et
