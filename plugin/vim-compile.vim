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
if !hasmapto("<leader>m",'n')
    noremap <leader>m :call VimCompileCompile(1,0,0,0,0)<CR>
endif

" compile & exec {{{2
if !hasmapto("<leader>me",'n')
    noremap <leader>me :call VimCompileCompile(1,0,0,1,0)<CR>
endif

" make install and make install {{{2
if !hasmapto("<leader>mi",'n')
    noremap <leader>mi :call VimCompileCompile(1,0,1,0,0)<CR>
endif

" make parallel {{{2
if !hasmapto("<leader>mj",'n')
    noremap <leader>mj :call VimCompileCompile(1,1,0,0,0)<CR>
endif

" make parallel and make install parallel {{{2
if !hasmapto("<leader>mij",'n')
    noremap <leader>mij :call VimCompileCompile(1,1,1,0,0)<CR>
endif

" make parallel and exec{{{2
if !hasmapto("<leader>mje",'n')
    noremap <leader>mje :call VimCompileCompile(1,1,0,1,0)<CR>
endif

" clean {{{2
if !hasmapto("<leader>mc",'n')
    noremap <leader>mc :call VimCompileCompile(1,0,0,0,1)<CR>
endif

" clean and compile {{{2
if !hasmapto("<leader>mcm",'n')
    noremap <leader>mcm :call VimCompileCompile(1,0,0,0,2)<CR>
endif

" exec {{{2
if !hasmapto("<leader>e",'n')
    noremap <leader>e :call VimCompileCompile(0,0,0,1,0)<CR><CR>
endif

" clean, compile ad execute {{{2
if !hasmapto("<leader>mcm",'n')
    noremap <leader>mce :call VimCompileCompile(1,0,0,1,2)<CR>
endif

" Functions {{{1

function! VimCompileGetLatexMainFile()
    " Set latex main file
    let l:mainfile=substitute(glob("*.latexmain"),".latexmain","","")
    if empty(l:mainfile)
        let l:ignore=&ignorecase
        set ignorecase
        let l:line=search("%!TEX root=","cn")
        let &ignorecase=l:ignore
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
        else
            let l:mainfile=expand("%")
        endif
    endif
    return l:mainfile
endfunction
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
"   parallel:   Pass -j option to Makefile, for makefile only
"   install:    Do installation,  for makefile only
"   exec:       Start an execution
"   clean:      clean, (for Makefile, Ant and custom builder only), if clean==2
"               continue compilation after cleaning
function! VimCompileCompile(compi, parallel, install, exec,clean)

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

    if( &ft=='tex' || &ft=='plaintex' ) " Special rules for latex {{{3
        " get main file
        let l:mainfile=VimCompileGetLatexMainFile()
        " prepare latex suite rules if defined
        if (exists("g:Tex_DefaultTargetFormat") &&
                    \ exists("g:VimCompileUseLatexSuite") &&
                    \ g:VimCompileUseLatexSuite == 1)
            let l:make=Tex_GetVarValue('Tex_CompileRule_'.g:Tex_DefaultTargetFormat).l:mainfile
            let l:output=substitute(l:mainfile,".[^\.]*$",".".g:Tex_DefaultTargetFormat,"")
            let l:start=Tex_GetVarValue('Tex_ViewRule_'.g:Tex_DefaultTargetFormat)." ".l:output." &"
        endif
        " update rules
        if (l:mainfile!=expand('%'))
            " Update commands
            let l:base=substitute(l:mainfile,'\(.*\)\.[^\.]*','\1','')
            let l:make=substitute(VimCompileExpandAll(l:make),expand("%:r"),l:mainfile,"g")
            let l:start=substitute(VimCompileExpandAll(l:start),expand("%:r"),l:base,'')
        endif
    endif
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
endif

if(a:compi) " Compile {{{3
    " Save the file
    :w
    if(a:clean)
        let l:clean=''
        if exists("g:VimCompileCustomBuilderClean") && filereadable(g:VimCompileCustomBuilder)
            let l:clean=g:VimCompileCustomBuilderClean
        elseif filereadable("Makefile")
            let l:clean="make clean"
        elseif filereadable("build.xml")
            let l:clean="ant clean"
        endif
        if l:clean!=''
            call s:VimCompileStartCmd(l:clean, 'm')
        else
            echo "Clean is only available for make, ant, and custom builders"
            sleep 3
        endif
        if(a:clean !=2)
            return
        endif
    endif
    if l:make=="make"
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
    return substitute(a:str,'\(%[:phtre]*\)','\=expand(submatch(1))','g')
endfunction

" Restore context {{{1
let &cpo = s:save_cpo
