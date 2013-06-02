" Tests for my miscellaneous Vim scripts.
"
" Author: Peter Odding <peter@peterodding.com>
" Last Change: June 2, 2013
" URL: http://peterodding.com/code/vim/misc/

" The process handling tests cannot use the built-in "echo" command from the
" Windows shell because it has way too much idiosyncrasies for me to put up
" with. Seriously. Instead I'm using an "echo.exe" from the UnxUtils project.
if xolox#misc#os#is_win()
  let s:echo = xolox#misc#escape#shell(xolox#misc#path#merge(expand('<sfile>:p:h'), 'echo.exe'))
else
  let s:echo = 'echo'
endif

" Tests for the miscellaneous scripts. {{{1

function! xolox#misc#tests#run_all() " {{{2
  " Run the automated tests of the miscellaneous functions.
  let starttime = xolox#misc#timer#start()
  " Start from a clean slate.
  call s:test_reset()
  " Run the tests.
  call s:test_string_escaping()
  call s:test_command_execution()
  call s:test_list_handling()
  call s:test_option_handling()
  " Report a short summary to the user.
  call xolox#misc#timer#force("Took %s to run %i tests: %i passed, %i failed.", starttime, s:num_passed + s:num_failed, s:num_passed, s:num_failed)
endfunction

" Tests for autoload/xolox/misc/escape.vim {{{2

function! s:test_string_escaping()
  call s:test_wrap('s:test_pattern_escaping')
  call s:test_wrap('s:test_substitute_escaping')
  call s:test_wrap('s:test_shell_escaping')
endfunction

