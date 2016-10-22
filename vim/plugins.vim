call plug#begin('~/.vim/plugged')

Plug 'chriskempson/base16-vim'
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] } | Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'benmills/vimux' " tmux integration for vim
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-ragtag' " endings for html, xml, etc. - ehances surround
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-obsession'
Plug 'jiangmiao/auto-pairs' " automatic closing of quotes, parenthesis, brackets, etc.
Plug 'Valloric/YouCompleteMe'
Plug 'scrooloose/syntastic'
Plug 'majutsushi/tagbar' " enables a list of current ctags
Plug 'ervandew/supertab' "makes tab work better with YCM and Ultisnips
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'godlygeek/tabular'
Plug 'easymotion/vim-easymotion'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'roman/golden-ratio'
Plug 'jlanzarotta/bufexplorer'
Plug 'ryanoasis/vim-devicons'

" Python
Plug 'hynek/vim-python-pep8-indent' "provides better tab behavior for python
Plug 'tmhedberg/SimpylFold' "provides better folding for python
Plug 'jmcantrell/vim-virtualenv'
call plug#end()
