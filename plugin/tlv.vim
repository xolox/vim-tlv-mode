" Vim plug-in
" Language: TLV (Transaction-Level Verilog)
" Author: Peter Odding <peter@peterodding.com>
" Last Change: March 13, 2015
" URL: https://github.com/xolox/vim-tlv-mode

" Don't source the plug-in when it's already been loaded or &compatible is set.
if &cp || exists('g:loaded_tlv_plugin')
  finish
endif

" The g:tlv_compiler option defines the name of the TLV compiler.
if !exists('g:tlv_compiler')
  let g:tlv_compiler = 'sandpiper'
endif

" The g:tlv_auto_check_syntax variable defines whether syntax
" checking is automatically performed when a TLV file is saved.
if !exists('g:tlv_auto_check_syntax')
  let g:tlv_auto_check_syntax = 0
endif

" Command to manually check for syntax errors.
command! -bar TlvCheckSyntax call tlv#check_syntax()

" Automatic command to check for syntax errors on save.
augroup PluginFileTypeTLV
  autocmd! BufWritePost * call tlv#auto_check_syntax()
augroup END

" Make sure the plug-in is only loaded once.
let g:loaded_tlv_plugin = 1

" vim: ts=2 sw=2 et
