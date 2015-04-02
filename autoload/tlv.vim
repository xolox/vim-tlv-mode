" Vim auto-load script
" Language: TLV (Transaction-Level Verilog)
" Author: Peter Odding <peter@peterodding.com>
" Last Change: April 2, 2015
" URL: https://github.com/xolox/vim-tlv-mode

let g:tlv#version = '0.2.1'

function! tlv#compiler_is_installed() " {{{1
  " Check if the TLV compiler is installed. Returns true (1) when the compiler
  " is available in the $PATH, false (0) otherwise.
  return executable(g:tlv_compiler)
endfunction

function! tlv#check_syntax() " {{{1
  " Run the "sandpiper" compiler to validate the syntax of the TLV file that's
  " currently being edited.
  if !tlv#compiler_is_installed()
    let msg = "The configured TLV compiler (%s) is not available!"
    throw printf(msg, g:tlv_compiler)
  endif
  let efm_save = &errorformat
  let mp_save = &makeprg
  try
    let &makeprg = 'sandpiper'
    let &errorformat = "File '%f',%s(Line %l)"
    let &errorformat = "%m(Line %l)"
    echomsg printf("Checking syntax using %s compiler .. ", g:tlv_compiler)
    silent lmake! %
    " Avoid the hit-enter prompt (we don't want to break the user's flow).
    redraw
    if empty(getloclist(0))
      " Close the location list window when no output was generated.
      lclose
      " Clear the previously emitted "Checking syntax" message.
      echomsg ""
    else
      " Open the location list window when output was generated.
      lopen
      " Set the title of the location list window.
      let w:quickfix_title = printf("%s compiler output", g:tlv_compiler)
    endif
  finally
    let &errorformat = efm_save
    let &makeprg = mp_save
  endtry
endfunction

function! tlv#auto_check_syntax() " {{{1
  " Automatically check the syntax of TLV files when the compiler is installed
  " and the user hasn't disabled automatic syntax checking.
  if &filetype != 'tlv'
    " Never run the automatic syntax check for other file types.
    return
  elseif exists('g:tlv_auto_check_syntax') && !g:tlv_auto_check_syntax
    " The user has disabled automatic syntax checks, respect their choice.
    return
  elseif tlv#compiler_is_installed()
    " Only run the automatic syntax check when the compiler is installed
    " because there's no point in spamming the user with errors because the
    " compiler isn't installed - the syntax check is obviously never going to
    " work without the compiler installed! :-)
    call tlv#check_syntax()
  endif
endfunction

function! tlv#foldexpr() " {{{1
  " Support for automatic (smart) text folding. The result of this folding
  " expression isn't exactly ideal yet, but it's one step up from indentation
  " based text folding (that falls apart as soon as line type characters are
  " used :-). I'd like to improve this further, but I'm not yet sure how...
  return s:calculate_indent(getline(v:lnum)) / &tabstop
endfunction

function! tlv#indentexpr() " {{{1
  " Support for automatic (smart) indentation.
  let previous_lnum = prevnonblank(v:lnum - 1)
  let previous_line = getline(previous_lnum)
  let previous_indent = s:calculate_indent(previous_line)
  if previous_line =~ '^\s*[>|?@\\-]'
    " When the previous non blank line starts with one of the characters in
    " the [character class] above, the scope (and thus indentation) is
    " increased by one level.
    return previous_indent + &tabstop
  else
    " Otherwise we stick to the current indentation level.
    return previous_indent
  endif
endfunction

function! s:calculate_indent(line) " {{{1
  " Calculate the indentation level of a line (as the number of spaces). This
  " is complicated by line type characters (any character in the first column
  " other than a space or backslash) because they are to be considered
  " indentation so we have to include them (manually) in the calculation of
  " indentation. This explains why we can't use Vim's otherwise very handy
  " indent() function :-).
  if a:line =~ '^[^\\ ] '
    return matchend(a:line, '^[^\\] \+')
  else
    return matchend(a:line, '^ *')
  endif
endfunction

" vim: ts=2 sw=2 et
