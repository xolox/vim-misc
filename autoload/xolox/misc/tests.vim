" Tests for the miscellaneous Vim scripts.
"
" Author: Peter Odding <peter@peterodding.com>
" Last Change: June 22, 2013
" URL: http://peterodding.com/code/vim/misc/
"
" The Vim auto-load script `autoload/xolox/misc/tests.vim` contains the
" automated test suite of the miscellaneous Vim scripts. Right now the
" coverage is not very high yet, but this will improve over time.

function! xolox#misc#tests#run() " {{{1
  " Run the automated test suite of the miscellaneous Vim scripts. To be used
  " interactively. Intended to be safe to execute irrespective of context.
  call xolox#misc#test#reset()
  " Run the tests.
  call s:test_string_escaping()
  call s:test_list_handling()
  call s:test_option_handling()
  call s:test_command_execution()
  call s:test_version_handling()
  " Report a short summary to the user.
  call xolox#misc#test#summarize()
endfunction

" Tests for autoload/xolox/misc/escape.vim {{{1

function! s:test_string_escaping()
  call xolox#misc#test#wrap('xolox#misc#tests#pattern_escaping')
  call xolox#misc#test#wrap('xolox#misc#tests#substitute_escaping')
  call xolox#misc#test#wrap('xolox#misc#tests#shell_escaping')
endfunction

function! xolox#misc#tests#pattern_escaping() " {{{2
  " Test escaping of regular expression patterns with
  " `xolox#misc#escape#pattern()`.
  call xolox#misc#test#assert_equals('foo [qux] baz', substitute('foo [bar] baz', xolox#misc#escape#pattern('[bar]'), '[qux]', 'g'))
  call xolox#misc#test#assert_equals('also very nasty', substitute('also ~ nasty', xolox#misc#escape#pattern('~'), 'very', 'g'))
endfunction

function! xolox#misc#tests#substitute_escaping() " {{{2
  " Test escaping of substitution strings with
  " `xolox#misc#escape#substitute()`.
  call xolox#misc#test#assert_equals('nasty & tricky stuff', substitute('tricky stuff', 'tricky', xolox#misc#escape#substitute('nasty & tricky'), 'g'))
endfunction

function! xolox#misc#tests#shell_escaping() " {{{2
  " Test escaping of shell arguments with `xolox#misc#escape#shell()`.
  let expected_value = 'this < is > a | very " scary ^ string '' indeed'
  let result = xolox#misc#os#exec({'command': g:xolox#misc#test#echo . ' ' . xolox#misc#escape#shell(expected_value)})
  call xolox#misc#test#assert_equals(0, result['exit_code'])
  call xolox#misc#test#assert_equals([expected_value], result['stdout'])
endfunction

" Tests for autoload/xolox/misc/list.vim {{{1

function! s:test_list_handling()
  call xolox#misc#test#wrap('xolox#misc#tests#making_a_list_unique')
  call xolox#misc#test#wrap('xolox#misc#tests#binary_insertion')
endfunction

function! xolox#misc#tests#making_a_list_unique() " {{{2
  " Test removing of duplicate values from lists with
  " `xolox#misc#list#unique()`.
  call xolox#misc#test#assert_equals([1, 2, 3, 4, 5], xolox#misc#list#unique([1, 1, 2, 3, 3, 4, 5, 5]))
  " Should work for strings just as well. And it should preserve order.
  call xolox#misc#test#assert_equals(['a', 'b', 'c'], xolox#misc#list#unique(['a', 'a', 'b', 'b', 'c']))
  " Just to make sure that lists without duplicate values pass through unharmed.
  call xolox#misc#test#assert_equals([1, 2, 3, 4, 5], xolox#misc#list#unique([1, 2, 3, 4, 5]))
endfunction

function! xolox#misc#tests#binary_insertion() " {{{2
  " Test the binary insertion algorithm implemented in
  " `xolox#misc#list#binsert()`.
  let list = ['a', 'B', 'e']
  " Insert 'c' (should end up between 'B' and 'e').
  call xolox#misc#list#binsert(list, 'c', 1)
  call xolox#misc#test#assert_equals(['a', 'B', 'c', 'e'], list)
  " Insert 'D' (should end up between 'c' and 'e').
  call xolox#misc#list#binsert(list, 'D', 1)
  call xolox#misc#test#assert_equals(['a', 'B', 'c', 'D', 'e'], list)
  " Insert 'f' (should end up after 'e', at the end).
  call xolox#misc#list#binsert(list, 'f', 1)
  call xolox#misc#test#assert_equals(['a', 'B', 'c', 'D', 'e', 'f'], list)
endfunction

" Tests for autoload/xolox/misc/option.vim {{{1

