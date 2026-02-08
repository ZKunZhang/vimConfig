" Codex CLI vim config (XDG)
set nocompatible
filetype plugin indent on
syntax on

" Editing helpers
set number
set relativenumber
set cursorline
set laststatus=2
set showcmd
set wildmenu
set hidden

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase

" Encoding / file format
set encoding=utf-8
set fileencoding=utf-8
set fileformats=unix,dos,mac

" Statusline: full path, flags, filetype, encoding, format, line/total, column
set statusline=%F\ %h%m%r%w%=[%y]\ [%{&fileencoding==''?&encoding:&fileencoding}]\ [%{&fileformat}]\ %l/%L:%c

" Leader key
let mapleader=" "

" Quick save/quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>wq :wq<CR>
nnoremap <leader>qa :qa<CR>
nnoremap <leader>x :x<CR>
nnoremap <leader>h :nohlsearch<CR>
nnoremap <C-f> /
vnoremap <C-f> /

" File tree (netrw)
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25
let g:netrw_list_hide = '\v(^\./$|\.git/|node_modules/|dist/|build/|\.next/|coverage/|\.cache/|\.turbo/)'

let s:project_ignore_regex = '\v/(node_modules|\.git|dist|build|\.next|coverage|\.cache|\.turbo)/'
let s:project_file_exts = ['.tsx', '.ts', '.jsx', '.js']

function! s:ProjectRoot() abort
  let l:dir = expand('%:p:h')
  if empty(l:dir)
    let l:dir = getcwd()
  endif
  let l:root = systemlist('git -C ' . shellescape(l:dir) . ' rev-parse --show-toplevel')
  if v:shell_error == 0 && !empty(l:root)
    return l:root[0]
  endif
  return l:dir
endfunction

function! s:OpenProjectTree() abort
  execute 'Lexplore' fnameescape(s:ProjectRoot())
endfunction

function! s:OpenProjectPath(path) abort
  if a:path ==# ''
    call s:OpenProjectTree()
    return
  endif

  let l:path = expand(a:path)
  let l:root = s:ProjectRoot()
  if l:path !~# '^/'
    let l:path = l:root . '/' . l:path
  endif

  if isdirectory(l:path)
    execute 'Lexplore' fnameescape(l:path)
    return
  endif

  if filereadable(l:path)
    execute 'edit' fnameescape(l:path)
    return
  endif

  for l:ext in s:project_file_exts
    if filereadable(l:path . l:ext)
      execute 'edit' fnameescape(l:path . l:ext)
      return
    endif
  endfor

  let l:needle = a:path
  if l:needle =~# '^/'
    if l:needle[:len(l:root) - 1] ==# l:root
      let l:needle = l:needle[len(l:root) + 1 :]
    else
      let l:needle = fnamemodify(l:needle, ':t')
    endif
  endif

  let l:candidates = []
  call extend(l:candidates, globpath(l:root, '**/' . l:needle, 0, 1))
  for l:ext in s:project_file_exts
    call extend(l:candidates, globpath(l:root, '**/' . l:needle . l:ext, 0, 1))
  endfor

  let l:candidates = sort(filter(l:candidates, 'v:val !=# \"\" && v:val !~# s:project_ignore_regex'))
  let l:candidates = uniq(l:candidates)

  if empty(l:candidates)
    echohl WarningMsg | echom 'Path not found: ' . l:path | echohl None
    return
  endif

  if len(l:candidates) == 1
    let l:target = l:candidates[0]
  else
    let l:choices = ['Select target:']
    for l:i in range(len(l:candidates))
      call add(l:choices, printf('%d. %s', l:i + 1, l:candidates[l:i]))
    endfor
    let l:sel = inputlist(l:choices)
    if l:sel <= 0 || l:sel > len(l:candidates)
      return
    endif
    let l:target = l:candidates[l:sel - 1]
  endif

  if isdirectory(l:target)
    execute 'Lexplore' fnameescape(l:target)
  else
    execute 'edit' fnameescape(l:target)
  endif
endfunction

function! s:PromptProjectPath() abort
  let l:input = input('Open: ', '', 'file')
  if l:input ==# ''
    return
  endif
  call s:OpenProjectPath(l:input)
endfunction

function! s:ToggleProjectTree() abort
  if exists('t:netrw_lexplore') && t:netrw_lexplore !=# ''
    Lexplore
  else
    call s:OpenProjectTree()
  endif
endfunction

command! -nargs=? P call <SID>OpenProjectPath(<q-args>)
nnoremap <C-b> :call <SID>ToggleProjectTree()<CR>
nnoremap <C-p> :call <SID>PromptProjectPath()<CR>

augroup NetrwMappings
  autocmd!
  autocmd FileType netrw nnoremap <buffer> q :Lexplore<CR>
  autocmd FileType netrw nnoremap <buffer> o <CR>:Lexplore<CR>
augroup END
