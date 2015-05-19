# Readme

## What is this plugin ?

This plugin is a helper for compiling directly from vim, I recommend to use
it with [dispatch](https://github.com/tpope/vim-dispatch) but it can work
without, it is also compatible with
[vim-latex](http://vim-latex.sourceforge.net/) compilation settings.

Since v0.1.1 it can also compile using
[vimux](https://github.com/benmills/vimux) but for the moment it does not
provide the quickix window for vimux compilations.

It provides an easy and unified way to set and use compilers, see the Features
secion.

## Install

### Quick install

    git clone https://github.com/dbeniamine/vim-compile.git
    cd vim-compile/
    cp -r ./* ~/.vim

### Pathogen install

    git clone https://github.com/dbeniamine/vim-compile.git ~/.vim/bundle/vim-compile

## Features

This plugins provides a pre-defined list of compilation and execution rules by
filetype using xdg-open (sometimes). If a Makefile are a build.xml is
available, it will always be prefered to the filetype rule.

The user can easily add / modify theses rules, see the next section.

The following compilation function is provided

    " Launch a compilation
    " All arguments are booleans
    " args:
    "   compi:      Actually compile (or clean)
    "   forcemake:  Use Makefile instead of predefined function
    "   parallel:   Pass -j option to Makefile, require forcemake
    "   install:    Do installation, require forcemake
    "   exec:       Start an execution
    "   clean:      doe a make clean, require forcemake
    function! VimCompileCompile(compi, forcemake, parallel, install, exec,clean)

The compilation is executed by the first available options:

1. [Dispatch](https://github.com/tpope/vim-dispatch)
2. [Vimux](https://github.com/benmills/vimux) (no quickfix for the moment)
3. Native :make (always available)

There are several predefined compilation mappings:

    " make
    noremap <leader>m :call VimCompileCompile(1,0,0,0,0,0)<CR>

    " make & exec
    noremap <leader>me :call VimCompileCompile(1,0,0,0,1,0)<CR>

    " make & install
    noremap <leader>mi :call VimCompileCompile(1,1,0,1,0,0)<CR>

    " make parallel
    noremap <leader>mj :call VimCompileCompile(1,1,1,0,0,0)<CR>

    " make install parallel
    noremap <leader>mij :call VimCompileCompile(1,1,1,1,0,0)<CR>

    " make & exec parallel
    noremap <leader>mje :call VimCompileCompile(1,1,1,0,1,0)<CR>

    " make clean
    noremap <leader>mc :call VimCompileCompile(1,0,0,0,0,1)<CR>

    " make clean and make
    noremap <leader>mc :call VimCompileCompile(1,0,0,0,0,1)<CR>

    " exec
    noremap <leader>e :call VimCompileCompile(0,0,0,0,1,0)<CR><CR>



## Configuration

Three variables can be used to configure the plugin, the two firsts are
dictionaries (see :help Dictionary) giving the association filetype =>
compile or execute rule.
For instances adding the following to your vimrc will change the compilation
and execution rules for pandoc files

    let g:VimCompileExecutors={'pandoc' : "firefox %:t:r.html > /dev/null 2>&1",}
    let g:VimCompileCompiler={'pandoc' : "pandoc --smart --standalone --mathml --listings % > %:t:r.html",}

The third gives the default execution rule if none are defined for the
filetype:

    let g:VimCompileDefaultExecutor="./%"

## TODO

1. Make QuickFix work with vimux
2. Give Flexible choice for user (vim/Dispatch/Vimux/other function or plugin)
