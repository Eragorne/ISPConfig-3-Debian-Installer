﻿#!/bin/bash

###############################################################################################
# Complete ISPConfig setup script for Debian 7.         						 			  #
# Drew Clardy																				  #
# http://drewclardy.com							                                              #
###############################################################################################

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

clear
echo "================================================================================"
echo "ISPConfig 3 Setup Script,  Written by Drew Clardy with help from other scripts!"
echo "================================================================================"
echo "A tool to auto-install ISPConfig and its dependencies "
echo "Script is using the DotDeb repo for updated packages"
echo "================================================================================"
echo "Please have Server IP and Hostname Ready!"
echo "Press ENTER to continue.."
read DUMMY

if [ "$1" != "--help" ]; then

#set Server IP

    serverIP="123.156.78.9"
    echo "Please input the Server IP:"
    read -p "(Default Server IP: 123.456.78.9):" serverIP
    if [ "$serverIP" = "" ]; then
        serverIP="123.456.78.9"
    fi
    echo "==========================="
    echo "serverIP=$serverIP"
    echo "==========================="

#set Hostname

    HOSTNAME="server1"
    echo "Please input the Hostname:"
    read -p "(Default Hostname: server1):" HOSTNAME
    if [ "$HOSTNAME" = "" ]; then
        HOSTNAME="server1"
    fi
    echo "==========================="
    echo "HOSTNAME=$HOSTNAME"
    echo "==========================="

#set Fully Qualified Hostname

    HOSTNAMEFQDN="server1.example.com"
    echo "Please input the Full Hostname:"
    read -p "(Default Full Hostname: server1.example.com):" HOSTNAMEFQDN
    if [ "$HOSTNAMEFQDN" = "" ]; then
        HOSTNAMEFQDN="server1.example.com"
    fi
    echo "==========================="
    echo "HOSTNAMEFQDN=$HOSTNAMEFQDN"
    echo "==========================="

#set Web Server

    web_server="Apache"
	echo "Please select Web Server (Apache or NginX):"
	read -p "(Default Web Server: Apache):" web_server
    if [ "$web_server" = "" ]; then
    	web_server="Apache"
    fi
    echo "==========================="
    echo "web_server=$web_server"
    echo "==========================="
	
#set Mail Server

    mail_server="Courier"
    echo "Please select Mail Server (Courier or Dovecot):"
    read -p "(Default Mail Server: Courier):" mail_server
    if [ "$mail_server" = "" ]; then
        mail_server="Courier"
    fi
    echo "==========================="
    echo "mail_server=$mail_server"
    echo "==========================="

#set mysql root password

    MYSQL_ROOT_PASSWORD="123456789"
    echo "Please input the root password of mysql:"
    read -p "(Default password: 123456789):" MYSQL_ROOT_PASSWORD
    if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
        MYSQL_ROOT_PASSWORD="123456789"
    fi
    echo "==========================="
    echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD"
    echo "==========================="

#set Quota
    quota="Yes"
    echo "Please select whether to install Quota or Not:"
    read -p "(Default: No):" quota
    if [ "$quota" = "" ]; then
        quota="No"
    fi
    echo "==========================="
    echo "quota=$quota"
    echo "==========================="
    
#set Mailman
    mailman="Yes"
    echo "Please select whether to install Mailman or Not:"
    read -p "(Default: No):" mailman
    if [ "$mailman" = "" ]; then
        mailmam="No"
    fi
    echo "==========================="
    echo "mailman=$mailman"
    echo "==========================="
    
#set Jailkit
    jailkit="Yes"
    echo "Please select whether to install Jailkit or Not:"
    read -p "(Default: No):" jailkit
    if [ "$jailkit" = "" ]; then
        jailkit="No"
    fi
    echo "==========================="
    echo "jailkit=$jailkit"
    echo "==========================="

