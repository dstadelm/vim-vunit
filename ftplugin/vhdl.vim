if exists("b:did_vunit_plugin")
  finish
endif
let b:did_vunit_plugin = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" commands to simplify mappings
command! VunitRunTestWithFzf call VunitRunTestWithFzf(0)
command! VunitRunTestWithFzfInGui call VunitRunTestWithFzf(1)
command! VunitUpdateTestList call VunitUpdateTestList()
command! VunitReRunSelectedTests call VunitReRunSelectedTests()
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" global variables that can be used for configuration
if !exists("g:VunitInvocationCmd")
  let g:VunitInvocationCmd = 'python3'
endif

if !exists("g:VunitRunpyScriptName")
  let g:VunitRunpyScriptName = 'run.py'
endif

if !exists("g:VunitGuiPreCmd")
  let g:VunitGuiPreCmd = 'export $(tmux show-env | grep DISP); '
endif

if !exists("g:VunitPreCmd")
  let g:VunitPreCmd = ''
endif

if !exists("g:VunitAdditionalOptions")
  let g:VunitAdditionaOptions = ''
endif

if !exists("g:VunitAdditionalGuiOptions")
  let g:VunitAdditionalGuiOptions = ''
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Actual implementation
"

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Only a function to test the CreateTestDict
function TestCreateTestDict()
  let l:ts = "library.test_bench.test_case.use_case"
  let l:test_dict = {}
  call s:CreateTestDict(l:test_dict,split(l:ts, '\.'))

  let l:ts = "library.test_bench.test_case.other_use_case"
  call s:CreateTestDict(l:test_dict,split(l:ts, '\.'))

  let l:ts = "library.test_bench.test_ca.other_use_case.bla.blu.blo"
  call s:CreateTestDict(l:test_dict,split(l:ts, '\.'))

  let l:test_list = []
  call s:CreateTestList(l:test_dict,l:test_list,"")
  echomsg(string(l:test_dict))
  echomsg(string(l:test_list))
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Creates a dictionary of the elements of the test names. The elements beining
" the strings separated by a '.'
function! s:CreateTestDict(test_dict, split_test_string)

  let l:test_dict = a:test_dict

  if has_key(a:test_dict,a:split_test_string[0]) < 1
    let l:test_dict[a:split_test_string[0]] = {}
  endif

  if len(a:split_test_string) > 1
    call s:CreateTestDict(l:test_dict[a:split_test_string[0]],a:split_test_string[1:-1])
  endif

  return l:test_dict

endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Creates a list of tests from a hierarchical test dictionary (tree)
function! s:CreateTestList(test_dict, test_list, curr_name)
  let l:test_list = a:test_list

  if empty(a:test_dict)
    call add(l:test_list, a:curr_name)
  else

    for [key, value] in items(a:test_dict)
      if a:curr_name == ""
        let l:curr_name = a:curr_name . key
      else
        let l:curr_name = a:curr_name . "." . key
      endif
      call s:CreateTestList(value, l:test_list, l:curr_name)
    endfor

    if len(a:test_dict)>1
      call add(l:test_list, a:curr_name . ".*")
    endif

  endif

  return l:test_list

endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Adds wildcard options to tests that have multiple sub tests
"
" e.g.
" ----
" test.name.bla
" test.name.blo
"
" will then appear as
" test.*
" test.name.*
" test.name.bla
" test.name.blo
function! s:VunitCreateStarSelection(vunit_list)
  let l:test_dict = {}

  for test_string in a:vunit_list
    let l:split_test_string = split(test_string,'\.')

    if len(l:split_test_string) > 1
      call s:CreateTestDict(l:test_dict,l:split_test_string)
    endif

  endfor

  return s:CreateTestList(l:test_dict, [], "")

endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search the project directory. Currently only git repositories are supported
function VunitFindRootRunPy()
    let l:project_root = finddir('.git/..', ';')
    let l:runpy_and_workdir = { "runpy": expand(findfile(g:VunitRunpyScriptName, l:project_root . "**")), "workdir": l:project_root}
    return l:runpy_and_workdir
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" parsing of the jobstart
function! s:VunitGetTestList(job_id, data, event) dict
  if a:event == 'stdout'
    if a:data != ['']
      let g:vunit_test_list += a:data
    endif
  elseif a:event == 'stderr'
    if a:data != ['']
      echomsg "stderr " . join(a:data, "\r\r")
    endif
  else
    call sort(g:vunit_test_list)
    call uniq(g:vunit_test_list)
    let g:vunit_test_list = s:VunitCreateStarSelection(g:vunit_test_list)
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" run the vunit run.py script with -l, collect the tests and create wildcard
" entries
function VunitUpdateTestList()
  let g:vunit_test_list=[]
  let l:runpy = VunitFindRootRunPy()
  let s:opts = {
        \ 'on_stdout': function('s:VunitGetTestList'),
        \ 'on_stderr': function('s:VunitGetTestList'),
        \ 'on_exit'  : function('s:VunitGetTestList'),
        \ 'cwd'      : l:runpy["workdir"]
        \}
  let g:vunit_update_test_list_job_id = jobstart([g:VunitInvocationCmd,  l:runpy["runpy"], '-l', '--log-level', 'error'], s:opts)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Called by the plugin script to initially create a list of tests when opening
" a vhdl file
function VunitInitTestList()
  if !exists("g:vunit_test_list")
    call VunitUpdateTestList()
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Parameter guimode can be 0 for non gui mode or 1 for calling simulator with
" gui
function VunitRunTestWithFzf(guimode)
  let g:vunit_gui_mode = a:guimode
  if exists("g:vunit_test_list")
    call jobwait([g:vunit_update_test_list_job_id])
  else
    return
  endif
  if exists(":FZF")
    call fzf#run({
          \ 'source': g:vunit_test_list,
          \ 'options': '-m -d " " --with-nth 1',
          \ 'down' : '50%',
          \ 'sink*': function('VunitRunVunitTest'),
          \ 'window': {'width': 0.9, 'height': 0.6} })
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Rerun a previously selected test
function VunitReRunSelectedTests()
  call VunitRunVunitTest(g:VunitSelectedTests)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" The actual invocation of vunit with one or multiple selected tests
"
" ATTENTION: if the list of the selected tests is too long the terminal buffer
" might be to small
function VunitRunVunitTest(tests)
  if empty(a:tests)
    return
  endif
  if exists("g:vunit_buf")
    if bufexists(g:vunit_buf)
      exec "bd!".g:vunit_buf
    endif
  endif
  let g:VunitSelectedTests = a:tests
  let l:runpy = VunitFindRootRunPy()
  let l:command = g:VunitInvocationCmd . " " . l:runpy["runpy"] . " -m \"" . join(a:tests, "\" \"") . "\" -o nvim"
  if g:vunit_gui_mode == 1
    let l:command = g:VunitGuiPreCmd . l:command . " -g " . g:VunitAdditionalGuiOptions
  else
    let l:command = g:VunitPreCmd . l:command . g:VunitAdditionaOptions
  endif
  " reset g:vunit_gui_mode for next call
  let g:vunit_gui_mode = 0
  bo new | resize 15
  call termopen(l:command, {'cwd': l:runpy["workdir"]})
  call cursor(100,0)
  let g:vunit_buf = bufnr("%")
  let g:vunit_win = winnr()
  let g:vunit_tab = tabpagenr()
  wincmd p
endfunction

