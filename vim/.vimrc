"Launch Config {{{
set nocompatible
source ~/.vim/plugins.vim "run plugins script; install plugins

filetype plugin indent on

set backspace=indent,eol,start
"Allow backspacing while in insert mode.

"This will cause Vim to treat all numerals as decimals.
"Only matters when using <C-a> or <C-x> on numbers padded
"with zeros (e.g. 007)
set nrformats=

"This allows you to paste from your system clipboard
"in normal mode.
set clipboard=unnamed

" allow scrolling
set mouse=a

" get rid of audible bell
set visualbell

"Change directory to the current buffer when opening fies.
" set autochdir

"Let vim know that your tags files will always be called tags
"set tags=./tags;

set hidden
"This will allow you to switch buffers that have been
"modified (keeping its changes) without needing '!'
"e.g.(:buffer2! assuming your window is buffer 1 and
"you havemade changes to it.)

" http://vi.stackexchange.com/questions/3964/timeoutlen-breaks-leader-and-vim-commentary
"Link explians why none of your leader keys work.
"without these settings.Also,
"Makes Airline faster when leaving insert mode but
"may cause issues.
set timeoutlen=1000
set ttimeoutlen=10

set history=200" Number of commands that are remembered.
set encoding=utf-8             "The encoding displayed.
set fileencoding=utf-8         "The encoding written to file.
set ttyfast                    "Redraw the screen quicker

" start typing a command and then type hit <c-p> or <c-n> to filter history
cnoremap <c-p> <Up>
cnoremap <c-n> <Down>

"}}}
"UI Config {{{

set wildmenu                   "Commandline autocomplete view"
set number                     "Show line numbers.
set cursorline                 "Show the cursor line so its it's easier to find - SEE LEADER KEY TO TOGGLE
" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'
" highlight conflicts

set showmode                   "Show paste mode
set noshowmode                 "Disabled for PowerLine

set scrolloff=5                "Keep a few lines always visable
set ruler                      "Show the cursor position in command line
set showcmd                    "Display incomplete commands
set laststatus=2               "Show the satus line all the time
set cmdheight=2                "Make the command prompt bigger
set showmatch                  "Show matching \",],etc.
" set invlist
set listchars=tab:▸\ ,eol:¬,trail:⋅,extends:❯,precedes:❮
" set showbreak=↪

""}}}
"Colors {{{

syntax on
"turns on syntax highlighting

set termguicolors
"this makes WebStorm render colors in terminal

" let g:gruvbox_contrast_dark='medium'
let base16colorspace=256  " Access colors present in 256 colorspace
set t_Co=256  " the terminal supports 256 colors; see iTerm docs

" Note this theme has been tweaked. Keyword was changed to #6897BB 
" from #CC7832 (~/.vim/plugged/darcula/colors/darcula.vim). Number was 
" also changed from #6897BB to 
" #4F8C89.
colorscheme darcula

let g:Hexokinase_highlighters = ['sign_column'] " Make the color icon appear in the column
let g:Hexokinase_signIcon = '◼' " Make the color icon bigger than he default so it's easier to see

let g:SignatureMarkTextHL = "FoldedFg" 


"}}}
"Space and Tabs {{{

set smarttab " tab respects 'tabstop', 'shiftwidth', and 'softtabstop'
set tabstop=4 " the visible width of tabs
set softtabstop=4 " edit as if the tabs are 4 characters wide
set shiftwidth=4 " number of spaces to use for indent and unindent
set shiftround " round indent to a multiple of 'shiftwidth'
set autoindent  " automatically set indent of new line?
set smartindent

set pastetoggle=<F2>
"Allows you to preserve indentation when pasting
"during insert/normal mode (e.g.<C-r> 0).

set expandtab
"This will expand tabs into equivalent spaces.
"The default is noexpandtab, so just comment this
"setting out to turn it off.

    " Python {{{