set Mail Client
    web_mail="SquirrelMail"
    echo "Please select which Web Mail Client to install (SquirrelMail or RoundCube):"
    read -p "(Default Web Mail Client: SquirrelMail):" web_mail
    if [ "$web_mail" = "" ]; then
        web_mail="SquirrelMail"
    fi
    echo "==========================="
    echo "web_mail=$web_mail"
    echo "==========================="
    
fi

###DEBIAN Functions Begin### 

debian_install_basic (){

#Set hostname and FQDN
sed -i "s/${serverIP}.*/${serverIP} ${HOSTNAMEFQDN} ${HOSTNAME}/" /etc/hosts
echo "$HOSTNAME" > /etc/hostname
/etc/init.d/hostname.sh start >/dev/null 2>&1

#Updates server and install commonly used utilities
cp /etc/apt/sources.list /etc/apt/sources.list.backup
cat > /etc/apt/sources.list <<EOF
deb http://ftp.de.debian.org/debian/ wheezy main contrib non-free
deb-src http://ftp.de.debian.org/debian/ wheezy main contrib non-free

deb http://security.debian.org/ wheezy/updates main contrib non-free
deb-src http://security.debian.org/ wheezy/updates main contrib non-free

# wheezy-updates, previously known as 'volatile'
deb http://ftp.de.debian.org/debian/ wheezy-updates main contrib non-free
deb-src http://ftp.de.debian.org/debian/ wheezy-updates main contrib non-free

# DotDeb
deb http://packages.dotdeb.org wheezy all
deb-src http://packages.dotdeb.org wheezy all
EOF

wget http://www.dotdeb.org/dotdeb.gpg
cat dotdeb.gpg | apt-key add -
apt-get update
apt-get -y upgrade
apt-get -y install vim-nox dnsutils unzip 

} #end function debian_install_basic

debian_install_DashNTP (){

echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1

#Synchronize the System Clock
apt-get -y install ntp ntpdate

} #end function debian_install_DashNTP

debian_install_MYSQLCourier (){

#Install Postfix, Courier, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections
echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections
echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections

apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server courier-authdaemon courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql openssl courier-maildrop getmail4 rkhunter binutils sudo

#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
sed -i 's/bind-address           = 127.0.0.1/#bind-address           = 127.0.0.1/' /etc/mysql/my.cnf
/etc/init.d/mysql restart

#Delete and Reconfigure SSL Certificates
cd /etc/courier
rm -f /etc/courier/imapd.pem
rm -f /etc/courier/pop3d.pem
sed -i "s/CN=localhost/CN=${HOSTNAMEFQDN}/" /etc/courier/imapd.cnf
sed -i "s/CN=localhost/CN=${HOSTNAMEFQDN}/" /etc/courier/pop3d.cnf
mkimapdcert
mkpop3dcert
/etc/init.d/courier-imap-ssl restart
/etc/init.d/courier-pop-ssl restart

}

debian_install_MYSQLDovecot (){

#Install Postfix, Dovecot, Saslauthd, MySQL, phpMyAdmin, rkhunter, binutils
echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections

apt-get -y install postfix postfix-mysql postfix-doc mysql-client mysql-server openssl getmail4 rkhunter binutils dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve sudo 

#Uncommenting some Postfix configuration files
cp /etc/postfix/master.cf /etc/postfix/master.cf.backup
sed -i 's|#submission inet n       -       -       -       -       smtpd|submission inet n       -       -       -       -       smtpd|' /etc/postfix/master.cf
sed -i 's|#  -o syslog_name=postfix/submission|  -o syslog_name=postfix/submission|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_tls_security_level=encrypt|  -o smtpd_tls_security_level=encrypt|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|  -o smtpd_client_restrictions=permit_sasl_authenticated,reject|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_sasl_auth_enable=yes|  -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|#smtps     inet  n       -       -       -       -       smtpd|smtps     inet  n       -       -       -       -       smtpd|' /etc/postfix/master.cf
sed -i 's|#  -o syslog_name=postfix/smtps|  -o syslog_name=postfix/smtps|' /etc/postfix/master.cf
sed -i 's|#  -o smtpd_tls_wrappermode=yes|  -o smtpd_tls_wrappermode=yes|' /etc/postfix/master.cf

#Allow MySQL to listen on all interfaces
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.backup
sed -i 's|bind-address           = 127.0.0.1|#bind-address           = 127.0.0.1|' /etc/mysql/my.cnf

/etc/init.d/postfix restart
/etc/init.d/mysql restart

}

