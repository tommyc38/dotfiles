#!/bin/bash
# THIS FILE IS OLD - NEED TO UPDATE NEXTIME YOU WORK WITH PYTHON
if [ ! "$(which python2)" ] && [ ! "$(which python3)" ]; then
    echo "You need to brew install python2 and python 3"
    exit
fi
if [ ! "$(which virtualenvwrapper.sh)" ]; then
    echo "You need to pip install virtualenv and virtualenvwrapper"
    exit
fi

source $(which virtualenvwrapper.sh)

echo "Creating virtualenv directory"
if [ -e ~/.virtualenvs ];then
    echo "Found ~.virtualenvs folder.  Installing virtualenvs to it..."
else
    mkdir ~/.virtualenvs
fi

echo "Setting up python2 virtualenvs..."
mkvirtualenv -p /usr/local/bin/python2 py2
workon py2
if test $VIRTUAL_ENV; then
    pip2 install --upgrade setuptools
    pip2 install --upgrade pip
    pip2 install flake8
    pip2 install requests
    pip2 install jinja2
    pip2 install flask
    pip2 install scrapy
    pip2 install beautifulsoup
    pip2 install ipython
else
    echo "py2 virtualenv not setup!"
fi
deactivate
echo "Setting up python3 virtualenvs..."
mkvirtualenv -p /usr/local/bin/python3 py3
workon py3
if test $VIRTUAL_ENV; then
    pip3 install --upgrade setuptools
    pip3 install --upgrade pip
    pip3 install flake8
    pip3 install requests
    pip3 install jinja2
    pip3 install flask
    pip3 install scrapy
    pip3 install beautifulsoup
    pip3 install ipython
else
    echo "py3 virtualenv not setup!"
fi
deactivate
exit
