" File:        vim-compile.vim
" Description: Helper to compile from vim
" Author:      David Beniamine <David@Beniamine.net>
" License:     Vim license
" Website:     http://github.com/dbeniamine/vim-compile.vim
" Version:     0.2

" Don't load twice {{{1
if exists("g:loaded_VimCompile")
    finish
endif
let g:loaded_VimCompile=0.2

" Save context {{{1
let s:save_cpo = &cpo
set cpo&vim

" Default compile/exec rules {{{1

" Compilers {{{2
let s:VimCompileDefaultCompilers={'cpp': " g++ -Wall -Werror -g -o %:t:r %",
            \ 'c': "gcc -Wall -Werror -g -o %:t:r %",
            \'java': "javac %",
            \"dot": "dot -Tpdf % %:t:r.pdf",
            \'pandoc': "pandoc --smart --standalone --mathml --listings % > %:t:r.html",
            \'tex': "pdflatex --interaction=nonstopmode %",
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
let s:VimCompileDefaultExecutors={'cpp': " ./%:t:r", 'c': " ./%:t:r",
            \'java': "java\ %:t:r",
            \'dot' : "xdg-open %:t:r.pdf > /dev/null 2>&1 &",
            \'pandoc' : "xdg-open %:t:r.html > /dev/null 2>&1 &",
            \'tex' : "xdg-open %:t:r.pdf > /dev/null 2>&1 &",
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

" make {{{2
if !hasmapto("<leader>m",'n')
    noremap <leader>m :call VimCompileCompile(1,0,0,0,0,0)<CR>
endif

" make & exec {{{2
if !hasmapto("<leader>me",'n')
    noremap <leader>me :call VimCompileCompile(1,0,0,0,1,0)<CR>
endif

" make & install {{{2
if !hasmapto("<leader>mi",'n')
    noremap <leader>mi :call VimCompileCompile(1,1,0,1,0,0)<CR>
endif

" make parallel {{{2
if !hasmapto("<leader>mj",'n')
    noremap <leader>mj :call VimCompileCompile(1,1,1,0,0,0)<CR>
endif

" make install parallel {{{2
if !hasmapto("<leader>mij",'n')
    noremap <leader>mij :call VimCompileCompile(1,1,1,1,0,0)<CR>
endif

" make & exec parallel {{{2
if !hasmapto("<leader>mje",'n')
    noremap <leader>mje :call VimCompileCompile(1,1,1,0,1,0)<CR>
endif

" make clean {{{2
if !hasmapto("<leader>mc",'n')
    noremap <leader>mc :call VimCompileCompile(1,0,0,0,0,1)<CR>
endif

" make clean and make {{{2
if !hasmapto("<leader>mcm",'n')
    noremap <leader>mc :call VimCompileCompile(1,0,0,0,0,1)<CR>
endif

" exec {{{2
if !hasmapto("<leader>e",'n')
    noremap <leader>e :call VimCompileCompile(0,0,0,0,1,0)<CR><CR>
endif

" Functions {{{1

" Start a command {{{2
" Choose the best way to start a command
" Arguments: cmd: the command
"            type: 'm' for a compilation, 'e' for a command to execute
" Possibilities: Custom function, Dispatch, :!
function! VimCompileStartCmd(cmd,type)
    if exists("g:VimCompileCustomStarter")
        " custom command
        execute ":call ".g:VimCompileCustomStarter."('".a:cmd."','".a:type."')"
    elseif exists("g:loaded_dispatch")
        " Dispatch: differentiate real command from make
        if a:type=='m'
            execute ":Dispatch ".a:cmd
        else
            " Background should be handled by Dispatch
            if (a:cmd=~'^.*&\s*$')
                let l:cmd=substitute(a:cmd,'&\s*$','','')
                echo l:cmd
                sleep 2
                execute ":Start! ".l:cmd
            else
                execute ":Start ".a:cmd
            endif
        endif
    else
        " Normal execution
        execute ":! ".a:cmd
    endif
endfunction

" Launch a compilation {{{2
" All arguments are booleans
" args:
"   compi:      Actually compile (or clean)
"   forcemake:  Use Makefile instead of predefined command
"   parallel:   Pass -j option to Makefile, require forcemake
"   install:    Do installation, require forcemake
"   exec:       Start an execution
"   clean:      doe a make clean, require forcemake
function! VimCompileCompile(compi, forcemake, parallel, install, exec,clean)
    let l:start=""
    if filereadable("Makefile") " Use makefile or build.xml if available {{{3
        set makeprg='make'
        "Change the start only if the make run target exists
        execute "silent !cat Makefile | grep \"run[ ]*:\""
        if v:shell_error == 0
            let l:start="make\ run"
        endif
    elseif filereadable("build.xml")
        set efm=%A\ %#[javac]\ %f:%l:\ %m,%-Z\ %#[javac]\ %p^,%-C%.%#
        set makeprg='ant'
    else " Use compile rule {{{3

        if(&ft=='tex' && g:Tex_DefaultTargetFormat!="") " Latex specific {{{4
            "Use latex suite if rule is defined
            let &makeprg=Tex_GetVarValue('Tex_CompileRule_'.g:Tex_DefaultTargetFormat)."\ %"
            let l:output="%:t:r.".g:Tex_DefaultTargetFormat
            let l:start=Tex_GetVarValue('Tex_ViewRule_'.g:Tex_DefaultTargetFormat)." ".l:output." &"
        else " Normal rule {{{4
            if(has_key(g:VimCompileCompilers,&ft))
                let &makeprg=g:VimCompileCompilers[&ft]
            endif
        endif
    endif
    if l:start=="" " Executor {{{3
        if (has_key(g:VimCompileExecutors,&ft))
            let l:start=g:VimCompileExecutors[&ft]
        else
            let l:start=g:VimCompileDefaultExecutor
        endif
    endif

    if(a:compi) " Compile {{{3
        " Save the file
        :w
        if(a:forcemake) " Use make command {{{4
            if(a:clean)
                set makeprg="make clean"
                call VimCompileStartCmd(l:cmd, 'm')
            endif
            let l:cmd="make"
            if(a:parallel) " Do it in parallel {{{5
                let l:ncores=system("cat /proc/cpuinfo | grep processor | wc -l")
                let l:ncores=substitute(l:ncores,"\n","","g")
                let makeprg.=" -j ".l:ncores

            endif
            if(a:install) " Also do make install {{{5
                let l:oldcmd=l:cmd
                let makeprg.=" && ".l:oldcmd." install"
            endif
        endif
        " Do the compilation {{{4
        call VimCompileStartCmd(&makeprg, 'm')
    endif
    if(a:exec) " Execute the program {{{3
        call VimCompileStartCmd(l:start, 'e')
    endif
    call VimCompileRedraw()
endfunction

" Redraw {{{2
function! VimCompileRedraw()
    " Redraw screen if no errors
    if v:shell_error == 0
        " Let some time to be sure that the start command is finished
        sleep 500m
        redraw!
    endif
endfunction

" Restore context {{{1
let &cpo = s:save_cpo
