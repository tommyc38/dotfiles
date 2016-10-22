#!/usr/bin/env sh

YCM="~/.vim/plugged/YouCompleteMe/install.py"
if [ -e $YCM ]; then
    echo "Running post-install YouCompleteMe hook..."
    sed -i '1s/python/python3/' $YCM
    python3 $YCM/install.py --clang-completer --omnisharp-completer --gocode-completer --tern-completer
else
    echo "YouCompleteMe did not install"
fi