function! s:test_pattern_escaping() " {{{3
  " Test escaping of regular expression patterns.
  call s:assert_equals('foo [qux] baz', substitute('foo [bar] baz', xolox#misc#escape#pattern('[bar]'), '[qux]', 'g'))
  call s:assert_equals('also very nasty', substitute('also ~ nasty', xolox#misc#escape#pattern('~'), 'very', 'g'))
endfunction

function! s:test_substitute_escaping() " {{{3
  " Test escaping of substitution strings.
  call s:assert_equals('nasty & tricky stuff', substitute('tricky stuff', 'tricky', xolox#misc#escape#substitute('nasty & tricky'), 'g'))
endfunction

function! s:test_shell_escaping() " {{{3
  " Test escaping of shell arguments.
  let expected_value = 'this < is > a | very " scary ^ string '' indeed'
  let result = xolox#misc#os#exec({'command': s:echo . ' ' . xolox#misc#escape#shell(expected_value)})
  call s:assert_equals(0, result['exit_code'])
  call s:assert_equals([expected_value], result['stdout'])
endfunction

" Tests for autoload/xolox/misc/os.vim {{{2

function! s:test_command_execution()
  call s:test_wrap('s:test_exec_synchronous')
  call s:test_wrap('s:test_exec_synchronous_error_with_raise')
  call s:test_wrap('s:test_exec_synchronous_error_without_raise')
  call s:test_wrap('s:test_exec_asynchronous')
endfunction

function! s:test_exec_synchronous() " {{{3
  " Test basic functionality of synchronous command execution.
  let result = xolox#misc#os#exec({'command': printf('%s output && %s errors >&2', s:echo, s:echo)})
  call s:assert_type({}, result)
  call s:assert_equals(0, result['exit_code'])
  call s:assert_equals(['output'], result['stdout'])
  call s:assert_equals(['errors'], result['stderr'])
endfunction

function! s:test_exec_synchronous_error_with_raise() " {{{3
  " Test raising of errors during synchronous command execution.
  try
    call xolox#misc#os#exec({'command': 'exit 1'})
    call s:assert_true(0)
  catch
    call s:assert_true(1)
  endtry
endfunction

function! s:test_exec_synchronous_error_without_raise() " {{{3
  " Test synchronous command execution without raising of errors.
  try
    let result = xolox#misc#os#exec({'command': 'exit 42', 'check': 0})
    call s:assert_true(1)
    call s:assert_equals(42, result['exit_code'])
  catch
    call s:assert_true(0)
  endtry
endfunction

function! s:test_exec_asynchronous() " {{{3
  " Test basic functionality of asynchronous command execution.
  let tempfile = tempname()
  let expected_value = string(localtime())
  let command = s:echo . ' ' . xolox#misc#escape#shell(expected_value) . ' > ' . tempfile
  let result = xolox#misc#os#exec({'command': command, 'async': 1})
  call s:assert_type({}, result)
  " Make sure the command is really executed.
  let timeout = localtime() + 30
  while !filereadable(tempfile) && localtime() < timeout
    sleep 500 m
  endwhile
  call s:assert_true(filereadable(tempfile))
  call s:assert_equals([expected_value], readfile(tempfile))
endfunction

" Tests for autoload/xolox/misc/list.vim {{{2

function! s:test_list_handling()
  call s:test_wrap('s:test_list_unique')
  call s:test_wrap('s:test_list_binsert')
endfunction

function! s:test_list_unique() " {{{3
  " Test removing of duplicate values from lists.
  call s:assert_equals([1, 2, 3, 4, 5], xolox#misc#list#unique([1, 1, 2, 3, 3, 4, 5, 5]))
  " Should work for strings just as well. And it should preserve order.
  call s:assert_equals(['a', 'b', 'c'], xolox#misc#list#unique(['a', 'a', 'b', 'b', 'c']))
  " Just to make sure that lists without duplicate values pass through unharmed.
  call s:assert_equals([1, 2, 3, 4, 5], xolox#misc#list#unique([1, 2, 3, 4, 5]))
endfunction

function! s:test_list_binsert() " {{{3
  " Test binary insertion algorithm.
  let list = ['a', 'B', 'e']
  " Insert 'c' (should end up between 'B' and 'e').
  call xolox#misc#list#binsert(list, 'c', 1)
  call s:assert_equals(['a', 'B', 'c', 'e'], list)
  " Insert 'D' (should end up between 'c' and 'e').
  call xolox#misc#list#binsert(list, 'D', 1)
  call s:assert_equals(['a', 'B', 'c', 'D', 'e'], list)
  " Insert 'f' (should end up after 'e', at the end).
  call xolox#misc#list#binsert(list, 'f', 1)
  call s:assert_equals(['a', 'B', 'c', 'D', 'e', 'f'], list)
endfunction

" Tests for autoload/xolox/misc/option.vim {{{2

function! s:test_option_handling()
  call s:test_wrap('s:test_option_get')
  call s:test_wrap('s:test_option_split')
  call s:test_wrap('s:test_option_join')
  call s:test_wrap('s:test_option_eval_tags')
endfunction

function! s:test_option_get() " {{{3
  " Test getting of scoped options.
  let magic_name = 'a_variable_that_none_would_use'
  call s:assert_equals(0, xolox#misc#option#get(magic_name))
  " Test custom default values.
  call s:assert_equals([], xolox#misc#option#get(magic_name, []))
  " Set the option as a global variable.
  let global_value = 'global variable'
  let g:{magic_name} = global_value
  call s:assert_equals(global_value, xolox#misc#option#get(magic_name))
  " Set the option as a buffer local variable, thereby shadowing the global.
  let local_value = 'buffer local variable'
  let b:{magic_name} = local_value
  call s:assert_equals(local_value, xolox#misc#option#get(magic_name))
  " Sanity check that it's possible to unshadow as well.
  unlet b:{magic_name}
  call s:assert_equals(global_value, xolox#misc#option#get(magic_name))
  " Cleanup after ourselves.
  unlet g:{magic_name}
  call s:assert_equals(0, xolox#misc#option#get(magic_name))
endfunction

function! s:test_option_split() " {{{3
  " Tests splitting of multi-valued Vim options.
  call s:assert_equals([], xolox#misc#option#split(''))
  call s:assert_equals(['just one value'], xolox#misc#option#split('just one value'))
  call s:assert_equals(['value 1', 'value 2'], xolox#misc#option#split('value 1,value 2'))
  call s:assert_equals(['value 1', 'value 2', 'tricky,value'], xolox#misc#option#split('value 1,value 2,tricky\,value'))
endfunction

function! s:test_option_join() " {{{3
  " Tests joining of multi-valued Vim options.
  call s:assert_equals('', xolox#misc#option#join([]))
  call s:assert_equals('just one value', xolox#misc#option#join(['just one value']))
  call s:assert_equals('value 1,value 2', xolox#misc#option#join(['value 1', 'value 2']))
  call s:assert_equals('value 1,value 2,tricky\,value', xolox#misc#option#join(['value 1', 'value 2', 'tricky,value']))
endfunction

function! s:test_option_eval_tags() " {{{3
  " Tests evaluation of Vim's &tags option. We don't test ~/.tags style
  " patterns because xolox#misc#option#eval_tags() doesn't support those.
  " Depending on your perspective this is not a bug, because &tags gets
  " special treatment in Vim anyway:
  "
  "   :set tags=~/.tags
  "     tags=~/.tags
  "   :echo &tags
  "     /home/peter/.tags
  "
  " So at the point where xolox#misc#option#eval_tags() receives the value of
  " &tags, it has already been expanded by Vim.
  call s:assert_equals([fnamemodify('.tags', ':p')], xolox#misc#option#eval_tags('./.tags'))
  call s:assert_equals([fnamemodify('.tags', ':p'), fnamemodify('.more-tags', ':p')], xolox#misc#option#eval_tags('.tags,.more-tags'))
endfunction

" Testing infrastructure. {{{1

function! s:test_reset() " {{{2
  " Reset counters for passed/failed tests.
  let s:num_passed = 0
  let s:num_failed = 0
endfunction

function! s:test_wrap(function) " {{{2
  " Call a function in a try/catch block and prevent exceptions from bubbling.
  let num_failed = s:num_failed
  try
    call xolox#misc#msg#info("Running test: %s", a:function)
    call call(a:function, [])
  catch
    call xolox#misc#msg#warn("Test %s raised exception:", a:function)
    call xolox#misc#msg#warn("%s", v:exception)
    call xolox#misc#msg#warn("(at %s)", v:throwpoint)
    if num_failed == s:num_failed
      " Make sure exceptions are counted as failures, but don't inflate the
      " number of failed assertions when it's not needed (it can produce
      " confusing test output).
      call s:test_failed()
    endif
  endtry
endfunction

function! s:test_feedback() " {{{2
  " Let the user know the status of the test suite.
  call xolox#misc#msg#info("Test status: %i passed, %i failed assertions ..", s:num_passed, s:num_failed)
endfunction

function! s:test_passed() " {{{2
  " Record a test which succeeded.
  let s:num_passed += 1
  call s:test_feedback()
endfunction

function! s:test_failed() " {{{2
  " Record a test which failed.
  let s:num_failed += 1
  call s:test_feedback()
endfunction

function! s:assert_true(expr) " {{{2
  " Check whether an expression is true.
  if a:expr
    call s:test_passed()
    return 1
  else
    call s:test_failed()
    let msg = "Expected value to be true, got %s instead"
    throw printf(msg, string(a:expr))
  endif
endfunction

function! s:assert_equals(expected, received) " {{{2
  " Check whether two values are the same.
  if s:assert_type(a:expected, a:received) && a:expected == a:received
    call s:test_passed()
    return 1
  else
    call s:test_failed()
    let msg = "Expected value %s, received value %s!"
    throw printf(msg, string(a:expected), string(a:received))
  endif
endfunction

function! s:assert_type(expected, received) " {{{2
  " Check whether two values are of the same type.
  if type(a:expected) == type(a:received)
    call s:test_passed()
    return 1
  else
    call s:test_failed()
    let msg = "Expected value of same type as %s, got value %s!"
    throw printf(msg, string(a:expected), string(a:received))
  endif
endfunction
