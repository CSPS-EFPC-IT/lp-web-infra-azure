#!/bin/bash
# This script must be run as root (ex.: sudo sh [script_name])

function echo_title {
    echo ""
    echo "###############################################################################"
    echo "$1"
    echo "###############################################################################"
}

function echo_action {
    echo ">> $1"
}

###############################################################################
echo_title "Starting $0 on $(date)."
###############################################################################

###############################################################################
echo_title "Map input parameters."
###############################################################################
projectName="$1"
appStoragePath="$2"
dbServerName="$3"
dbServerFqdn="$4"
dbAdminUsername="$5"
dbAdminPassword="$6"
dbAppDatabaseName="$7"
dbAppUsername="$8"
dbAppPassword="$9"
echo_action "Done."

###############################################################################
echo_title "Echo parameter values for debuging purpose."
###############################################################################
echo_action "projectName=${projectName}"
echo_action "appStoragePath=${appStoragePath}"
echo_action "dbServerName=${dbServerName}"
echo_action "dbServerFqdn=${dbServerFqdn}"
echo_action "dbAdminUsername=${dbAdminUsername}"
echo_action "dbAdminPassword=${dbAdminPassword}"
echo_action "dbAppDatabaseName=${dbAppDatabaseName}"
echo_action "dbAppUsername=${dbAppUsername}"
echo_action "dbAppPassword=${dbAppPassword}"
echo_action "Done."

###############################################################################
echo_title "Set useful variables."
###############################################################################
defaultDocumentRoot="/var/www/html"
newDocumentRoot="${defaultDocumentRoot}/${projectName}/web"
nginxUser="www-data"
phpFpmIniPath="/etc/php/7.3/fpm/php.ini"
workingDir=$(pwd)
echo_action "Done."

###############################################################################
echo_title "Update and upgrade the server."
###############################################################################
echo_action "Updating sytem..."
apt-get update

echo_action "Upgrading sytem..."
apt-get upgrade -y

echo_action "Removing unused components..."
apt-get autoremove -y

echo_action "Done."

###############################################################################
echo_title "Install tools."
###############################################################################
echo_action "Installing mysql-client..."
apt-get install mysql-client -y

echo_action "Done."

###############################################################################
echo_title "Install NGINX and PHP dependencies."
###############################################################################
echo_action "Adding ppa:ondrej/nginx repository..."
add-apt-repository ppa:ondrej/nginx -y

echo_action "Adding ppa:ondrej/php repository..."
add-apt-repository ppa:ondrej/php -y

echo_action "Updating local repositories..."
apt update -y

echo_action "Installing nginx..."
apt-get install nginx -y

echo_action "Installing PHP 7.3..."
apt-get install php7.3-fpm php7.3-common php7.3-mysql php7.3-xml php7.3-xmlrpc php7.3-curl php7.3-gd php7.3-imagick php7.3-cli php7.3-dev php7.3-imap php7.3-mbstring php7.3-opcache php7.3-soap php7.3-zip php7.3-intl -y

echo_action "Done."

###############################################################################
echo_title "Update PHP FastCGI Process Manager (FPM) config."
###############################################################################
echo_action "Updating allow_url_fopen setting."
sed -i "s/^;\?allow_url_fopen[[:space:]]*=.*/allow_url_fopen = On/" $phpFpmIniPath

echo_action "Updating cgi.fix_pathinfo setting."
sed -i "s/^;\?cgi\.fix_pathinfo[[:space:]]*=.*/cgi\.fix_pathinfo = 0/" $phpFpmIniPath

echo_action "Updating date.timezone setting."
sed -i "s/^;\?date\.timezone[[:space:]]*=.*/date\.timezone = America\/Toronto/" $phpFpmIniPath

echo_action "Updating file_uploads setting."
sed -i "s/^;\?file_uploads[[:space:]]*=.*/file_uploads = On/" $phpFpmIniPath

echo_action "Updating max_execution_time setting."
sed -i "s/^;\?max_execution_time[[:space:]]*=.*/max_execution_time = 360/" $phpFpmIniPath

echo_action "Updating memory_limit setting."
sed -i "s/^;\?memory_limit[[:space:]]*=.*/memory_limit = 256M/" $phpFpmIniPath

echo_action "Updating short_open_tag setting."
sed -i "s/^;\?short_open_tag[[:space:]]*=.*/short_open_tag = On/" $phpFpmIniPath

echo_action "Updating upload_max_filesize setting."
sed -i "s/^;\?upload_max_filesize[[:space:]]*=.*/upload_max_filesize = 100M/" $phpFpmIniPath

echo_action "Restarting PHP processor."
service php7.3-fpm restart

echo_action "Done."

###############################################################################
echo_title "Configure a new NGINX site for ${projectName}."
###############################################################################
echo_action "Creating new document root folder..."
mkdir --parents ${newDocumentRoot}

echo_action "Creating dummy index.php file..."
cat <<EOF > ${newDocumentRoot}/index.php
<?php
phpinfo();
EOF

echo_action "Updating document root ownership..."
chown -R $nginxUser ${defaultDocumentRoot}

echo_action "Creating new NGINX site configuration..."
cat <<EOF > /etc/nginx/sites-available/${projectName}
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root ${newDocumentRoot};
    index index.php;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.3-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

echo_action "Enabling new site configuration..."
ln -s /etc/nginx/sites-available/${projectName} /etc/nginx/sites-enabled/${projectName}

echo_action "Disabling NGINX default site configuration..."
rm /etc/nginx/sites-enabled/default

echo_action "Reloading new site configuration..."
service nginx reload

echo_action "Done."

###############################################################################
echo_title "Mount Data disk."
###############################################################################
echo_action "Creating a file system on data disk..."
mkfs -t ext4 /dev/sdc

echo_action "Creating a mount point for the data disk..."
mkdir --parents $appStoragePath

echo_action "Updating fstab file with new mount point definition..."
printf "/dev/sdc\t${appStoragePath}\text4\tdefaults,nofail\t0\t0\n" >> /etc/fstab

echo_action "Mounting all mount points..."
mount -a

echo_action "Updating mountpoint ownership..."
chown -R $nginxUser $appStoragePath

echo_action "Done."

###############################################################################
echo_title "Create Application database user "
###############################################################################
echo_action "Saving database connection parameters to file..."
touch ${workingDir}/mysql.connection
chmod 600 ${workingDir}/mysql.connection
cat <<EOF > ${workingDir}/mysql.connection
[client]
host=${dbServerFqdn}
user=${dbAdminUsername}@${dbServerName}
password="${dbAdminPassword}"
EOF

echo_action "Creating user and granting privileges..."
mysql --defaults-extra-file=${workingDir}/mysql.connection <<EOF
DROP USER IF EXISTS "${dbAppUsername}"@"${dbServerName}";
CREATE USER "${dbAppUsername}"@"${dbServerName}" IDENTIFIED BY '${dbAppPassword}';
GRANT ALL PRIVILEGES ON ${dbAppDatabaseName}.* TO "${dbAppUsername}"@"${dbServerName}";
FLUSH PRIVILEGES;
exit
EOF

echo_action "Done."

###############################################################################
echo_title "Finishing $0 on $(date)."
###############################################################################