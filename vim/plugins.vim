"Installs Plug if its not already installed
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

"Themeing{{{

" Plug 'doums/darcula'
Plug '~/.vim/plugged/custom-plugins/darcula'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'chriskempson/base16-vim'
Plug 'ryanoasis/vim-devicons'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'morhetz/gruvbox'
Plug 'https://github.com/tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'gerw/vim-HiLinkTrace'
"}}}
"Code Completion / Linting / Snippets / Ctags{{{
Plug 'beeender/Comrade'
Plug 'neoclide/coc.nvim'
Plug 'honza/vim-snippets'

"}}}
"Navigation{{{

Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] } | Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'jlanzarotta/bufexplorer'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'justinmk/vim-sneak'

"}}}
"User Interface{{{
Plug 'liuchengxu/vista.vim'
" Plug 'majutsushi/tagbar' " enables a list of current ctags
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
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-obsession'

"}}}
"
"Language Specific
"Typescript{{{

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
