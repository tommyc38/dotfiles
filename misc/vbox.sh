#!/bin/bash

# Setup virtual boxes for mac and linux automation testing

vagrant_boxes_root_default="$HOME/vagrant_boxes"
vagrant_boxes_root="${1:-"$vagrant_boxes_root_default"}"
ubuntu_20="$vagrant_boxes_root/ubuntu-focal-20.04"
ubuntu_18="$vagrant_boxes_root/ubuntu-bionic-18.02"
mac_big_sur="$vagrant_boxes_root/mac-big-sur-11.3"

if [ -x "$(which vagrant)" ] && [ -x "$(which virtualbox)" ]; then

    cd ~
    mkdir -p "$ubuntu_20"
    cd $ubuntu_20
    vagrant init ubuntu/focal64

    cd ~
    mkdir -p "$ubuntu_18"
    cd $ubuntu_18
    vagrant init ubuntu/bionic64

    cd ~
    mkdir -p "$mac_big_sur"
    cd $mac_big_sur
    vagrant init tampham/automation-macos
fi
