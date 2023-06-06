<a name="readme-top"></a>

## Table of Contents

<ol>
  <li>
    <a href="#about-the-project">About The Project</a>
  </li>
  <li>
    <a href="#getting-started">Getting Started</a>
    <ul>
      <li><a href="#prerequisites">Prerequisites</a></li>
      <li><a href="#setup">Setup a New Machine</a></li>
      <li><a href="#post-setup">Post Setup</a></li>
    </ul>
  </li>
  <li><a href="#config-files">Sym-linking Configuration Files</a></li>
  <li>
    <a href="#ides">IDEs</a>
    <ul>
      <li><a href="#vim">Vim</a></li>
      <li><a href="#webstorm">Webstorm</a></li>
      <li><a href="#visual-studio">Visual Studio</a></li>
    </ul>
  </li>
  <li><a href="#virtualbox">VirtualBox and Vagrant</a></li>
  <li><a href="#fonts">Fonts</a></li>
  <li>
    <a href="#shells">Operating Systems</a>
    <ul>
      <li><a href="#vim">MacOS</a></li>
      <li><a href="#vim">Ubuntu</a></li>
    </ul>
  </li>
  <li><a href="#karabiner">Karabiner</a></li>
  <li>
    <a href="#shells">Shells</a>
    <ul>
      <li><a href="#zsh">Zsh</a></li>
      <li><a href="#bash">Bash</a></li>
    </ul>
  </li>
  <li>
    <a href="#contributing">Contributing</a>
    <ul>
      <li><a href="#coding-rules">Coding Rules</a></li>
      <li><a href="#node-npm">Node & NPM</a></li>
      <li><a href="#secondary-entrypoints">Secondary Entrypoints</a></li>
      <li><a href="#standalong-components">Standalone Components</a></li>
      <li><a href="#versioning">Versioning</a></li>
      <li><a href="#example">Example</a></li>
    </ul>
  </li>
</ol>

## About The Project <a name="about-the-project">#</a>

Unless you are constantly setting up new computers for development, it can often be a frustrating task.
The goal of this repo is to automate that process and serve as an easy way to remember small steps that would otherwise
likely be forgotten.  Moreover, there are also scripts that can help you whether it's ssh'ing into a new machine and
quickly setting up vim or installing fonts into a docker image, there are lots of tools to help. 

<p align="right">(<a href="#readme-top">back to top</a>)</p>
<!-- GETTING STARTED -->

## Getting Started <a name="getting-started">#</a>

This guide explains how to set up your Angular project to begin using ng-material-plus. It includes information on
prerequisites, installation, and optionally displaying a sample component in your application to
verify your setup.

### Prerequisites <a name="prerequisites">#</a>

#### MacOs

Install Xcode from https://developer.apple.com/xcode/.  The app store doesn't work well and you can't install it from brew.

Update Urls

- install/brew.sh
    - nvm - ensure the link is pointing to the most recent version
- misc/vbox.sh
    - virtualbox extension pack - ensure the link is pointing to the most recent version

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Setup a New Machine <a name="setup">#</a>

1. Clone the repository into your home folder.
    ```sh
    cd $HOME
    git clone https://github.com/tommyc38/dotfiles.git
    ```
2. There are a few scripts that may contain outdated packages. Notes are in the scripts below with links.
   Follow the links and check for the most recent versions and update the scripts with the latest package download URLs.
    - install/brew.sh
        - nvm
    - install/vagrant.sh
        - virtualbox extension pack
   - install/fonts.sh
       - nerd fonts url

### Post Setup <a name="setup">#</a>

#### MacOS
In order to run `bin/vault` you will need to give full access to whatever programs you may use to run it
- Examples: Terminal, Webstorm, iTerm, Visual Studio Code, etc.

Moreover, to finish the install we need to symlink our decrypted vault files to the home directory.

1. Go into Settings/Privacy.
2. Click Developer Tools on the left pane.
3. Add your apps.
4. Open your terminal and run: `vault`
5. Input your encryption/decryption password (1 for each file)
6. Now symlink the contents

> If you don't adjust these settings you will get a popup telling you to move the app to the trash and it won't execute.

#### Webstorm

Once Webstorm is installed you will need to sync your settings from the cloud and install the command line executable
to be able to run commands:
- Open a file: `webstorm file.txt`
- Launch a project: `open -na Webstorm.app projectDir`


- [Get settings from account](https://www.jetbrains.com/help/webstorm/sharing-your-ide-settings.html#IDE_settings_sync)
- [Install Command-line Interface](https://www.jetbrains.com/help/webstorm/working-with-the-ide-features-from-command-line.html)

## Sym-linking Configuration Files <a name="config-files">#</a>

The `symlink.sh` script will symlink all configuration files to their respective target directories in a non-destructive
way. If it finds matching files at the symlink target location, it will move those files to a backup directory. To see what file
operations will be made without file execution pass the -d|--dry-run option. To include vim pass the -v|--include-vim
option.  To include karabiner pass the -k|--include-karabiner option.  For more details and options
run: `symlink.sh --help`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## IDEs <a name="ides">#</a>

This guide explains how to set up your Angular project to begin using ng-material-plus. It includes information on
prerequisites, installation, and optionally displaying a sample component in your application to
verify your setup.

### Vim <a name="vim">#</a>
See https://www.virtualbox.org/wiki/Downloads for latest version
local extension_pack_url="https://download.virtualbox.org/virtualbox/7.0.6/Oracle_VM_VirtualBox_Extension_Pack-7.0.6a-155176.vbox-extpack"


<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Webstorm <a name="webstorm">#</a>

1. Install ng-material-plus along w
   ```sh
   npm install @gotomconley/ng-material-plus
   ```

### Visual Studio <a name="visual-studio">#</a>

Settings
https://code.visualstudio.com/docs/getstarted/settings#_settingsjson

Settings file locations
Depending on your platform, the user settings file is located here:

- Windows %APPDATA%\Code\User\settings.json
- macOS $HOME/Library/Application\ Support/Code/User/settings.json
- Linux $HOME/.config/Code/User/settings.json

Sync Settings
https://code.visualstudio.com/docs/editor/settings-sync

## Vagrant and VirtualBox

## Testing Scripts