" USING SIMPLYFOLD PLUGIN FOR PYTHON - BELOW IS A FALL BACK
    " au BufNewFile,BufRead *.py
    "     \ set tabstop=4
    "     \ set softtabstop=4
    "     \ set shiftwidth=4
    "     \ set textwidth=79
    "     \ set expandtab
    "     \ set autoindent
    "     \ set fileformat=unix

    " }}}
    " HTML, CSS, JS {{{
autocmd BufRead .jscsrc set filetype=json
autocmd BufRead .jshintrc set filetype=json
autocmd BufRead .bowerrc set filetype=json
autocmd BufRead .babelrc set filetype=json
autocmd BufRead .eslintrc set filetype=json
autocmd BufRead .tslintrc set filetype=json


    " }}}

"}}}
"Searching {{{

set hls "This will highlight all searches

set ignorecase " case insensitive searching
set smartcase " case-sensitive if expresson contains a capital letter
set hlsearch  " highlight searchs
set incsearch " view searches as you type 
set nolazyredraw " don't redraw while executing macros

"}}}
"Folding {{{

set modelines=1 " file specific settings; see bottom line below
set foldlevel=10 "prevents all folds from expanding when opening a file
set foldmethod=indent
set foldnestmax=10
set foldenable
nmap zo za
"}}}
"Custom Movements {{{

" scroll the viewport faster
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>

nnoremap j gj
nnoremap k gk
"move through lines that wrap without skipping

"}}}
"Keymap {{{

" REGULAR KEYS
" ----------------------------------------------------------
" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" GoTo code navigation.
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gi <Plug>(coc-implementation)

"show documentation in preview window.
nnoremap <silent> gh :call <SID>show_documentation()<CR>

" highlight last inserted text
nnoremap gV `[v`]

" Copy until the end of the line
noremap Y y$

" Toggle with zo since its easier than za
nmap zo za
vmap zo za

"delete all trailing whitespace off of every line by
:noremap <F4> :call TrimWhitespace()<CR>

" make it easier to jump to open windows
map <silent> <C-h> :call WinMove('h')<cr>
map <silent> <C-j> :call WinMove('j')<cr>
map <silent> <C-k> :call WinMove('k')<cr>
map <silent> <C-l> :call WinMove('l')<cr>

" Remap <C-f> and <C-b> for scroll float windows/popups.
if has('nvim')
  vnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#nvim_scroll(1, 1) : "\<C-f>"
  vnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#nvim_scroll(0, 1) : "\<C-b>"
  inoremap <nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" enable . command in visual mode
vnoremap . :normal .<cr>

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

"insert a '|' and the columns will align
inoremap <silent> <Bar>   <Bar><Esc>:call <SID>align()<CR>a

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" ----------------------------------------------------------
" LEADER KEYS
" ----------------------------------------------------------

let mapleader = "\<Space>" "Sets spacebar as leader

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

nnoremap <leader>bre :vsp ~/.bashrc<CR>
nnoremap <leader>brs :source ~/.bashrc<CR>
nnoremap <leader>bpe :vsp ~/.bash_profile<CR>
nnoremap <leader>bps :source ~/.bash_profile<CR>

" Manage extensions.
nnoremap <silent><nowait> <leader>e  :<C-u>CocList extensions<cr>
" Do default action for previous item.
" nnoremap <silent><nowait> <leader>k  :<C-u>CocPrev<CR>
" Do default action for next item.
" nnoremap <silent><nowait> <leader>j  :<C-u>CocNext<CR>

" Resume latest coc list.
nnoremap <silent><leader>pl  :<C-u>CocListResume<CR>

" clear highlighted search
noremap <leader>h :set hlsearch! hlsearch?<cr>

" Map function and class text objects
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)

"Make it easy to edit .ideavimrc.
nnoremap <leader>ie  :vsp ~/.ideavimrc<CR>

nmap <Leader>n :NERDTreeToggle<CR>

