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
shift 9
vmAdminUsername="$1"
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
echo_action "dbAppDatabaseName=${dbAppDatabaseName}" ##
echo_action "dbAppUsername=${dbAppUsername}"
echo_action "dbAppPassword=${dbAppPassword}"
echo_action "vmAdminUsername=${vmAdminUsername}"
echo_action "Done."

###############################################################################
echo_title "Set useful variables."
###############################################################################
defaultDocumentRoot="/var/www/html"
newDocumentRoot="${defaultDocumentRoot}/${projectName}/web"
nginxUser="www-data"
phpVersion="7.2"
phpFpmIniPath="/etc/php/${phpVersion}/fpm/php.ini"
workingDir=$(pwd)
echo_action "Done."

###############################################################################
echo_title "Update and upgrade the server."
###############################################################################
echo_action "Updating system repository..."
apt-get update

echo_action "Upgrading system..."
apt-get upgrade -y

echo_action "Done."

###############################################################################
echo_title "Install tools."
###############################################################################
# echo_action "Installing mysql-client..."
#apt-get install mysql-client -y

echo_action "Installing postgresql-client..."
apt-get install postgresql-client-10 -y

echo_action "Done."

###############################################################################
echo_title "Install Application Stack."
###############################################################################
echo_action "Installing nginx..."
apt-get install nginx -y

echo_action "Installing PHP ${phpVersion} Modules..."
apt-get install \
    php${phpVersion}-cli \
    php${phpVersion}-common \
    php${phpVersion}-curl \
    php${phpVersion}-dev \
    php${phpVersion}-fpm \
    php${phpVersion}-gd \
    php${phpVersion}-imagick \
    php${phpVersion}-imap \
    php${phpVersion}-intl \
    php${phpVersion}-mbstring \
    php${phpVersion}-opcache \
    php${phpVersion}-pgsql \
    php${phpVersion}-soap \
    php${phpVersion}-xml \
    php${phpVersion}-xmlrpc \
    php${phpVersion}-zip -y

# echo_action "Installing PHP 7.3 Modules..."
# apt-get install php7.3-fpm php7.3-common php7.3-mysql php7.3-xml php7.3-xmlrpc php7.3-curl php7.3-gd php7.3-imagick php7.3-cli php7.3-dev php7.3-imap php7.3-mbstring php7.3-opcache php7.3-soap php7.3-zip php7.3-intl -y

# echo_action "Installing PHP 7.4 Modules..."
# apt-get install php7.4-fpm php7.4-common php7.4-pgsql php7.4-xml php7.4-xmlrpc php7.4-curl php7.4-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip php7.4-intl -y

# echo_action "Installing latest PHP modules..."
# apt-get install php-fpm php-common php-pgsql php-xml php-xmlrpc php-curl php-gd php-imagick php-cli php-dev php-imap php-mbstring php-opcache php-soap php-zip php-intl -y

echo_action "Installing NPM..."
apt-get install npm -y

echo_action "Installing PHP Composer..."
apt-get install unzip -y
curl -sS https://getcomposer.org/installer -o composer-setup.php
HASH=e0012edf3e80b6978849f5eff0d4b4e4c79ff1609dd1e613307e16318854d24ae64f26d17af3ef0bf7cfb710ca74755a
php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer

echo_action "Removing unused components..."
apt-get autoremove -y

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
service php${phpVersion}-fpm restart

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
chown -R ${nginxUser}:${vmAdminUsername} ${defaultDocumentRoot}
chmod -R g+w ${defaultDocumentRoot}

echo_action "Creating new NGINX site configuration..."
cat <<EOF > /etc/nginx/sites-available/${projectName}
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root ${newDocumentRoot};
    index index.php;

    server_name _;

    location / {
        try_files \$uri \$uri/ @rewrites;
    }
    location @rewrites {
        rewrite ^(.*) /index.php?p=\$1 last;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${phpVersion}-fpm.sock;
    }
    location ~ /\.ht {
        deny all;
    }

    error_page 404 /index.php;
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

echo_action "Creating a symbolic link: ${newDocumentRoot}/uploads -> $appStoragePath..."
ln -s $appStoragePath $newDocumentRoot/uploads

echo_action "Done."

###############################################################################
echo_title "Create Application database user "
###############################################################################
# echo_action "Saving database connection parameters to file..."
# touch ${workingDir}/mysql.connection
# chmod 600 ${workingDir}/mysql.connection
# cat <<EOF > ${workingDir}/mysql.connection
# [client]
# host=${dbServerFqdn}
# user=${dbAdminUsername}@${dbServerName}
# password="${dbAdminPassword}"
# EOF

# echo_action "Creating user and granting privileges..."
# mysql --defaults-extra-file=${workingDir}/mysql.connection <<EOF
# DROP USER IF EXISTS "${dbAppUsername}"@"%";
# CREATE USER "${dbAppUsername}"@"%" IDENTIFIED BY '${dbAppPassword}';
# GRANT ALL PRIVILEGES ON ${dbAppDatabaseName}.* TO "${dbAppUsername}"@"%";
# FLUSH PRIVILEGES;
# exit
# EOF

echo_action "Creating user and granting privileges..."
export PGPASSWORD="$dbAdminPassword"
psql "host=${dbServerFqdn} port=5432 dbname=postgres user=${dbAdminUsername}@${dbServerName} sslmode=require" <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname='${dbAppUsername}') THEN
        CREATE USER ${dbAppUsername} WITH ENCRYPTED PASSWORD '${dbAppPassword}';
        GRANT ALL PRIVILEGES ON DATABASE ${dbAppDatabaseName} TO ${dbAppUsername};
        RAISE INFO 'User ${dbAppUsername} created.';
    ELSE
        RAISE WARNING 'User ${dbAppUsername} was already existing. Nothing was done.';
    END IF;
END
\$\$;
EOF

echo_action "Done."

###############################################################################
echo_title "Finishing $0 on $(date)."
###############################################################################