debian_install_Virus (){

#Install Amavisd-new, SpamAssassin, And Clamav
apt-get -y install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl

/etc/init.d/spamassassin stop
update-rc.d -f spamassassin remove

}

debian_install_Apache (){

#Install Apache2, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
#PhpMyAdmin Selections Not Working
#echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
#echo "dbconfig-common dbconfig-common/dbconfig-install boolean false" | debconf-set-selections

apt-get -y install apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libapache2-mod-suphp libruby libapache2-mod-ruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached

a2enmod suexec rewrite ssl actions include
a2enmod dav_fs dav auth_digest

#Fix SuPHP
cp /etc/apache2/mods-available/suphp.conf /etc/apache2/mods-available/suphp.conf.backup
rm /etc/apache2/mods-available/suphp.conf
cat > /etc/apache2/mods-available/suphp.conf <<EOF
<IfModule mod_suphp.c>
    #<FilesMatch "\.ph(p3?|tml)$">
    #    SetHandler application/x-httpd-suphp
    #</FilesMatch>
        AddType application/x-httpd-suphp .php .php3 .php4 .php5 .phtml
        suPHP_AddHandler application/x-httpd-suphp

    <Directory />
        suPHP_Engine on
    </Directory>

    # By default, disable suPHP for debian packaged web applications as files
    # are owned by root and cannot be executed by suPHP because of min_uid.
    <Directory /usr/share>
        suPHP_Engine off
    </Directory>

# # Use a specific php config file (a dir which contains a php.ini file)
#       suPHP_ConfigPath /etc/php5/cgi/suphp/
# # Tells mod_suphp NOT to handle requests with the type <mime-type>.
#       suPHP_RemoveHandler <mime-type>
</IfModule>
EOF

#Enable Ruby Support
sed -i 's|application/x-ruby|#application/x-ruby|' /etc/mime.types

#Install XCache
apt-get -y install php5-xcache

#Restart Apache
/etc/init.d/apache2 restart

}

debian_install_NginX (){

#Install NginX, PHP5, phpMyAdmin, FCGI, suExec, Pear, And mcrypt
#PhpMyAdmin Selections Not Working
#echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
#echo "dbconfig-common dbconfig-common/dbconfig-install boolean false" | debconf-set-selections
apt-get -y install nginx
/etc/init.d/apache2 stop
update-rc.d -f apache2 remove
/etc/init.d/nginx start

apt-get -y install php5-fpm
apt-get -y install php5-mysql php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-memcached php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached
apt-get -y install php-apc
#PHP Configuration Stuff Goes Here
apt-get -y install fcgiwrap
apt-get -y install phpmyadmin

#Remove the Apache2 Stuff for NginX
/etc/init.d/apache2 stop
insserv -r apache2
/etc/init.d/nginx start

/etc/init.d/php5-fpm restart

}

