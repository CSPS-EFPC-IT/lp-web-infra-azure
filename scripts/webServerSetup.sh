
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
projectName=$1
echo "Done."

###############################################################################
echo_title "Echo parameter values for debuging purpose."
###############################################################################
echo "Done."

###############################################################################
echo_title "Set useful variables."
###############################################################################
phpIniPath="/etc/php/7.3/fpm/php.ini"
defaultDocumentRoot=/var/www/html
nginxUser="www-data"
newDocumentRoot=${defaultDocumentRoot}/${projectName}/web
data
installDir=$(pwd)
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
mkdir /mnt/data
sudo printf "/dev/sdc\t/mnt/data\text4\tdefaults,nofail\t0\t0\n" >> /etc/fstab
sudo mount -a
chmod -R 777 /mnt/data
echo "Done."

###############################################################################
echo_title "Install tools."
###############################################################################
apt-get install mysql-client ## temporaire
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
echo_title "Update PHP config."
###############################################################################
echo "Update upload_max_filesize setting."
sed -i "s/upload_max_filesize.*/upload_max_filesize = 100M/" $phpIniPath

echo "Update post_max_size setting."
sed -i "s/post_max_size.*/post_max_size = 2048M/" $phpIniPath

echo "Done."

###############################################################################
echo_title "Update NGINX default site DocumentRoot property."
###############################################################################
if ! grep -q "${newDocumentRoot}" /etc/nginx/sites-available/000-default.conf; then
    echo "Updating /etc/apache2/sites-available/000-default.conf..."
    escapedDefaultDocumentRoot=$(sed -E 's/(\/)/\\\1/g' <<< ${defaultDocumentRoot})
    escapedNewDocumentRoot=$(sed -E 's/(\/)/\\\1/g' <<< ${newDocumentRoot})
    sed -i -E "s/DocumentRoot[[:space:]]*${escapedDefaultDocumentRoot}/DocumentRoot ${escapedNewDocumentRoot}/g" /etc/nginx/sites-available/000-default.conf
    echo "Restarting NGINX..."
    service nginx restart
else
    echo "Skipping /etc/nginx/sites-available/000-default.conf file update."
fi
echo "Done."

###############################################################################
echo_title "Create Application database user if not existing."
###############################################################################
echo "Done."


###############################################################################
echo_title "Finishing $0 on $(date)."
###############################################################################

