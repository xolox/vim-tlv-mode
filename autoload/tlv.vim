" Vim auto-load script
" Language: TLV (Transaction-Level Verilog)
" Author: Peter Odding <peter@peterodding.com>
" Last Change: April 3, 2015
" URL: https://github.com/xolox/vim-tlv-mode

let g:tlv#version = '0.3'

" Public functions called by the other tlv.vim scripts. {{{1

function! tlv#check_syntax() " {{{2
  " Run the "sandpiper" compiler to validate the syntax of the TLV file that's
  " currently being edited. If the compiler emits messages they are rendered
  " in a location list window so the user can easily jump to the relevant
  " lines in the source file.
  if !tlv#compiler_is_installed()
    throw "The TLV compiler is not available!"
  endif
  echomsg "Checking TLV syntax .. "
  let output = tlv#parse_compiler_output(expand('%:p'))
  " Clear the previously emitted "Checking syntax" message.
  redraw
  if empty(output)
    " Close the location list window when no output was generated.
    lclose
  else
    " Convert the parsed compiler output to a location list.
    let loclist = tlv#generate_quick_fix_list(output)
    " Replace (r) the location list for the current window (0).
    call setloclist(0, loclist, 'r')
    " Open the location list window.
    lopen
    " Set the title of the location list window.
    let num_issues = len(loclist)
    let issues = (num_issues == 1 ? "issue" : "issues")
    let w:quickfix_title = printf("TLV compiler reported %i %s", num_issues, issues)
    " Clear the "Checking TLV syntax .." message.
    echo
  endif
endfunction

function! tlv#auto_check_syntax() " {{{2
  " Automatically check the syntax of TLV files when the compiler is installed
  " and the user hasn't disabled automatic syntax checking.
  if exists('g:tlv_auto_check_syntax') && !g:tlv_auto_check_syntax
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

function! tlv#foldexpr() " {{{2
  " Support for automatic (smart) text folding. The result of this folding
  " expression isn't exactly ideal yet, but it's one step up from indentation
  " based text folding (that falls apart as soon as line type characters are
  " used :-). I'd like to improve this further, but I'm not yet sure how...
  return tlv#calculate_indent(getline(v:lnum)) / &tabstop
endfunction

function! tlv#indentexpr() " {{{2
  " Support for automatic (smart) indentation.
  let previous_lnum = prevnonblank(v:lnum - 1)
  let previous_line = getline(previous_lnum)
  let previous_indent = tlv#calculate_indent(previous_line)
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

" Supporting functions (may be useful to others). {{{1

function! tlv#compiler_is_installed() " {{{2
  " Check if the TLV compiler is installed. Returns true (1)
  " when the compiler is installed, false (0) otherwise.
  return executable('sandpiper')
endfunction

function! tlv#find_compiler_path() " {{{2
  " Find the absolute pathname of the TLV compiler. Returns a string (empty if
  " the TLV compiler is not installed).
  if tlv#compiler_is_installed()
    let output = system('which sandpiper')
    " Strip the trailing line end from the output of `which'.
    let pathname = substitute(output, '\_s*$', '', '')
    " Make sure `which' produced a valid pathname.
    if filereadable(pathname)
      " If the executable on the search path is a symbolic link, resolve the
      " symbolic link to find where the sandpiper distribution is installed.
      return resolve(pathname)
    endif
  endif
  return ''
endfunction

function! tlv#compiler_command(pathname) " {{{2
  " Generate a command line that can be used to run the TLV compiler on the
  " TLV file whose pathname is given as the first and only argument. Returns a
  " string containing a shell command.
  let compiler_path = tlv#find_compiler_path()
  if !empty(compiler_path)
    let command_line = [compiler_path]
    " Determine the directory containing the sandpiper distribution. We need
    " this in order to compose a valid -m4inc command line argument.
    let bin_directory = fnamemodify(compiler_path, ':h')
    let dist_directory = fnamemodify(bin_directory, ':h')
    call extend(command_line, ['-m4inc', dist_directory . '/m4'])
    " Generate a temporary filename for the m4 output file (we don't actually
    " use this file but the TLV compiler requires this when the file header
    " indicates that the M4 preprocessor is to be used.
    let m4_output_file = tempname() . '.m4'
    call extend(command_line, ['-m4out', m4_output_file])
    " Add the pathname of the TLV file to check to the command line.
    call add(command_line, a:pathname)
    " Generate a temporary filename for the SystemVerilog output file (we
    " don't actually use this file but the TLV compiler requires this).
    let sv_output_file = tempname() . '.sv'
    call add(command_line, sv_output_file)
    " Convert the list of command line tokens into a single, properly quoted
    " command line string.
    return join(map(command_line, 'shellescape(v:val)'))
  endif
  return ''
