"Installs Plug if its not already installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

"Themeing{{{

" Plug 'doums/darcula'
Plug 'airblade/vim-gitgutter'
Plug '~/.vim/plugged/custom-plugins/darcula'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'chriskempson/base16-vim'
Plug 'ryanoasis/vim-devicons'
Plug 'morhetz/gruvbox'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'gerw/vim-HiLinkTrace'
"}}}
"Code Completion / Linting / Snippets / Ctags{{{
if has('nvim')
    Plug 'beeender/Comrade'
endif
Plug 'neoclide/coc.nvim'
Plug 'honza/vim-snippets'

"}}}
"Navigation{{{

Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] } | Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'jlanzarotta/bufexplorer'
Plug 'ctrlpvim/ctrlp.vim'

"}}}
"User Interface{{{
Plug 'liuchengxu/vista.vim'
Plug 'kshenoy/vim-signature' " make marks visible in the column bar (https://github.com/kshenoy/vim-signature)
Plug 'rrethy/vim-hexokinase', { 'do': 'make hexokinase' } " shows color boxes in gutter

"}}}
"Editing / General Functionality{{{

Plug 'roman/golden-ratio'
Plug 'godlygeek/tabular'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-ragtag' " endings for html, xml, etc. - ehances surround
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-fugitive' "git support
Plug 'tpope/vim-surround' "create vim sessions
Plug 'tpope/vim-obsession'

"}}}
"
"Language Specific
"Typescript{{{

Plug 'HerringtonDarkholme/yats.vim'
" Plug 'leafgarland/typescript-vim' "provides better tab behavior for python
" Plug 'sheerun/vim-polyglot'

"}}}
"Python{{{

    Plug 'hynek/vim-python-pep8-indent' "provides better tab behavior for python
    Plug 'tmhedberg/SimpylFold' "provides better folding for python
    Plug 'jmcantrell/vim-virtualenv'

"}}}
"
"Misc{{{

Plug 'benmills/vimux' " tmux integration for vim

"}}}

call plug#end()

" vim:foldmethod=marker:foldlevel=0