" Show window file symbol outline
nnoremap <leader>o  :<C-u>Vista coc<CR>

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Show / search commands.
nnoremap <leader>sc  :<C-u>CocList commands<cr>

" Show / find usages.
nmap <leader>su <Plug>(coc-references)

" Show / search workspace symbols
nnoremap <leader>sw  :<C-u>CocList -I symbols<cr>

" Show (toggle) invisible characters.
nmap <leader>si :set list!<cr>

" Show quick file symbol outline
nnoremap <leader>so  :<C-u>CocList outline<cr>

" Show all problems/diagnostics.
nnoremap <silent><space>sp  :<C-u>CocList diagnostics<cr>

" Show (toggle) cursor line.
nnoremap <leader>sl :set cursorline!<cr>

" Show (toggle) spelling errors.
map <leader>ss :setlocal spell!<cr>

"easily format on common characters '=' and ':'
if exists(":Tabularize")
    nmap <Leader>t= :Tabularize /=<CR>
    vmap <Leader>t= :Tabularize /=<CR>
    nmap <Leader>t: :Tabularize /:\zs<CR>
    vmap <Leader>t: :Tabularize /:\zs<CR>
endif

"Make it easy to edit and source .virmc & plugins.
nnoremap <leader>vs  :source ~/.vimrc<CR>
nnoremap <leader>ve  :vsp ~/.vimrc<CR>
nnoremap <leader>vp  :vsp ~/.vim/plugins.vim<CR>

"make it easier to save
nmap <leader>w :w!<cr>

"make it easy to edit and source .zshrc
nnoremap <leader>ze  :vsp ~/.zshrc<CR>
nnoremap <leader>zs  :source ~/.zshrc<CR>


" make it easy to resize window width
map <leader>- 20<c-w><
map <leader>= 20<c-w>>

" Textmate style indentation
vmap <leader>[ <gv
vmap <leader>] >gv
nmap <leader>[ <<
nmap <leader>] >>

" This allows you to filter command history AND
" traverse the results.  Only <Up> / <Down> allow you
" you to filter your command history.
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>

" nnoremap <leader>r :mksession<CR> " save session
" nnoremap <buffer> <F9> :exec '!python' shellescape(@%, 1)<cr>
" nnoremap <silent> <F5> :!clear;python %<CR>
" nmap <F5> :call VimuxRunCommand("clear;~/.virtualenvs/py3/bin/ipython  . bufname("%"))<CR>
" nmap <silent> <F5> :call VimuxRunCommand("clear;[ -z $VIRTUAL_ENV ] && workon py3; ipython " . bufname("%"))<CR> 
"}}}
"Custom Commands & Functions{{{

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')
function! SetupCommandAbbrs(from, to)
  exec 'cnoreabbrev <expr> '.a:from
        \ .' ((getcmdtype() ==# ":" && getcmdline() ==# "'.a:from.'")'
        \ .'? ("'.a:to.'") : ("'.a:from.'"))'
endfunction

" Use C to open coc config
call SetupCommandAbbrs('C', 'CocConfig')

"rename a file
command! -bar -nargs=1 -bang -complete=file Rename :
  \ let s:file = expand('%:p') |
  \ setlocal modified |
  \ keepalt saveas<bang> <args> |
  \ if s:file !=# expand('%:p') |
  \   call delete(s:file) |
  \ endif |
  \ unlet s:file

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" if no plugins support the file type then use as default
if has("autocmd") && exists("+omnifunc")
	autocmd Filetype *
        \	if &omnifunc == "" |
        \		setlocal omnifunc=syntaxcomplete#Complete |
        \	endif
endif

" Window movement shortcuts
" move to the window in the direction shown, or create a new window
function! WinMove(key)
    let t:curwin = winnr()
    exec "wincmd ".a:key
    if (t:curwin == winnr())
        if (match(a:key,'[jk]'))
            wincmd v
        else
            wincmd s
        endif
        exec "wincmd ".a:key
    endif
