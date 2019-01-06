" File:         pick-me-up.vim
" Description:  Fast characterwise, linewise, and blockwise mouse selections
" Author:       Brian Dellatera <github.com/bdellaterra>
" Version:      0.1.1
" License:      Copyright 2017-2019 Brian Dellaterra. This file is part of Pick-Me-Up.
"               Distributed under the terms of the GNU Lesser General Public License.
"               See the file LICENSE or <http://www.gnu.org/licenses/>.


" Check compatibility
if &compatible || v:version < 700 
    finish
end

" Guard against repeat sourcing of this script
if exists('g:loaded_pickMeUpPlugin')
    finish
end
let g:loaded_pickMeUpPlugin = 1

" convert path to forward slashes with a slash at the end
function s:DirSlashes(path)
    return substitute(a:path, '[^/\\]\@<=$\|\\', '/', 'g')
endfunction

if exists('g:pickMeUpSessionDir')
    let s:TmpDir = s:DirSlashes(g:pickMeUpSessionDir)
else
    let s:TmpDir = s:DirSlashes(fnamemodify(tempname(), ':h:h'))
end

" Python is required if 'base64' command isn't available
if exists('g:sessionEncodeCmd') && exists('g:sessionDecodeCmd')
    let s:encodeCmd = g:sessionEncodeCmd
    let s:decodeCmd = g:sessionDecodeCmd
elseif executable('base64')
    let s:encodeCmd = 'base64'
    let s:decodeCmd = 'base64 -d'
elseif executable('python')
    let s:encodeCmd = 'python -m base64 -e'
    let s:decodeCmd = 'python -m base64 -e'
else
    finish
endif

function s:DefaultSessionId()
    " Create project-specific session if projectroot.vim is installed
    if exists('*ProjectRootGuess')
        let baseDir = ProjectRootGuess()
    else
        let baseDir = $HOME
    end
    return substitute(system(s:encodeCmd, baseDir), '\_s*$', '', '')
endfunction

function s:DefaultSessionFile()
    if exists('g:activeSessionFile')
        return g:activeSessionFile
    else
        return s:TmpDir . s:DefaultSessionId() . '.vim'
    endif
endfunction

function SaveSession(...)
    let sessionFile = get(a:000, 0, s:DefaultSessionFile())
    let saveSessionOptions = &sessionoptions
    set sessionoptions=buffers,curdir,tabpages,winsize
    exe 'mksession! ' . sessionFile
    let &sessionoptions = saveSessionOptions
endfunction

function RestoreSession(...)
    let sessionFile = get(a:000, 0, s:DefaultSessionFile())
    execute 'source ' . sessionFile
    windo filetype detect
endfunction

function DeleteSession(...)
    let sessionFile = get(a:000, 0, s:DefaultSessionFile())
    call delete(sessionFile)
endfunction

" Create editor commands for the functions
command -nargs=? -complete=file SaveSession call SaveSession(<f-args>)
command -nargs=? -complete=file RestoreSession call RestoreSession(<f-args>)
command -nargs=? -complete=file DeleteSession call DeleteSession(<f-args>)

autocmd BufAdd,BufHidden,BufLeave,FileType * SaveSession
autocmd VimLeave * if exists(s:DefaultSessionFile()) | SaveSession | endif

function InitSession()
    if !argc() && filereadable(s:DefaultSessionFile())
        try
            call RestoreSession()
        " Catch all errors for silent start
        catch
        endtry
    endif
endfunction

" Restore default session when vim is started with no file argument(s)
autocmd VimEnter * call InitSession()


