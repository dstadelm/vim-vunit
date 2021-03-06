# Introduction

Vunit is a framework for running vhdl testbenches. The framework provides a
list of tests that can be run. Through the framework one can invoke the
tests in an headless mode or with the gui of the simulator. This plugin
provides a way to interact with the vunit framework through vim directly and
therefore eliminateing the need to switch to a terminal and search for the
test to run.

# Requirements

- vim8 or nvim
- FZF

# Usage

The plugin provides an fzf interface from which one can select the test or
multiple tests to run. The plugin opens a horizontal split in the bottom
part of the window. The test runs asynchronously and does block you from
editing your source.

# Configuration
*g:VunitInvocationCmd*


            Type: |String|
            The command to be used to invoke the run.py script.

            Default value:

            let g:VunitInvocationCmd = 'python3'


*g:VunitRunpyScriptName*

            Type: |String|
            The name to be used as run.py script.

            Default value:

            let g:VunitRunpyScriptName = 'run.py'


*g:VunitPreCmd*

            Type: |String|
            A command that can be executed prior to running vunit

            Default value:

            let g:VunitPreCmd = ''

*g:VunitGuiPreCmd*

            Type: |String|
            A command that can be executed prior to running vunit in gui mode

            Default value:

              let g:VunitGuiPreCmd = ''


            Example value:

              let g:VunitGuiPreCmd = 'export $(tmux show-env | grep DISP);'


*g:VunitAdditionalOptions*

            Type: |String|
            Additional options to be passed when invoking vunit

            Default value:

              let g:VunitAdditionalOptions = ''


*g:VunitAdditionalGuiOptions*

            Type: |String|
            Additional options to be passed when invoking vunit in gui mode

            Default value:

              let g:VunitAdditionalOptions = ''



# Mappings

There are no default mappings, here are some possible examples
```
  nnoremap <leader>vr :VunitRunTestWithFzf<CR>
  nnoremap <leader>vg :VunitRunTestWithFzfInGui<CR>
  nnoremap <leader>vl :VunitUpdateTestList<CR>
  nnoremap <leader>rr :VunitReRunSelectedTests<CR>
```
