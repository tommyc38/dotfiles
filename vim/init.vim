set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" Neovim Python Provider Configuration
" This points to a dedicated Python environment created by install/python.sh
" The environment is named 'nvim-provider' and includes the pynvim package
" required by Neovim plugins that use Python (e.g., deoplete, coc.nvim, etc.)
"
" Current Configuration: Python 3.13 in nvim-provider environment
"
" To change the Python version:
" 1. Edit install/python.sh to designate a different Python version for nvim-provider
" 2. Run install/python.sh to create the new environment
" 3. Update the path below if the environment name changes
" 4. Restart Neovim
"
" Verify the configuration in Neovim with: :checkhealth provider
let g:python3_host_prog = '~/.pyenv/versions/nvim-provider/bin/python'

" Source the file below to help with debugging
" source $DOTFILES/vim/minvim.vim
