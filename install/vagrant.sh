#!/bin/bash

# DESCRIPTION
#   Installs VirtualBox, VirtualBox Extension Pack, and Vagrant.  It also creates a directory (~/vagrant_boxes) for
#   Vagrant projects which can overridden by passing a directory name as an argument. To install the packages without
#   creating Vagrant projects pass the --install-only option.

# bashsupport disable=BP5001
mac_vagrantfile='
ENV["VAGRANT_EXPERIMENTAL"] = "typed_triggers"

Vagrant.configure("2") do |config|
    config.vm.box = "amarcireau/macos"
    config.vm.box_version = "12.5"
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.provider "virtualbox" do |v|
        v.check_guest_additions = false
    end
    config.trigger.after :"VagrantPlugins::ProviderVirtualBox::Action::Import", type: :action do |t|
        t.ruby do |env, machine|
            FileUtils.cp(
                machine.box.directory.join("include").join("macOS.nvram").to_s,
                machine.provider.driver.execute_command(["showvminfo", machine.id, "--machinereadable"]).
                    split(/\n/).
                    map {|line| line.partition(/=/)}.
                    select {|partition| partition.first == "BIOS NVRAM File"}.
                    last.
                    last[1..-2]
            )
        end
    end
end
'

#######################################
# Create a Vagrant project.
# Arguments:
#   1 - directory - the root project directory
#   2 - box - the box associated with the project
#######################################
function create_project() {
  if [ -d "$1" ]; then
    echo "$1 already exists.  Skipping..."
    return 0
  fi

  mkdir -p "$1"
  cd "$1" || exit
  vagrant init "$2"
  if [ "$2" = "$mac_box" ]; then
    echo "$mac_vagrantfile" > "$1/Vagrantfile"
  fi
}

#######################################
# Install Vagrant, VirtualBox, and VirtualBox Extension Pack.
# Globals:
#   HOME - The user's home directory.
#   mac_box - The mac os box.
# Arguments:
#   1 - directory - The name of the root directory to store Vagrant projects in (default is $HOME/vagrant_boxes).
#######################################
function main() {
  local vagrant_project_root_default="$HOME/vagrant_boxes"
  local vagrant_project_root="${1:-"$vagrant_project_root_default"}"
  local install_only=
  while getopts "id::" arg; do
    case $arg in
      -d) vagrant_project_root="$arg" ;;
      -i) install_only="true";;
    esac
  done

  # MacOS Monterey (12.5). See docs at https://app.vagrantup.com/amarcireau/boxes/macos
  local mac_box="amarcireau/macos"
  local mac_box_project_dir="mac-monterey-12.5"

  if [[ "$(uname)" == "Darwin" ]]; then

    if [ ! -x "$(which brew)" ]; then
      echo "Homebrew needs to be installed to run this script."
      exit 1
    fi

    # Install packages
    [ ! -x "$(which virtualbox)" ] && brew install --cask virtualbox
    [ ! -x "$(which vagrant)" ] && brew install --cask vagrant

    # Install virtualbox extension pack needed for mac
    cd "$vagrant_project_root" || exit

    # See https://www.virtualbox.org/wiki/Downloads for the latest version and update the download URL.
    local extension_pack_url="https://download.virtualbox.org/virtualbox/7.0.8/Oracle_VM_VirtualBox_Extension_Pack-7.0.8-156879.vbox-extpack"
    if [ ! -e "$vagrant_project_root/$(basename "$extension_pack_url")" ]; then
      curl -o "$(basename $extension_pack_url)" "$extension_pack_url"
      VBoxManage extpack install --replace "$(basename "$extension_pack_url")"
    fi

    # Check if the --install option was passed to the script.
    if [ "$1" != "--install-only" ] && [ "$2" != "--install-only" ]; then
      create_project "$vagrant_project_root/ubuntu-focal-20.04" "ubuntu/focal64"
      create_project "$vagrant_project_root/ubuntu-bionic-18.02" "ubuntu/bionic64"
#      create_project "$vagrant_project_root/mac-monterey-12.5" "$mac_box"
      create_project "$vagrant_project_root/windows-10" "gusztavvargadr/windows-10"
      create_project "$vagrant_project_root/mac-monterey" "jrl/macos-monterey"
    fi
  fi
}

main "$@"