function! s:test_option_handling()
  call xolox#misc#test#wrap('xolox#misc#tests#getting_configuration_options')
  call xolox#misc#test#wrap('xolox#misc#tests#splitting_of_multi_valued_options')
  call xolox#misc#test#wrap('xolox#misc#tests#joining_of_multi_valued_options')
  call xolox#misc#test#wrap('xolox#misc#tests#evaluation_of_tags_option')
endfunction

function! xolox#misc#tests#getting_configuration_options() " {{{2
  " Test getting of scoped plug-in configuration "options" with
  " `xolox#misc#option#get()`.
  let magic_name = 'a_variable_that_none_would_use'
  call xolox#misc#test#assert_equals(0, xolox#misc#option#get(magic_name))
  " Test custom default values.
  call xolox#misc#test#assert_equals([], xolox#misc#option#get(magic_name, []))
  " Set the option as a global variable.
  let global_value = 'global variable'
  let g:{magic_name} = global_value
  call xolox#misc#test#assert_equals(global_value, xolox#misc#option#get(magic_name))
  " Set the option as a buffer local variable, thereby shadowing the global.
  let local_value = 'buffer local variable'
  let b:{magic_name} = local_value
  call xolox#misc#test#assert_equals(local_value, xolox#misc#option#get(magic_name))
  " Sanity check that it's possible to unshadow as well.
  unlet b:{magic_name}
  call xolox#misc#test#assert_equals(global_value, xolox#misc#option#get(magic_name))
  " Cleanup after ourselves.
  unlet g:{magic_name}
  call xolox#misc#test#assert_equals(0, xolox#misc#option#get(magic_name))
endfunction

function! xolox#misc#tests#splitting_of_multi_valued_options() " {{{2
  " Test splitting of multi-valued Vim options with
  " `xolox#misc#option#split()`.
  call xolox#misc#test#assert_equals([], xolox#misc#option#split(''))
  call xolox#misc#test#assert_equals(['just one value'], xolox#misc#option#split('just one value'))
  call xolox#misc#test#assert_equals(['value 1', 'value 2'], xolox#misc#option#split('value 1,value 2'))
  call xolox#misc#test#assert_equals(['value 1', 'value 2', 'tricky,value'], xolox#misc#option#split('value 1,value 2,tricky\,value'))
endfunction

function! xolox#misc#tests#joining_of_multi_valued_options() " {{{2
  " Test joining of multi-valued Vim options with `xolox#misc#option#join()`.
  call xolox#misc#test#assert_equals('', xolox#misc#option#join([]))
  call xolox#misc#test#assert_equals('just one value', xolox#misc#option#join(['just one value']))
  call xolox#misc#test#assert_equals('value 1,value 2', xolox#misc#option#join(['value 1', 'value 2']))
  call xolox#misc#test#assert_equals('value 1,value 2,tricky\,value', xolox#misc#option#join(['value 1', 'value 2', 'tricky,value']))
endfunction

