" Manipulation of UNIX file permissions.
"
" Author: Peter Odding <peter@peterodding.com>
" Last Change: June 29, 2014
" URL: http://peterodding.com/code/vim/misc/
"
" Vim's [writefile()][] function cannot set file permissions for newly created
" files and although Vim script has a function to get file permissions (see
" [getfperm()][]) there is no equivalent for changing a file's permissions.
"
" This omission breaks the otherwise very useful idiom of updating a file by
" writing its new contents to a temporary file and then renaming the temporary
" file into place (which is as close as you're going to get to atomically
" updating a file's contents on UNIX) because the file's permissions will not
" be preserved!
"
" **Here's a practical example:** My [vim-easytags][] plug-in writes tags file
" updates to a temporary file and renames the temporary file into place. When
" I use `sudo -s` on Ubuntu Linux it preserves my environment variables so my
" `~/.vimrc` and the [vim-easytags][] plug-in are still loaded. Now when a
" tags file is written the file becomes owned by root (my effective user id in
" the `sudo` session). Once I leave the `sudo` session I can no longer update
" my tags file because it's now owned by root … ಠ_ಠ
"
" [getfperm()]: http://vimdoc.sourceforge.net/htmldoc/eval.html#getfperm()
" [vim-easytags]: http://peterodding.com/code/vim/easytags/
" [writefile()]: http://vimdoc.sourceforge.net/htmldoc/eval.html#writefile()

function! xolox#misc#perm#get(fname)
  " Get the permissions of the pathname given as the first argument. Returns a
  " string which you can later pass to `xolox#misc#perm#set()`.
  let pathname = xolox#misc#path#absolute(a:fname)
  if filereadable(pathname)
    let command = printf('stat --format %%a %s', shellescape(pathname))
    let result = xolox#misc#os#exec({'command': command})
    if result['exit_code'] == 0 && len(result['stdout']) >= 1
      let permissions_string = '0' . xolox#misc#str#trim(result['stdout'][0])
      if permissions_string =~ '^[0-7]\+$'
        call xolox#misc#msg#debug("vim-misc %s: Found permissions of %s: %s.", g:xolox#misc#version, pathname, permissions_string)
        return permissions_string
      endif
    endif
  endif
  return ''
endfunction

function! xolox#misc#perm#set(fname, perms)
  " Set the permissions (the second argument) of the pathname given as the
  " first argument. Expects a permissions string created by
  " `xolox#misc#perm#get()`.
  if !empty(a:perms)
    let pathname = xolox#misc#path#absolute(a:fname)
    let command = printf('chmod %s %s', shellescape(a:perms), shellescape(pathname))
    let result = xolox#misc#os#exec({'command': command})
    if result['exit_code'] == 0
      call xolox#misc#msg#debug("vim-misc %s: Successfully set permissions of %s to %s.", g:xolox#misc#version, pathname, a:perms)
      return 1
    endif
  endif
  return 0
endfunction