debian_install_Mailman (){
#Install Mailman
apt-get -y install mailman
newlist mailman

mv /etc/aliases /etc/aliases.backup

cat > /etc/aliases.mailman <<EOF
mailman:              "|/var/lib/mailman/mail/mailman post mailman"
mailman-admin:        "|/var/lib/mailman/mail/mailman admin mailman"
mailman-bounces:      "|/var/lib/mailman/mail/mailman bounces mailman"
mailman-confirm:      "|/var/lib/mailman/mail/mailman confirm mailman"
mailman-join:         "|/var/lib/mailman/mail/mailman join mailman"
mailman-leave:        "|/var/lib/mailman/mail/mailman leave mailman"
mailman-owner:        "|/var/lib/mailman/mail/mailman owner mailman"
mailman-request:      "|/var/lib/mailman/mail/mailman request mailman"
mailman-subscribe:    "|/var/lib/mailman/mail/mailman subscribe mailman"
mailman-unsubscribe:  "|/var/lib/mailman/mail/mailman unsubscribe mailman"
EOF

cat /etc/aliases.backup /etc/aliases.mailman > /etc/aliases
newaliases
/etc/init.d/postfix restart
ln -s /etc/mailman/apache.conf /etc/apache2/conf.d/mailman.conf
/etc/init.d/apache2 restart
/etc/init.d/mailman start

}

debian_install_PureFTPD (){
#Install PureFTPd
apt-get -y install pure-ftpd-common pure-ftpd-mysql

#Setting up Pure-Ftpd
sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
echo 1 > /etc/pure-ftpd/conf/TLS
mkdir -p /etc/ssl/private/
echo "==========================================================================================="
echo "The following questions can be left as default (just press enter), but when"
echo "asked for 'Common Name', enter your FQDN hostname ($HOSTNAMEFQDN)."
echo "==========================================================================================="
echo "Press ENTER to continue.."
read DUMMY

openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/pure-ftpd.pem
/etc/init.d/pure-ftpd-mysql restart

}

debian_install_Quota (){

#Editing FStab
cp /etc/fstab /etc/fstab.backup
sed -i "s/errors=remount-ro/errors=remount-ro,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0/" /etc/fstab

#Setting up Quota
apt-get -y install quota quotatool
mount -o remount /
quotacheck -avugm
quotaon -avug

}

debian_install_Bind (){
#Install BIND DNS Server
apt-get -y install bind9 dnsutils

}

debian_install_Stats (){

#Install Vlogger, Webalizer, And AWstats
apt-get -y install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl

sed -i "s/*/10 * * * * www-data/#*/10 * * * * www-data/" /etc/cron.d/awstats
sed -i "s/10 03 * * * www-data/#10 03 * * * www-data/" /etc/cron.d/awstats

}

debian_install_Jailkit (){
#Install Jailkit
apt-get -y install build-essential autoconf automake1.9 libtool flex bison debhelper binutils-gold

cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.16.tar.gz
tar xvfz jailkit-2.16.tar.gz
cd jailkit-2.16
./debian/rules binary
cd ..
dpkg -i jailkit_2.16-1_*.deb
rm -rf jailkit-2.16*

}

debian_install_Fail2BanCourier (){
#Install fail2ban
apt-get -y install fail2ban

cat > /etc/fail2ban/jail.local <<EOF
[pureftpd]
enabled  = true
port     = ftp
filter   = pureftpd
logpath  = /var/log/syslog
maxretry = 3

[sasl]
enabled  = true
port     = smtp
filter   = sasl
logpath  = /var/log/mail.log
maxretry = 5

[courierpop3]
enabled  = true
port     = pop3
filter   = courierpop3
logpath  = /var/log/mail.log
maxretry = 5

[courierpop3s]
enabled  = true
port     = pop3s
filter   = courierpop3s
logpath  = /var/log/mail.log
maxretry = 5

[courierimap]
enabled  = true
port     = imap2
filter   = courierimap
logpath  = /var/log/mail.log
maxretry = 5

[courierimaps]
enabled  = true
port     = imaps
filter   = courierimaps
logpath  = /var/log/mail.log
maxretry = 5
EOF
}

