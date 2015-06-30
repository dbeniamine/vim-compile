" File:        vim-compile.vim
" Description: Helper to compile from vim
" Author:      David Beniamine <David@Beniamine.net>
" License:     Vim license
" Website:     http://github.com/dbeniamine/vim-compile.vim
" Version:     0.2.2

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
            \'pandoc' : "xdg-open %:r.html > /dev/null 2>&1 &",
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

" Actual command starter {{{2
if exists("g:VimCompileCustomStarter")
    let s:VimCompileStartCmd=g:VimCompileCustomStarter
else
    let s:VimCompileStartCmd=function("VimCompileDefaultStartCmd")
endif

" Launch a compilation {{{2
" All arguments are booleans
" args:
"   compi:      Do compile (or clean)
"   forcemake:  Use make whatever (for make install / make clean rules)
"   parallel:   Pass -j option to Makefile, require forcemake
"   install:    Do installation, require forcemake
"   exec:       Start an execution
"   clean:      Make clean, require forcemake
function! VimCompileCompile(compi, forcemake, parallel, install, exec,clean)

    if(has_key(g:VimCompileCompilers,&ft)) " Compilator {{{3
        let l:make=g:VimCompileCompilers[&ft]
    else
        let l:make=&makeprg
    endif

    if (has_key(g:VimCompileExecutors,&ft)) " Executor {{{3
        let l:start=g:VimCompileExecutors[&ft]
    else
        let l:start=g:VimCompileDefaultExecutor
    endif

    " Use custom builder or makefile or build.xml if available {{{3
    if exists("g:VimCompileCustomBuilder") && filereadable(g:VimCompileCustomBuilder)
        let l:make=g:VimCompileCustomBuilderCompile
        if exists("g:VimCompileCustomBuilderExec")
            let l:start=g:VimCompileCustomBuilderExec
        endif
    elseif filereadable("Makefile")
        let l:make='make'
        "Change the start only if the make run target exists
        execute "silent !cat Makefile | grep \"run[ ]*:\""
        if v:shell_error == 0
            let l:start="make\ run"
        endif
    elseif filereadable("build.xml")
        set efm=%A\ %#[javac]\ %f:%l:\ %m,%-Z\ %#[javac]\ %p^,%-C%.%#
        let l:make='ant'
    else
        if( &ft=='tex' || &ft=='plaintex' ) " Special ules for latex {{{4
            " Use latex suite {{{5
            if (exists("g:Tex_DefaultTargetFormat") && g:Tex_DefaultTargetFormat!="")
                " Set main file
                let l:mainfile=substitute(glob("*.latexmain"),".latexmain","","")
                if empty(l:mainfile)
                    let l:mainfile="%"
                endif
                " Update commands
                let l:make=Tex_GetVarValue('Tex_CompileRule_'.g:Tex_DefaultTargetFormat).l:mainfile
                let l:output=substitute(l:mainfile,".[^\.]*$",".".g:Tex_DefaultTargetFormat,"")
                let l:start=Tex_GetVarValue('Tex_ViewRule_'.g:Tex_DefaultTargetFormat)." ".l:output." &"
            else
                " No latex suite, try to guess the main {{{5
                let l:ignore=&ignorecase
                set ignorecase
                " search for a line containing %!TEX root=
                let l:line=search("%!TEX root=","cn")
                if l:line != 0
                    " If found set the path of the mainfile
                    let l:path=substitute(getline(l:line),"%!TEX root=","","")
                    " Remove extension
                    let l:path=substitute(l:path, "\.[^\.]*$","","")
                    if(stridx(l:path,"/")!=0)
                        let l:mainfile="./".expand("%:h")."/".l:path
                    else
                        let l:mainfile=l:path
                    endif
                    " Update commands
                    let &ignorecase=l:ignore
                    let l:make=substitute(VimCompileExpandAll(l:make),expand("%:r"),l:mainfile,"g")
                    let l:start=substitute(VimCompileExpandAll(l:start),expand("%:r"),l:mainfile,"g")
                endif
            endif
        endif
    endif

    if(a:compi) " Compile {{{3
        " Save the file
        :w
        if(a:forcemake) " Use make command {{{4
            if(a:clean)
                call s:VimCompileStartCmd("make clean", 'm')
            endif
            let l:make="make"
            if(a:parallel) " Do it in parallel {{{5
                let l:ncores=system("cat /proc/cpuinfo | grep processor | wc -l")
                let l:ncores=substitute(l:ncores,"\n","","g")
                let l:make.=" -j ".l:ncores
            endif
            if(a:install) " Also do make install {{{5
                let l:make=l:make." && ".l:make." install"
            endif
        endif
        " Do the compilation {{{4
        call s:VimCompileStartCmd(l:make, 'm')
    endif
    if(a:exec) " Execute the program {{{3
        call s:VimCompileStartCmd(l:start, 'e')
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

" Expand a complete string as with expand. {{{2
"   my_command %:t:r.pdf & > my_log
" will be replace by
"   my_command file.pdf & > my_log
" while the native expand wouldn't have done any thing
function! VimCompileExpandAll(str)
    let l:accu=""
    for s in split(a:str)
        if s=~"%:.*\..*"
            let l:words=split(s,'\.')
            let l:accu.=" ".expand(l:words[0]).".".expand(l:words[1])
        else
            let l:accu.=" ".expand(s)
        endif
    endfor
    return l:accu
endfunction

" Restore context {{{1
let &cpo = s:save_cpo
