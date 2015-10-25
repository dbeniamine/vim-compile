" File:        vim-compile.vim
" Description: Helper to compile from vim
" Author:      David Beniamine <David@Beniamine.net>
" License:     Vim license
" Website:     http://github.com/dbeniamine/vim-compile.vim
" Version:     0.2.3

" Don't load twice {{{1
if exists("g:loaded_VimCompile")
    finish
endif
let g:loaded_VimCompile=0.2.2

" Save context {{{1
let s:save_cpo = &cpo
set cpo&vim

" Default compile/exec rules {{{1

" Compilers {{{2
let s:VimCompileDefaultCompilers={'cpp': " g++ -Wall -Werror -g -o %:r %",
            \ 'c': "gcc -Wall -Werror -g -o %:r %",
            \'java': "javac %",
            \"dot": "dot -Tpdf % %:r.pdf",
            \'pandoc': "pandoc --smart --standalone --mathml --listings % > %:r.html",
            \'tex': "pdflatex --interaction=nonstopmode %",
            \'plaintex': "pdflatex --interaction=nonstopmode %",
            \}
if (exists("g:VimCompileCompilers"))
    for key in keys(s:VimCompileDefaultCompilers)
        if (!has_key(g:VimCompileCompilers,key))
            let g:VimCompileCompilers[key]=s:VimCompileDefaultCompilers[key]
        endif
    endfor
else
    let g:VimCompileCompilers=s:VimCompileDefaultCompilers
endif

" Executors {{{2
let s:VimCompileDefaultExecutors={'cpp': " ./%:r", 'c': " ./%:r",
            \'java': "java\ %:r",
            \'dot' : "xdg-open %:r.pdf > /dev/null 2>&1 &",
            \'pandoc' : "xdg-open %:r:p.html > /dev/null 2>&1 &",
            \'tex' : "xdg-open %:r.pdf > /dev/null 2>&1 &",
            \'plaintex' : "xdg-open %:r.pdf > /dev/null 2>&1 &",
            \}
if (exists("g:VimCompileExecutors"))
    for key in keys(s:VimCompileDefaultExecutors)
        if (!has_key(g:VimCompileExecutors,key))
            let g:VimCompileExecutors[key]=s:VimCompileDefaultExecutors[key]
        endif
    endfor
else
    let g:VimCompileExecutors=s:VimCompileDefaultExecutors
endif

if (!exists("g:VimDefaultExecutor"))
    let g:VimCompileDefaultExecutor="./%"
endif

" Compilation mappings {{{1

" compile {{{2
if !exists("g:VimCompileDoNotMap")
    noremap <leader>m :call vimcompile#Compile(1,0,0,0,0)<CR>
" compile & exec {{{2
    noremap <leader>me :call vimcompile#Compile(1,0,0,1,0)<CR>
" make install and make install {{{2
    noremap <leader>mi :call vimcompile#Compile(1,0,1,0,0)<CR>
" make parallel {{{2
    noremap <leader>mj :call vimcompile#Compile(1,1,0,0,0)<CR>
" make parallel and make install parallel {{{2
    noremap <leader>mij :call vimcompile#Compile(1,1,1,0,0)<CR>
" make parallel and exec{{{2
    noremap <leader>mje :call vimcompile#Compile(1,1,0,1,0)<CR>
" clean {{{2
    noremap <leader>mc :call vimcompile#Compile(1,0,0,0,1)<CR>
" clean and compile {{{2
    noremap <leader>mcm :call vimcompile#Compile(1,0,0,0,2)<CR>
" exec {{{2
    noremap <leader>e :call vimcompile#Compile(0,0,0,1,0)<CR><CR>
" clean, compile ad execute {{{2
    noremap <leader>mce :call vimcompile#Compile(1,0,0,1,2)<CR>
endif

" Restore context {{{1
let &cpo = s:save_cpo
