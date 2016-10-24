#!/usr/bin/env bash

# ================================================================== #
# Ubuntu 10.04 web server build shell script
# ================================================================== #
# Parts copyright (c) 2012 Matt Thomas http://betweenbrain.com
# This script is licensed under GNU GPL version 2.0 or above
# ================================================================== #
#
#
#
# ================================================================== #
#          Define system specific details in this section            #
# ================================================================== #
#
SYSTEMIP=
USER="tconley"
APP="blog"
PUBLICKEY="ssh-rsa ... foo@bar.com"
# ================================================================== #
#                      End system specific details                   #
# ================================================================== #
#
echo
echo "System updates and basic setup"
echo "==============================================================="
echo
echo
echo
echo "First things first, let's make sure we have the latest updates."
echo "---------------------------------------------------------------"
#
apt-get update && apt-get upgrade
#
echo
#
# ================================================================== #
#                             SSH Security                           #
#      https://help.ubuntu.com/community/SSH/OpenSSH/Configuring     #
# ================================================================== #
#
echo
echo
echo
echo "Disabling root ssh login"
echo "---------------------------------------------------------------"
#
sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
#
echo
echo
echo
echo "Disabling password authentication"
echo "---------------------------------------------------------------"
#
sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
#
echo
echo
echo
echo "Creating new primary user"
echo "---------------------------------------------------------------"
# -------------------------------------------------------------------------
# Script to add a user to Linux system
# -------------------------------------------------------------------------
# Copyright (c) 2007 nixCraft project <http://bash.cyberciti.biz/>
# This script is licensed under GNU GPL version 2.0 or above
# Comment/suggestion: <vivek at nixCraft DOT com>
# -------------------------------------------------------------------------
# See url for more info:
# http://www.cyberciti.biz/tips/howto-write-shell-script-to-add-user.html
# -------------------------------------------------------------------------
if [ $(id -u) -eq 0 ]; then
	# read -p "Enter username of who can connect via SSH: " USER
	read -s -p "Enter password of user who can connect via SSH: " PASSWORD
	egrep "^$USER" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$USER exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $PASSWORD)
		useradd -s /bin/bash -m -d /home/$USER -U -p $pass $USER
		[ $? -eq 0 ] && echo "$USER has been added to system!" || echo "Failed to add a $USER!"
	fi
else
	echo "Only root may add a user to the system"
	exit 2
fi
# -------------------------------------------------------------------------
# End script to add a user to Linux system
# -------------------------------------------------------------------------
#
echo
echo
echo
echo "Adding $USER to SSH AllowUsers"
echo "---------------------------------------------------------------"
#
echo "AllowUsers $USER" >> /etc/ssh/sshd_config
#
echo
echo
echo
echo "Adding $USER to sudoers"
echo "---------------------------------------------------------------"
#
cp /etc/sudoers /etc/sudoers.tmp
chmod 0640 /etc/sudoers.tmp
echo "$USER    ALL=(ALL) ALL" >> /etc/sudoers.tmp
chmod 0440 /etc/sudoers.tmp
mv /etc/sudoers.tmp /etc/sudoers
#
echo
echo
echo
echo "Adding ssh key"
echo "---------------------------------------------------------------"
#
mkdir /home/$USER/.ssh
touch /home/$USER/.ssh/authorized_keys
echo $PUBLICKEY >> /home/$USER/.ssh/authorized_keys
chown -R $USER:$USER /home/$USER/.ssh
chmod 700 /home/$USER/.ssh
chmod 600 /home/$USER/.ssh/authorized_keys

/etc/init.d/ssh restart
# ================================================================== #
#                     Install System Packages
# ================================================================== #
#
echo
echo "Installing packages"
echo "==============================================================="
echo
echo
apt-get install nginx
apt-get install zsh zsh-syntax-highlighting
apt-get install postgresql postgresql-contrib redis-server
apt-get install python3 python3-pip python3-dev
echo
# ================================================================== #
#                    Configure Project
# ================================================================== #
#
echo pip3 install virtualenv virtualenvwrapper
echo "Setting up project"
echo "---------------------------------------------------------------"
cd $HOME
mkdir ${APP} && cd ${APP}
virtualenv -p /usr/local/bin/python3 env
source env/bin/activate
echo "Setting up Python and dependencies"
echo "---------------------------------------------------------------"
pip install flask gunicorn redis flask-httpauth sqlalchemy ipython requests passlib psycopg2
pip freeze > requirments.txt
deactivate
echo
echo "Creating $APP.py file"
echo "---------------------------------------------------------------"

echo "from flask import Flask
application = Flask(__name__)

@application.route("/")
def hello():
    return \"<h1 style='color:blue'>Hello There!</h1>\"

if __name__ == \"__main__\":
    application.run(host='0.0.0.0')" > ${APP}.py
echo
echo "Creating gunicorn WSGI entry point"
echo "---------------------------------------------------------------"
echo
echo "from $APP import application

if name == \"__main__\":
    application.run()" > wsgi.py
echo
echo "Creating start up file in etc/init/"
echo "---------------------------------------------------------------"
echo
echo "description \"Gunicorn application server running myproject\"

start on runlevel [2345]
stop on runlevel [!2345]

respawn
setuid $USER
setgid www-data

env PATH=/home/$USER/$APP/env/bin
chdir /home/$USER/$APP
exec gunicorn --workers 3 --bind unix:$APP.sock -m 007 wsgi" > /etc/init/${APP}.conf
start $APP
echo
# ================================================================== #
#                    Configure Nginx
# ================================================================== #
#
echo "Configuring Nginx"
echo "---------------------------------------------------------------"
echo "server {
    listen 80;
    server_name $SYSTEMIP;

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/$USER/$APP/$APP.sock;
    }
}" > /etc/nginx/sites-available/${APP}

ln -s /etc/nginx/sites-available/${APP} /etc/nginx/sites-enabled

echo "Restarting Nginx"
echo "---------------------------------------------------------------"
service nginx restart
echo
# ================================================================== #
#                    Configure PostgreSQL
# ================================================================== #
#
echo "Configuring PostgreSQL"
echo "---------------------------------------------------------------"
echo
su postgres -c "createuser -d $USER"
su postgres -c "psql ALTER USER ${USER} WITH PASSWORD 'ckw2kids';"
su ${USER} -c "createbd"
su ${USER} -c "createbd ${APP}"

sed -i 's/listen_addresses ".*"/listen_addresses "\*"/g' /etc/postgresql/8.4/main/postgresql.conf
echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/8.4/main/pg_hba.conf
/etc/init.d/postgresql restart