endfunction

"This allows you to run a command that will trim
"all whitespace off the end of every line and file.
fun! TrimWhitespace()
    let l:save = winsaveview()
    %s/\s\+$//e
    call winrestview(l:save)
endfun
command! TrimWhitespace call TrimWhitespace()

"run the command to compare buffer with original file
"to end this command type 'windo diffoff'
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

function! VimuxSlime()
    call VimuxSendText("clear")
    call VimuxSendKeys("Enter")
    call VimuxSendText(@v)
endfunction

function! VimuxPython()
    let a:file = "%run " . expand("%:p")
    if &filetype != "python"
        echom "Not a python file!"
        return
    endif
    write
    call VimuxOpenRunner()
    call VimuxSendText("clear")
    call VimuxSendKeys("Enter")
    call VimuxSendText( a:file )
    call VimuxSendKeys("Enter")
endfunction

function! s:align()
  let p = '^\s*|\s.*\s|\s*$'
  if exists(':Tabularize') && getline('.') =~# '^\s*|' && (getline(line('.')-1) =~# p || getline(line('.')+1) =~# p)
    let column = strlen(substitute(getline('.')[0:col('.')],'[^|]','','g'))
    let position = strlen(matchstr(getline('.')[0:col('.')],'.*|\s*\zs.*'))
    Tabularize/|/l1
    normal! 0
    call search(repeat('[^|]*|',column).'\s\{-\}'.repeat('.',position),'ce',line('.'))
  endif
endfunction


" If text is selected, save it in the v buffer and send that buffer it to tmux
" nmap <F3> :call VimuxPython()<CR>
" vmap <Leader>vs "vy :call VimuxSlime()<CR>

" Select current paragraph and send it to tmux
" nmap <Leader>vs vip<LocalLeader>vs<CR>

"every time a | is inserted while in insertmode Tabularize will autoformat the
"width
"}}}
"Autogroups {{{

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end
" per the SimplyFold documentation
" autocmd BufWinEnter *.py setlocal foldexpr=SimpylFold(v:lnum) foldmethod=expr
" autocmd BufWinLeave *.py setlocal foldexpr< foldmethod<
"
" helps syntax_highlighting on large files - see https://stackoverflow.com/questions/27235102/vim-randomly-breaks-syntax-highlighting
autocmd BufEnter * syntax sync fromstart

" resource vim when reloaded
augroup reload_vimrc " {
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC | AirlineRefresh
augroup END " }

" if NERDTree is the only window open when you want to close Vim this will help
" autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

"}}}
"Backups {{{

set writebackup
set backup
set backupdir=~/.vim/_backup  " store backups here
set directory=~/.vim/_swaps   " store swap files here

"}}}

" PLUGINS
"Conquer of Completion{{{
" Highlight documentation
let g:markdown_fenced_languages = ['css', 'javascript', 'js=javascript', 'typescript']
"}}}
"Airline {{{
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#virtualenv#enabled = 1
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#obsession#enabled = 1
let g:airline#extensions#obsession#indicator_text = '●'
let g:airline#extensions#ycm#enabled = 1
let g:airline#extensions#tagbar#enabled = 1

let g:airline_left_sep=''
let g:airline_right_sep=''
let g:airline_theme='base16_ashes'
let g:airline_powerline_fonts = 1

"}}}
"CtrlP {{{

"  include dotfiles and dotdirs in search
" let g:ctrlp_show_hidden = 1
let g:ctrlp_custom_ignore = '\v[\/](node_modules|target|dist)|(\.(swp|ico|git|svn))$'

"Set the directory to store the cache files: >
"let g:ctrlp_cache_dir = $HOME.'/.cache/ctrlp'

" make CtrlP start in buffer mode
let g:ctrlp_cmd = 'CtrlPBuffer'
let g:ctrlp_match_window = 'bottom,order:ttb'
"order results 

