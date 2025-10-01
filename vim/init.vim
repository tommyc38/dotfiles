set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
" This is needed by neovim plugins.  See python script which creates this env
let g:python3_host_prog = '~/.pyenv/versions/nvim-provider/bin/python'

" Source the file below to help with debuging
" source $DOTFILES/vim/minvim.vim
