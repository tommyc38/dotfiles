#!/bin/bash

if [ $(which virtualbox) ];then
    pass
fi
if [$(which vagrant)]; then
    cd ~
    mkdir ubuntu_box
    cd ~/ubuntu_box
    vagrant init
    vagrant box add ubuntu/trusty64

    cd ~
    mkdir osx_box
    cd ~/osx_box
    vagrant init
    vagrant box add jhcook/osx-elcapitan-10.11
fi