let g:ctrlp_switch_buffer = 0
" always open file in a new buffers

let g:ctrlp_working_path_mode = 0
"lets us change working directory and 
"ctrlp respects that change during a 
"vim session.

"}}}
"NERDTree{{{

function! IsNERDTreeOpen()
 return exists("t:NERDTreeBuffName") && (bufwinnr(t:NERDTreeBuffName) != -1)
endfunction

"Call NERDTreeFind if NERDTree is active, current window contains a modifiable
"file, and we're not in vimdiff
function! SyncTree()
    if &modifiable && IsNERDTreeOpen() && strlen(expand('%')) > 0 && !&diff
        NERDTreeFind 
        wincmd p
    endif
endfunction

" Highlight currently open buffer in NERDTree
autocmd BufEnter * call SyncTree()

let g:NERDTreeWinSize=50
let g:NERDTreeHighlightFolders = 0 " enables folder icon highlighting using exact match
let g:NERDTreeHighlightFoldersFullName = 0 " highlights the folder name
let s:grey =  "#DCDCDC"
let g:NERDTreeExtensionHighlightColor = {} " this line is needed to avoid error
let g:NERDTreeExtensionHighlightColor['json'] = s:grey " sets the color of css files to blue
"}}}
"Devicons {{{

let g:WebDevIconsUnicodeDecorateFolderNodes=1
" this will make folder icons in NERDTree

let g:WebDevIconsNerdTreeGitPluginForceVAlign = 1

if exists("g:loaded_webdevicons")
    call webdevicons#refresh()
endif
" This will help refresh devicons when you source .vimrc

"}}}
"Easy Motion {{{
let g:sneak#label = 1
let g:EasyMotion_smartcase = 1
"}}}
"CocVim{{{
let g:coc_global_extensions = ['coc-json', 'coc-git', 'coc-tsserver', 'coc-symbol-line', 'coc-svg', 'coc-snippets',
\'coc-sh', 'coc-prettier', 'coc-html', 'coc-css', 'coc-eslint', 'coc-docker', 'coc-cssmodules', 'coc-angular', 'coc-calc',
\'coc-markdownlint', 'coc-sql', 'coc-yaml', 'coc-symbol-line']

" }}}
"Ultisnips{{{
let g:UltiSnipsEnableSnipMate = 0
"this won't check 'snippet' directories
"
let g:UltiSnipsSnippetDirectories=["UltiSnips", "MySnips"]
"only check search directories with these names to 
"find snippets
"
let g:UltiSnipsSnippetsDir = "~/.vim/MySnips"
"define where personal snippets are stored
let g:UltiSnipsListSnippets        = "<C-l>"
let g:UltiSnipsExpandTrigger       = "<C-j>"
let g:UltiSnipsJumpForwardTrigger  = "<C-j>"
let g:UltiSnipsJumpBackwardTrigger = "<C-k>"

" }}}
" SuperTab {{{

" let g:SuperTabDefaultCompletetype= context"
" let g:SuperTabContextDefaultCompletionType ="<C-o>"
" }}}
" Golden Ratio {{{

" disable when autocommands are called
let g:golden_ratio_autocommand = 0

"disables plugin on nonmodifiable windows
" let g:golden_ratio_exclude_nonmodifiable = 1

" }}}
"Plug{{{
    let g:plug_timeout = 1000
    "60 seconds is default but more is needed for YCM
"}}}

" PLUGINS - LANGUAGE SPECIFIC
" Python {{{
    " Simply Fold{{{

    " https://github.com/tmhedberg/SimpylFold

    let g:SimpylFold_docstring_preview = 1
    "allows you to view doctring in fold

    let g:SimpylFold_fold_import = 0
    " don't fold imports
    " }}}

" }}}
" Markdown {{{



" }}}
" Typescript{{{

" }}}

" vim:foldmethod=marker:foldlevel=0
