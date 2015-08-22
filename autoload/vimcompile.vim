" File:        autoload/vimcompile.vim
" Description: Helper to compile from vim
" Author:      David Beniamine <David@Beniamine.net>
" License:     Vim license
" Website:     http://github.com/dbeniamine/vim-compile.vim
" Version:     0.2.3


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
function! vimcompile#Compile(compi, parallel, install, exec,clean)

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