function! xolox#misc#tests#evaluation_of_tags_option() " {{{2
  " Test evaluation of Vim's ['tags'] [] option. We don't test `~/.tags` style
  " patterns because `xolox#misc#option#eval_tags()` doesn't support those.
  " Depending on your perspective this is not a bug, because the ['tags'] []
  " option gets special treatment in Vim anyway:
  "
  "   :set tags=~/.tags
  "     tags=~/.tags
  "   :echo &tags
  "     /home/peter/.tags
  "
  " So at the point where `xolox#misc#option#eval_tags()` receives the value
  " of ['tags'] [], it has already been expanded by Vim.
  "
  " ['tags']: http://vimdoc.sourceforge.net/htmldoc/options.html#'tags'
  let buffer_directory = fnamemodify(bufname('%'), ':p:h')
  call xolox#misc#test#assert_equals(
        \ [xolox#misc#path#merge(buffer_directory, '.tags')],
        \ xolox#misc#option#eval_tags('./.tags'))
  call xolox#misc#test#assert_equals(
        \ [xolox#misc#path#merge(buffer_directory, '.tags'),
        \  xolox#misc#path#merge(buffer_directory, '.more-tags')],
        \ xolox#misc#option#eval_tags('./.tags,./.more-tags'))
  call xolox#misc#test#assert_equals(
        \ [xolox#misc#path#merge(buffer_directory, '.tags')],
        \ xolox#misc#option#eval_tags('./.tags;'))
endfunction

" Tests for autoload/xolox/misc/os.vim {{{1

function! s:test_command_execution()
  call xolox#misc#test#wrap('xolox#misc#tests#finding_vim_on_the_search_path')
  call xolox#misc#test#wrap('xolox#misc#tests#synchronous_command_execution')
  call xolox#misc#test#wrap('xolox#misc#tests#synchronous_command_execution_with_raising_of_errors')
  call xolox#misc#test#wrap('xolox#misc#tests#synchronous_command_execution_without_raising_errors')
  call xolox#misc#test#wrap('xolox#misc#tests#asynchronous_command_execution')
endfunction

function! xolox#misc#tests#finding_vim_on_the_search_path() " {{{2
  " Test looking up Vim's executable on the search path using [v:progname] []
  " with `xolox#misc#os#find_vim()`.
  "
  " [v:progname]: http://vimdoc.sourceforge.net/htmldoc/eval.html#v:progname
  let pathname = xolox#misc#os#find_vim()
  call xolox#misc#test#assert_same_type('', pathname)
  call xolox#misc#test#assert_true(executable(pathname))
endfunction

function! xolox#misc#tests#synchronous_command_execution() " {{{2
  " Test basic functionality of synchronous command execution with
  " `xolox#misc#os#exec()`.
  let result = xolox#misc#os#exec({'command': printf('%s output && %s errors >&2', g:xolox#misc#test#echo, g:xolox#misc#test#echo)})
  call xolox#misc#test#assert_same_type({}, result)
  call xolox#misc#test#assert_equals(0, result['exit_code'])
  call xolox#misc#test#assert_equals(['output'], result['stdout'])
  call xolox#misc#test#assert_equals(['errors'], result['stderr'])
endfunction

function! xolox#misc#tests#synchronous_command_execution_with_raising_of_errors() " {{{2
  " Test raising of errors during synchronous command execution with
  " `xolox#misc#os#exec()`.
  try
    call xolox#misc#os#exec({'command': 'exit 1'})
    call xolox#misc#test#assert_true(0)
  catch
    call xolox#misc#test#assert_true(1)
  endtry
endfunction

function! xolox#misc#tests#synchronous_command_execution_without_raising_errors() " {{{2
  " Test synchronous command execution without raising of errors with
  " `xolox#misc#os#exec()`.
  try
    let result = xolox#misc#os#exec({'command': 'exit 42', 'check': 0})
    call xolox#misc#test#assert_true(1)
    call xolox#misc#test#assert_equals(42, result['exit_code'])
  catch
    call xolox#misc#test#assert_true(0)
  endtry
endfunction

function! xolox#misc#tests#asynchronous_command_execution() " {{{2
  " Test basic functionality of asynchronous command execution with
  " `xolox#misc#os#exec()`.
  let tempfile = tempname()
  let expected_value = string(localtime())
  let command = g:xolox#misc#test#echo . ' ' . xolox#misc#escape#shell(expected_value) . ' > ' . tempfile
  let result = xolox#misc#os#exec({'command': command, 'async': 1})
  call xolox#misc#test#assert_same_type({}, result)
  " Make sure the command is really executed.
  let timeout = localtime() + 30
  while !filereadable(tempfile) && localtime() < timeout
    sleep 500 m
  endwhile
  call xolox#misc#test#assert_true(filereadable(tempfile))
  call xolox#misc#test#assert_equals([expected_value], readfile(tempfile))
endfunction

" Tests for autoload/xolox/misc/version.vim {{{1

function! s:test_version_handling()
  call xolox#misc#test#wrap('xolox#misc#tests#version_string_parsing')
  call xolox#misc#test#wrap('xolox#misc#tests#version_string_comparison')
endfunction

function! xolox#misc#tests#version_string_parsing() " {{{2
  " Test parsing of version strings with `xolox#misc#version#parse()`.
  call xolox#misc#test#assert_equals([1], xolox#misc#version#parse('1'))
  call xolox#misc#test#assert_equals([1, 5], xolox#misc#version#parse('1.5'))
  call xolox#misc#test#assert_equals([1, 22, 3333, 44444, 55555], xolox#misc#version#parse('1.22.3333.44444.55555'))
  call xolox#misc#test#assert_equals([1, 5], xolox#misc#version#parse('1x.5y'))
endfunction

function! xolox#misc#tests#version_string_comparison() " {{{2
  " Test comparison of version strings with `xolox#misc#version#at_least()`.
  call xolox#misc#test#assert_true(xolox#misc#version#at_least('1', '1'))
  call xolox#misc#test#assert_true(!xolox#misc#version#at_least('1', '0'))
  call xolox#misc#test#assert_true(xolox#misc#version#at_least('1', '2'))
  call xolox#misc#test#assert_true(xolox#misc#version#at_least('1.2.3', '1.2.3'))
  call xolox#misc#test#assert_true(!xolox#misc#version#at_least('1.2.3', '1.2'))
  call xolox#misc#test#assert_true(xolox#misc#version#at_least('1.2.3', '1.2.4'))
endfunction