debian_install_Fail2BanDovecot() {
#Install fail2ban
apt-get -y install fail2ban

cat > /etc/fail2ban/jail.local <<EOF
[pureftpd]
enabled  = true
port     = ftp
filter   = pureftpd
logpath  = /var/log/syslog
maxretry = 3

[dovecot-pop3imap]
enabled = true
filter = dovecot-pop3imap
action = iptables-multiport[name=dovecot-pop3imap, port="pop3,pop3s,imap,imaps", protocol=tcp]
logpath = /var/log/mail.log
maxretry = 5

[sasl]
enabled  = true
port     = smtp
filter   = sasl
logpath  = /var/log/mail.log
maxretry = 3
EOF

}

debian_install_Fail2BanRulesCourier() {

cat > /etc/fail2ban/filter.d/pureftpd.conf <<EOF
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierpop3.conf <<EOF
[Definition]
failregex = pop3d: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierpop3s.conf <<EOF
[Definition]
failregex = pop3d-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierimap.conf <<EOF
[Definition]
failregex = imapd: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/courierimaps.conf <<EOF
[Definition]
failregex = imapd-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

/etc/init.d/fail2ban restart

}

debian_install_Fail2BanRulesDovecot() {

cat > /etc/fail2ban/filter.d/pureftpd.conf <<EOF
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF

cat > /etc/fail2ban/filter.d/dovecot-pop3imap.conf <<EOF
[Definition]
failregex = (?: pop3-login|imap-login): .*(?:Authentication failure|Aborted login \(auth failed|Aborted login \(tried to use disabled|Disconnected \(auth failed|Aborted login \(\d+ authentication attempts).*rip=(?P<host>\S*),.*
ignoreregex =
EOF

/etc/init.d/fail2ban restart

}

debian_install_SquirrelMail (){

echo "==========================================================================================="
echo "When prompted, type D! Then type the mailserver you choose ($mail_server),"
echo "and hit enter. Type S, Hit Enter. Type Q, Hit Enter."
echo "==========================================================================================="
echo "Press ENTER to continue.."
read DUMMY
#Install SquirrelMail
apt-get -y install squirrelmail
squirrelmail-configure

mv /etc/squirrelmail/apache.conf /etc/squirrelmail/apache.conf.backup
cat > /etc/squirrelmail/apache.conf <<EOF
Alias /squirrelmail /usr/share/squirrelmail
Alias /webmail /usr/share/squirrelmail

<Directory /usr/share/squirrelmail>
  Options FollowSymLinks
  <IfModule mod_php5.c>
    AddType application/x-httpd-php .php
    php_flag magic_quotes_gpc Off
    php_flag track_vars On
    php_admin_flag allow_url_fopen Off
    php_value include_path .
    php_admin_value upload_tmp_dir /var/lib/squirrelmail/tmp
    php_admin_value open_basedir /usr/share/squirrelmail:/etc/squirrelmail:/var/lib/squirrelmail:/etc/hostname:/etc/mailname
    php_flag register_globals off
  </IfModule>
  <IfModule mod_dir.c>
    DirectoryIndex index.php
  </IfModule>

  # access to configtest is limited by default to prevent information leak
  <Files configtest.php>
    order deny,allow
    deny from all
    allow from 127.0.0.1
  </Files>
</Directory>

# users will prefer a simple URL like http://webmail.example.com
#<VirtualHost 1.2.3.4>
#  DocumentRoot /usr/share/squirrelmail
#  ServerName webmail.example.com
#</VirtualHost>

# redirect to https when available (thanks omen@descolada.dartmouth.edu)
#
#  Note: There are multiple ways to do this, and which one is suitable for
#  your site's configuration depends. Consult the apache documentation if
#  you're unsure, as this example might not work everywhere.
#
#<IfModule mod_rewrite.c>
#  <IfModule mod_ssl.c>
#    <Location /squirrelmail>
#      RewriteEngine on
#      RewriteCond %{HTTPS} !^on$ [NC]
#      RewriteRule . https://%{HTTP_HOST}%{REQUEST_URI}  [L]
#    </Location>
#  </IfModule>
#</IfModule>
EOF

mkdir /var/lib/squirrelmail/tmp
chown www-data /var/lib/squirrelmail/tmp
ln -s /etc/squirrelmail/apache.conf /etc/apache2/conf.d/squirrelmail.conf
/etc/init.d/apache2 reload

}

install_ISPConfig (){
#Install ISPConfig 3
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar xfz ISPConfig-3-stable.tar.gz
cd /tmp/ispconfig3_install/install/
php -q install.php

} 

debian_install_RoundCube_NginX (){

}

debian_install_RoundCube_Apache (){

echo "==========================================================================================="
echo "When prompted, type D! Then type the mailserver you choose ($mail_server),"
echo "and hit enter. Type S, Hit Enter. Type Q, Hit Enter."
echo "==========================================================================================="
echo "Press ENTER to continue.."
read DUMMY


echo "roundcube-core  roundcube/dbconfig-upgrade  boolean true" | debconf-set-selections
echo "roundcube-core  roundcube/database-type select  mysql" | debconf-set-selections
echo "roundcube-core  roundcube/mysql/admin-pass  $MYSQL_ROOT_PASSWORD" | debconf-set-selections

echo "roundcube/reconfigure-webserver: apache2" | debconf-set-selections


apt-get install -y roundcube roundcube-plugins roundcube-plugins-extra

sed -i 's/$rcmail_config['default_host'] = '';/$rcmail_config['default_host'] = 'localhost';/' /etc/roundcube/main.inc.php

#Install RoundCube Plugins for ISPConfig3 

cd /tmp
wget --no-check-certificate -O RCPlugins.zip https://github.com/w2c/ispconfig3_roundcube/archive/master.zip
unzip RCPlugins.zip
cd ispconfig3_roundcube-master
mv ispconfig3_* /var/lib/roundcube/plugins
cd /var/lib/roundcube/plugins
mv ispconfig3_account/config/config.inc.php.dist ispconfig3_account/config/config.inc.php

sed -i 's/$rcmail_config['plugins'] = array();///$rcmail_config['plugins'] = array();/' /etc/roundcube/main.inc.php
sed 's/.*//$rcmail_config['plugins'] = array();'


}

#Execute functions#
if [ -f /etc/debian_version ]; then 
	debian_install_basic
    debian_install_DashNTP
    if [ $mail_server == "Courier" ]; then
		debian_install_MYSQLCourier
	fi
	if [ $mail_server == "Dovecot" ]; then
  		debian_install_MYSQLDovecot
	fi
	debian_install_Virus
	if [ $web_server == "Apache" ]; then
		debian_install_Apache
	fi
	if [ $web_server == "NginX" ]; then
		debian_install_NginX
	fi
	if [ $mailman == "Yes" ]; then
		debian_install_Mailman
	fi
	debian_install_PureFTPD
	if [ $quota == "Yes" ]; then
		debian_install_Quota
	fi
	debian_install_Bind
    debian_install_Stats
    if [ $jailkit == "Yes" ]; then
		debian_install_Jailkit
	fi
	if [ $mail_server == "Courier" ]; then
        debian_install_Fail2BanCourier
        debian_install_Fail2BanRulesCourier
    fi
    if [ $mail_server == "Dovecot" ]; then
        debian_install_Fail2BanDovecot
        debian_install_Fail2BanRulesDovecot
    fi
    if [ $web_mail == "RoundCube" ]; then
        if [ $web_mail == "Apache" ]; then
            debian_install_RoundCube_Apache
        fi
        if [ $web_mail == "NginX" ]; then
            debian_install_RoundCube_NginX
        fi
    fi
    if [ $web_mail == "SquirrelMail" ]; then
        debian_install_SquirrelMail
    fi 
    install_ISPConfig
else echo "Unsupported Linux Distribution."
fi		

#End execute functions#
