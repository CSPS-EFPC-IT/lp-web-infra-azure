#!/bin/bash
# This script must be run as root (ex.: sudo sh [script_name])

function echo_title {
    echo ""
    echo "###############################################################################"
    echo "$1"
    echo "###############################################################################"
}

###############################################################################
echo_title "Starting $0 on $(date)."
###############################################################################

###############################################################################
echo_title "Map input parameters."
###############################################################################
projectName="$1"
appStoragePath="$2"
echo "Done."

###############################################################################
echo_title "Echo parameter values for debuging purpose."
###############################################################################
echo "Done."

###############################################################################
echo_title "Set useful variables."
###############################################################################
defaultDocumentRoot=/var/www/html
newDocumentRoot=${defaultDocumentRoot}/${projectName}/web
nginxUser="www-data"
phpFpmIniPath="/etc/php/7.3/fpm/php.ini"
echo "Done."

###############################################################################
echo_title "Update and upgrade the server."
###############################################################################
apt-get update
apt-get upgrade -y
apt-get autoremove -y
echo "Done."

###############################################################################
echo_title "Mount Data disk."
###############################################################################
mkfs -t ext4 /dev/sdc
mkdir --parents $appStoragePath
printf "/dev/sdc\t${appStoragePath}\text4\tdefaults,nofail\t0\t0\n" >> /etc/fstab
mount -a
chown -R $nginxUser $appStoragePath
echo "Done."

###############################################################################
echo_title "Install tools."
###############################################################################
apt-get install mysql-client
echo "Done."

###############################################################################
echo_title "Install NGINX and PHP dependencies."
###############################################################################
add-apt-repository ppa:ondrej/nginx -y
add-apt-repository ppa:ondrej/php -y
apt update -y
apt-get install nginx php7.3-fpm php7.3-common php7.3-mysql php7.3-xml php7.3-xmlrpc php7.3-curl php7.3-gd php7.3-imagick php7.3-cli php7.3-dev php7.3-imap php7.3-mbstring php7.3-opcache php7.3-soap php7.3-zip php7.3-intl -y
echo "Done."

###############################################################################
echo_title "Update PHP FastCGI Process Manager (FPM) config."
###############################################################################
echo "Update allow_url_fopen setting."
sed -i "s/^;\?allow_url_fopen[[:space:]]*=.*/allow_url_fopen = On/" $phpFpmIniPath

echo "Update cgi.fix_pathinfo setting."
sed -i "s/^;\?cgi\.fix_pathinfo[[:space:]]*=.*/cgi\.fix_pathinfo = 0/" $phpFpmIniPath

echo "Update date.timezone setting."
sed -i "s/^;\?date\.timezone[[:space:]]*=.*/date\.timezone = America\/Toronto/" $phpFpmIniPath

echo "Update file_uploads setting."
sed -i "s/^;\?file_uploads[[:space:]]*=.*/file_uploads = On/" $phpFpmIniPath

echo "Update max_execution_time setting."
sed -i "s/^;\?max_execution_time[[:space:]]*=.*/max_execution_time = 360/" $phpFpmIniPath

echo "Update memory_limit setting."
sed -i "s/^;\?memory_limit[[:space:]]*=.*/memory_limit = 256M/" $phpFpmIniPath

echo "Update short_open_tag setting."
sed -i "s/^;\?short_open_tag[[:space:]]*=.*/short_open_tag = On/" $phpFpmIniPath

echo "Update upload_max_filesize setting."
sed -i "s/^;\?upload_max_filesize[[:space:]]*=.*/upload_max_filesize = 100M/" $phpFpmIniPath

echo "Restarting PHP processor."
service php7.3-fpm restart

echo "Done."

###############################################################################
echo_title "Configure a new NGINX site for ${projectName}."
###############################################################################
echo "Create and initialize new site document root."
mkdir --parents ${newDocumentRoot}
cat <<EOF >> ${newDocumentRoot}/index.php
<?php
phpinfo();
EOF
chown -R $nginxUser ${defaultDocumentRoot}

echo "Create new NGINX site configuration."
cat <<EOF >> /etc/nginx/sites-available/${projectName} \
server {\
    listen 80 default_server;\
    listen [::]:80 default_server;\
\
    root ${newDocumentRoot};\
    index index.php;\
\
    server_name _;\
\
    location / {\
        try_files \$uri \$uri/ =404;\
    }\
\
    location ~ \.php$ {\
        include snippets/fastcgi-php.conf;\
        fastcgi_pass unix:/run/php/php7.3-fpm.sock;\
    }\
\
    location ~ /\.ht {\
        deny all;\
    }\
}\
EOF

echo "Enable new site configuration"
ln -s /etc/nginx/sites-available/${projectName} /etc/nginx/sites-enabled/${projectName}

echo "Disable NGINX default site configuration"
rm /etc/nginx/sites-enabled/default

echo "Reload new site configuration"
service nginx reload

###############################################################################
echo_title "Create Application database user if not existing."
###############################################################################
echo "Not yet implemented"

###############################################################################
echo_title "Finishing $0 on $(date)."
###############################################################################

