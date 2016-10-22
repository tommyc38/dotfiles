#!/bin/bash
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
mkvirtualenv py2
workon py2
if test $VIRTUAL_ENV; then
    pip install --upgrade setuptools
    pip install --upgrade pip
    pip install flake8
    pip install requests
    pip install jinja2
    pip install flask
    pip install scrapy
    pip install beautifulsoup
    pip install ipython
else
    echo "py2 virtualenv not setup!"
fi
deactivate
echo "Setting up python3 virtualenvs..."
mkvirtualenv py3
workon py3
if test $VIRTUAL_ENV; then
    pip install --upgrade setuptools
    pip install --upgrade pip
    pip install flake8
    pip install requests
    pip install jinja2
    pip install flask
    pip install scrapy
    pip install beautifulsoup
    pip install ipython
else
    echo "py3 virtualenv not setup!"
fi
deactivate
exit