endfunction

function! tlv#parse_compiler_output(filename) " {{{2
  " The "sandpiper" compiler emits multi line messages and so far I have been
  " unable to get Vim to properly interpret these messages. I probably just
  " don't have the required experience with Vim's obscure &errorformat
  " specifications (yet). For now I've decided that the most expedient way
  " to gain support for populating quick-fix windows with messages emitted by
  " the compiler is to parse the output in Vim script. That's what this
  " function does. Here is an example message:
  "
  "   WARNING(1) (UNUSED-SIG): File '/path/to/example.tlv' Line 47 (char 17), while parsing:
  "   	+----------------v--------------
  "   	>               $write = $opcode == 5'b11000;
  "   	+----------------^--------------
  "   	Signal |pipe4>inst$write is assigned but never used.
  "   	To silence this message use "`BOGUS_USE($write)
  "
  " Prepare a list to collect the extracted messages in.
  let messages = []
  " Start by running the sandpiper compiler on the current file.
  let output = system(tlv#compiler_command(a:filename))
  " Split the compiler output into blocks separated by an empty line.
  for block in split(output, '\n\n')
    " Split the block into lines.
    let lines = split(block, '\n')
    if !empty(lines)
      " Extract the relevant information from the first line.
      let severity = matchstr(lines[0], '^\C[A-Z_]\+\ze(')
      let filename = matchstr(lines[0], ': File ''\zs[^'']\+\ze''')
      let line_number = matchstr(lines[0], ' Line \zs\d\+\ze ')
      let column_number = matchstr(lines[0], '(char \zs\d\+\ze)')
      " At this point we're done with the first line.
      call remove(lines, 0)
      " Skip the decorative lines (we already have the information we need).
      while !empty(lines) && lines[0] =~ '^\s*[+|>]'
        call remove(lines, 0)
      endwhile
      " At this point we've arrived at the line(s) containing the message text...
      if !empty(lines)
        " Join the remaining lines into one string, split that string on any
        " whitespace and join the resulting tokens with single spaces. This
        " effectively collapses all lines into one and normalizes all
        " sequences of whitespace to single spaces.
        let message_text = join(split(join(lines)))
        if !empty(severity) && !empty(filename) && !empty(line_number) && !empty(column_number) && !empty(message_text)
          call add(messages, {
                \ 'severity': severity,
                \ 'filename': filename,
                \ 'line_number': line_number + 0,
                \ 'column_number': column_number + 0,
                \ 'message_text': message_text,
                \ })
        endif
      endif
    endif
  endfor
  return messages
endfunction

function! tlv#generate_quick_fix_list(parsed_messages) " {{{2
  " Convert the output of tlv#parse_compiler_output() to the input expected by
  " Vim's setqflist() and setloclist() functions.
  let entries = []
  for msg in a:parsed_messages
    " Convert the severity to a message type that Vim understands.
    if msg['severity'] =~? 'error'
      let type = 'E'
    elseif msg['severity'] =~? 'warn'
      let type = 'W'
    else
      let type = 'I'
    endif
    " Convert the parsed message into a dictionary with the keys expected by
    " Vim's setqflist() and setloclist() functions.
    call add(entries, {'filename': msg['filename'], 'lnum': msg['line_number'], 'col': msg['column_number'], 'type': type, 'text': msg['message_text']})
  endfor
  return entries
endfunction

function! tlv#calculate_indent(line) " {{{2
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
