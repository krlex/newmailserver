echo "Begin Mailjet configurator. "
echo "You can find you API and SECRET key at https://app.mailjet.com/account/setup"

MAILJET_APIKEY=""
MAILJET_SECRETKEY=""

MAILJET_WRONG_DATA_MSG=false
while [ ${#MAILJET_APIKEY} != 32 ]; do
	if [ $MAILJET_WRONG_DATA_MSG == true ]; then
		echo "Not valid API key try again."
	fi
	MAILJET_WRONG_DATA_MSG=true;
	read -p "Please insert you API key: " MAILJET_APIKEY
done
	
MAILJET_WRONG_DATA_MSG=false
while [ ${#MAILJET_SECRETKEY} != 32 ]; do
	if [ $MAILJET_WRONG_DATA_MSG == true ]; then
		echo "Not valid SECRET key try again."
	fi
	MAILJET_WRONG_DATA_MSG=true;
	read -p "Please insert you SECRET key: " MAILJET_SECRETKEY
done

cd /etc/postfix/
cp main.cf main.cf_backup_before_mailjet_configurator
sed -i "s/relayhost =.*/relayhost = in-v3.mailjet.com/" main.cf
echo "
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
" >> main.cf
echo "in-v3.mailjet.com $MAILJET_APIKEY:$MAILJET_SECRETKEY" > /etc/postfix/sasl_passwd
chown root:root sasl_passwd
chmod 600 sasl_passwd
postmap sasl_passwd && postfix reload
