#!/bin/bash

if [ $(which virtualbox) ];then
    pass
fi
if [$(which vagrant)]; then
    cd ~
    mkdir ubuntu_box
    cd ~/ubuntu_box
    vagrant init hashicorp/bionic64

    cd ~
    mkdir osx_box
    cd ~/osx_box
    vagrant init AndrewDryga/vagrant-box-osx
fi
