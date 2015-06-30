# Readme

## What is this plugin ?

This plugin is a flexible helper for compiling directly from vim. Compilation
and execution command are run using the first avalaible of the following
options:

1. Custom function (see [custom starter](#starter) )
2. [Dispatch](https://github.com/tpope/vim-dispatch)
3. Vim shell escape (`:make` and `:!`)

It also provides an easy and unified way to set and use compilers, and
natively integrate with [vim-latex-suite](http://vim-latex.sourceforge.net/)
compilation settings.

## What is new ?

+   v0.3.1 allows the user to define a cleaning command to use with the custom
    builder. It also adds a few bug fix and two new mappings (clean and
    compile, clean compile and execute, see [mappings](#mappings))

+   Since V0.3, you can now define a custom builder for instance ̀`build.sh`
    with custom build and execute command. Such a builder will be always chosen
    if available, see [custom builder](#builder)

+   Since v0.2.3, vim-compile will try to retrieve the latex main file for
    compilation and execution.

    If latex-suite is activated, it search for a `*.latexmain` file, else it
    looks for a root file line, similar to the following:

        %!TEX root=my_main_file.tex
+   *Note* Since v0.2.2, you need to use `function()` to set a custom starter
    function.
+   Since v0.2 you can define a custom function to launch commands (compilation
    and exectuion), see [custom starter](#starter).


## Install

### Quick install

    git clone https://github.com/dbeniamine/vim-compile.git
    cd vim-compile/
    cp -r ./* ~/.vim

### Pathogen install

    git clone https://github.com/dbeniamine/vim-compile.git ~/.vim/bundle/vim-compile

## Usage


This plugin provides an easy way to compile and execute any file.

Some compilation and executions rules are predefined for a few filetypes, but the
user can redefine them, see [rules](#rules) for how.

If a `Makefile` exists in the working directory, `make` will be prefered over
the predefined rule. The same way, if a `build.xml` file exists, `ant` will be
prefered. The user can also define a custom builder that will always be
prefered to `make` and `ant`, see [custom builder](#builder)

For latex files, if [vim-latex-suite](http://vim-latex.sourceforge.net/) is
present, the predefined rules will be overwritten vy vim-late-suite settings.
Vim-compile will always try to guess if the current file is part of a bigger
latex project either using `*.latexmain` file (see help latex-master-file) or
by searching for a line ̀like `%!TEX root=my_main_file.tex` in the current
file. For these kind of project, vim should be open from the directory
containing the main file.

### Mappings

Some useful Mappings are defined:

+ `<leader>m` Compile

+ `<leader>e` Execute

+ `<leader>me` Compile and execute

+ `<leader>mc` Clean

+ `<leader>mcm` Clean and compile

+ `<leader>mce` Clean, Compile and execute


Some of the mappings are only working with Makefiles:

+ `<leader>mj` Make parallel

+ `<leader>mi` Make install

+ `<leader>mij` Make parallel and make install parallel

+ `<leader>mje` Make parallel and execute



## Configuration


### Rules

Two dictionaries (see :help Dictionary) can be used to modify or add
compilation and execution rules.
For instances adding the following to your vimrc will change the compilation
and execution rules for pandoc files

    let g:VimCompileExecutors={'pandoc' : "firefox %:t:r.html > /dev/null 2>&1",}
    let g:VimCompileCompiler={'pandoc' : "pandoc --smart --standalone --mathml --listings % > %:t:r.html",}

The following variable gives the default execution rule if none are defined
for the filetype:

    let g:VimCompileDefaultExecutor="./%"

### Starter

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

### Builder

Vim-compile allow you to define a custom compilation system which will always
be used if available. For instance if you have a script called `build.sh`, you
can define the following variables in your vimrc (adapt to your needs):

    let g:VimCompileCustomBuilder='build.sh'
    let g:VimCompileCustomBuilderCompile='./build.sh'

You can also define an executor command using this build system:

    let g:VimCompileCustomBuilderExec='./build.sh view'

And of course of command for cleanning the compilation stuff

    let g:VimCompileCustomBuilderClean='./build.sh clean'
