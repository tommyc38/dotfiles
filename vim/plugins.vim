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

"}}}
"Code Completion / Linting / Snippets{{{
"
Plug 'neoclide/coc.nvim' "code completion
Plug 'honza/vim-snippets'
Plug 'ervandew/supertab' "makes tab work better with YCM and Ultisnips

"If neovim gives unltisnip erros see  
"https://www.reddit.com/r/neovim/comments/gbb2g3/wierd_vimplug_error_messages/g3n3vtl/
" Plug 'SirVer/ultisnips'
" Plug 'beeender/Comrade'
" Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" Plug 'Valloric/YouCompleteMe'
" Plug 'scrooloose/syntastic'

"}}}
"Navigation{{{

Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] } | Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'easymotion/vim-easymotion'
Plug 'jlanzarotta/bufexplorer'
Plug 'ctrlpvim/ctrlp.vim'

"}}}
"User Interface{{{

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
"Language Specific{{{

    "Python{{{

    Plug 'hynek/vim-python-pep8-indent' "provides better tab behavior for python
    Plug 'tmhedberg/SimpylFold' "provides better folding for python
    Plug 'jmcantrell/vim-virtualenv'

    "}}}

"}}}
"Misc{{{

Plug 'benmills/vimux' " tmux integration for vim
Plug 'majutsushi/tagbar' " enables a list of current ctags

"}}}

call plug#end()

" vim:foldmethod=marker:foldlevel=0
