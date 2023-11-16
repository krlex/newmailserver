export CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export HOSTNAME
export IS_ON_DOCKER
export SSL_CA_Bundle_File
export SSL_Private_Key_File

function is_installed {
    is_installed=$(dpkg -l | grep $1 | wc -c)

    if [ $is_installed != "0" ]; then
        is_installed=1
    fi

   echo $is_installed
}

bash $CURRENT_DIR/event/before-install.sh

if [ $(is_installed php) == 1 ]; then
	echo "PHP is already installed, installation aborted"; exit
elif [ $(is_installed nginx) == 1 ]; then
	echo "Nginx is already installed, installation aborted"; exit
elif [ $(is_installed postfix) == 1 ]; then
	echo "Postfix is already installed, installation aborted"; exit
elif [ $(is_installed dovecot) == 1 ]; then
	echo "Dovecot is already installed, installation aborted"; exit
elif [ $(is_installed mysql) == 1 ]; then
	echo "MySQL is already installed, installation aborted"; exit
elif [ $(is_installed spamassassin) == 1 ]; then
	echo "SpamAssassin is already installed, installation aborted"; exit
fi

read -p "Type hostname: " HOSTNAME
read -s -p "Type admin's email password: " PASSWORD && echo -e  
read -e -p "Do you want to install your own ssl certificates? [n/Y] " SSL_INSTALL_OWN 

if [ "$SSL_INSTALL_OWN" == "n"  ] || [ "$SSL_INSTALL_OWN" == "N"  ]; then
	#by default use dovecot's self-signed certificate
	SSL_CA_Bundle_File=/etc/dovecot/dovecot.pem
	SSL_Private_Key_File=/etc/dovecot/private/dovecot.pem
else
	while [ ! -f "$SSL_CA_Bundle_File" ]; do
		read -p "[SSL] CA Bundle file path: " SSL_CA_Bundle_File
	done 

	while [ ! -f "$SSL_Private_Key_File" ]; do
		read -p "[SSL] Private key file path: " SSL_Private_Key_File
	done 
fi

read -e -p "Is this installation is on Docker? [N/y] " IS_ON_DOCKER

if [ "$IS_ON_DOCKER" == "y"  ] || [ "$IS_ON_DOCKER" == "Y"  ]; then
	IS_ON_DOCKER=true
else
	IS_ON_DOCKER=false
fi

function set_hostname {
	sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/g" $1
}
export -f set_hostname

function get_rand_password() {
	openssl rand  32 | md5sum | awk '{print $1;}'
}

export ADMIN_EMAIL="admin@$HOSTNAME"
export ADMIN_PASSWORD=$(openssl passwd -1 $PASSWORD)

export ROOT_MYSQL_USERNAME='root'
export ROOT_MYSQL_PASSWORD=$(get_rand_password)

export MYSQL_DATABASE='mailserver'
export MYSQL_HOSTNAME='127.0.0.1'
export MYSQL_USERNAME='mailuser'
export MYSQL_PASSWORD=$(get_rand_password)

export ROUNDCUBE_MYSQL_DATABASE='roundcube_dbname'
export ROUNDCUBE_MYSQL_USERNAME='roundcube_user'
export ROUNDCUBE_MYSQL_PASSWORD=$(get_rand_password)

apt-get update 

bash $CURRENT_DIR/mysql/install.sh
bash $CURRENT_DIR/postfix/install.sh
bash $CURRENT_DIR/dovecot/install.sh
touch /etc/dovecot/dovecot.pem
bash $CURRENT_DIR/roundcube/install.sh
bash $CURRENT_DIR/autoconfig/install.sh
bash $CURRENT_DIR/spamassassin/install.sh

echo "Root MySQL username: $ROOT_MYSQL_USERNAME | password: $ROOT_MYSQL_PASSWORD"
echo "Easymail MySQL db: $MYSQL_DATABASE | username: $MYSQL_USERNAME | password: $MYSQL_PASSWORD"
echo "Roundcube MySQL db: $ROUNDCUBE_MYSQL_DATABASE | username: $ROUNDCUBE_MYSQL_USERNAME | password: $ROUNDCUBE_MYSQL_PASSWORD"

echo "Installation has finished"
if [ $IS_ON_DOCKER == true ]; then 
	echo "After stop this docker container you must start this services manually:
==========
service mysql start
service nginx start
service php-fpm start
/etc/init.d/postfix start
/usr/sbin/dovecot
service spamassassin start
==========
	"
fi

#bash $CURRENT_DIR/event/after-install.sh

