# Readme

## What is this plugin ?

This plugin is a flexible helper for compiling directly from vim. Compilation
and execution command are run using the first avalaible of the following
options:

1. Custom function (see [configuration](#configuration) )
2. [Dispatch](https://github.com/tpope/vim-dispatch)
3. Vim shell escape (`:make` and `:!`)

It also provides an easy and unified way to set and use compilers, and
natively integrate with [vim-latex-suite](http://vim-latex.sourceforge.net/)
compilation settings.

## What is new ?

+   Since v0.2.3, vim-compile will try to retrieve the latex main file for
    compilation and execution.

    If latex-suite is activated, it search for a `*.latexmain` file, else it
    looks for a root file line, similar to the following:

        %!TEX root=my_main_file.tex
+   *Note* Since v0.2.2, you need to use `function()` to set a custom starter
    function.
+   Since v0.2 you can define a custom function to launch commands (compilation
    and exectuion), see [configuration](#configuration).


## Install

### Quick install

    git clone https://github.com/dbeniamine/vim-compile.git
    cd vim-compile/
    cp -r ./* ~/.vim

### Pathogen install

    git clone https://github.com/dbeniamine/vim-compile.git ~/.vim/bundle/vim-compile

## Features


This plugin provides an easy way to compile and execute any file.

Some compilation and executions rules are predefined for a few filetypes, but the
user can redefine them, see [configuration](#configuration) for how.

If a `Makefile` exists in the working directory, `make` will be prefered over
the predefined rule. The same way, if a `build.xml` file exists, `ant` will be
prefered.

For latex files, if [vim-latex-suite](http://vim-latex.sourceforge.net/) is
present, the predefined rules will be overwritten vy vim-late-suite settings.
Vim-compile will always try to guess if the current file is part of a bigger
latex project either using `*.latexmain` file (see help latex-master-file) or
by searching for a line ̀like `%!TEX root=my_main_file.tex` in the current
file. For these kind of project, vim should be open from the directory
containing the main file.

The compilation/execution function is visible to the user, and can be easily
called. Still some usefull compilation mappings are defined:

    " make only
    noremap <leader>m :call VimCompileCompile(1,0,0,0,0,0)<CR>

    " make and execute
    noremap <leader>me :call VimCompileCompile(1,0,0,0,1,0)<CR>

    " make and make install
    noremap <leader>mi :call VimCompileCompile(1,1,0,1,0,0)<CR>

    " make parallel
    noremap <leader>mj :call VimCompileCompile(1,1,1,0,0,0)<CR>

    " make install parallel
    noremap <leader>mij :call VimCompileCompile(1,1,1,1,0,0)<CR>

    " make parallel and execute
    noremap <leader>mje :call VimCompileCompile(1,1,1,0,1,0)<CR>

    " make clean
    noremap <leader>mc :call VimCompileCompile(1,0,0,0,0,1)<CR>

    " make clean and make
    noremap <leader>mc :call VimCompileCompile(1,0,0,0,0,1)<CR>

    " execute
    noremap <leader>e :call VimCompileCompile(0,0,0,0,1,0)<CR><CR>

It is possible to add other mappings, there is the specification of the
compile function:

    " Launch a compilation
    " All arguments are booleans
    " args:
    "   compi:      Do compile (or clean)
    "   forcemake:  Use make whatever (for make install / make clean rules)
    "   parallel:   Pass -j option to Makefile, require forcemake
    "   install:    Do installation, require forcemake
    "   exec:       Start an execution
    "   clean:      Make clean, require forcemake
    function! VimCompileCompile(compi, forcemake, parallel, install, exec,clean)


## <a name=configuration>Configuration</a>

Two dictionaries (see :help Dictionary) can be used to modify or add
compilation and execution rules.
For instances adding the following to your vimrc will change the compilation
and execution rules for pandoc files

    let g:VimCompileExecutors={'pandoc' : "firefox %:t:r.html > /dev/null 2>&1",}
    let g:VimCompileCompiler={'pandoc' : "pandoc --smart --standalone --mathml --listings % > %:t:r.html",}

The following variable gives the default execution rule if none are defined
for the filetype:

    let g:VimCompileDefaultExecutor="./%"

A custom starter function (responsible for starting compilation and execution)
can be provided by setting the following variable:

     let g:VimCompileCustomStarter=function("MyStarterFunction")

A starter functions takes two arguments:

+ the first is the command to execute
+ the second is a character:
    + `'m'` indicate that we are doing an actual compilation
    + `'e'` means that we run a custom command.

For a better understanding of starter functions, there is the default one:

    " Default command starter {{{2
    " Start a command using Dispatch if available or the shell escape
    " Arguments: cmd: the command to execute
    "            type: 'm' if we are doing a compilation, 'e' otherwise
    function! VimCompileDefaultStartCmd(cmd,type)
        if (a:type=='m') " Compilation: use makeprg and :Dispatch or :make
            let &makeprg=a:cmd
            if exists("g:loaded_dispatch")
                let l:launcher=":Dispatch"
            else
                let l:launcher=":make"
            endif
        else " Normal command
            let l:cmd=a:cmd
            if exists("g:loaded_dispatch")
                let l:launcher=":Start"
                if (a:cmd=~'^.*&\s*$') " Let Dispatch handle background commands
                    let l:cmd=substitute(a:cmd,'&\s*$','','')
                    let l:launcher.="!"
                endif
            else " Simple shell escape
                let l:launcher=":!"
            endif
            let l:launcher.=" ".l:cmd
        endif
        execute l:launcher
    endfunction
