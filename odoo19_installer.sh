#!/bin/bash
# Copyright from 2024 odooerpcloud.com
# !!! (WARNING!!!)
# Hardware Requirements:
#   * >=2GB RAM
#   * 20-40GB SSD
# Software Requirements: 
#   * Ubuntu 24.04 LTS Desktop or Server Edition, Debian 12 BookWorm
# v4.0.4 Production version for Odoo Coomunity or Enterprise Edition
# See tutorial for Odoo Enterprise Integration.
# Odoo Installer Pro supported versions: 16.0, 17.0, 18.0, 19.0
# Last updated: 2025-03-17


######## Customizable Variables from exporting ENV ########
ODOO_VERSION="${ODOO_VERSION:-master}"
ODOO_PORT="${ODOO_PORT:-8069}"
ODOO_GEVENT_PORT="${ODOO_GEVENT_PORT:-8072}"
ODOO_PROJECT_NAME="${ODOO_PROJECT_NAME:-odoo19}"

## Do not change the following variables ##
ODOO_USER=odoo
SERVICE_NAME=$ODOO_PROJECT_NAME
OS_NAME=$(lsb_release -cs)
DIR_PATH=$(pwd)
VCODE=master
#OCA_VERSION=18.0
PYTHON_VERSION=3.12
DEPTH=1

############################ Odoo Enterprise Version ############################
# Set to true if you want to install Odoo Enterprise
# by default is False for Odoo Community
# This script is used for setting up Odoo 18.0 development environment.
# Note: To install the enterprise version from GitHub, you need to export
# the following environment variables before running the script and you must to have access to the enterprise repository:
# - GH_USER: Your GitHub username
# - PAT: Your GitHub personal access token
# To create a GitHub Personal Access Token (PAT), follow the instructions here:
# https://github.com/settings/tokens
#
# Example exporting variables from terminal:
export GH_USER=acti-odoo
export PAT=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
export ODOO_INSTALL_ENTERPRISE=true
export ODOO_VERSION=master
export ODOO_PORT=8069
export ODOO_GEVENT_PORT=8072
export ODOO_PROJECT_NAME=odoo19

ODOO_INSTALL_ENTERPRISE="${ODOO_INSTALL_ENTERPRISE:-true}"
###################################################################################

PATHBASE=/opt/$ODOO_PROJECT_NAME
PATH_LOG=$PATHBASE/log
PATHREPOS=$PATHBASE/extra-addons
PATHREPOS_OCA=$PATHREPOS/oca
BACKUPS_DIR=/opt/backups
# Set GeoIP
GEOIP_DIR="/usr/share/GeoIP"
GEOIP_City="GeoLite2-City.mmdb"
GEOIP_Country="GeoLite2-Country.mmdb"
# C. Set PostreSQL version:
PG_VERSION=17

wk64=""
wk32=""
# SET ARCH for wkhtmltopdf (amd64/arm64)
ARCH=amd64

if [[ $OS_NAME == "bookworm" ]];

then
	wk64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_${ARCH}.deb"

fi

# the official version for Noble is not available yet, we use Jammy
if [[ $OS_NAME == "jammy" || $OS_NAME == "noble" ]];

then
	wk64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_${ARCH}.deb"

fi


if [[ $OS_NAME == "buster"  ||  $OS_NAME == "bionic" || $OS_NAME == "focal" ]];

then
	wk64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1."$OS_NAME"_${ARCH}.deb"
	wk32="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1."$OS_NAME"_i386.deb"

fi

if [[ $OS_NAME == "bullseye" ]];

then
	wk64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2."$OS_NAME"_${ARCH}.deb"
	wk32="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2."$OS_NAME"_i386.deb"
fi

echo $wk64
sudo useradd -m  -d $PATHBASE -s /bin/bash $ODOO_USER
# uncomment if you get sudo permissions
#sudo adduser $ODOO_USER sudo

#add universe repository & update (Fix error download libraries)
export DEBIAN_FRONTEND=noninteractive
sudo add-apt-repository universe -y -q
sudo apt-get update
sudo apt-get upgrade -y -q

#### Install Dependencies and Packages
sudo apt-get update && \
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    dirmngr \
    fonts-dejavu-core \
    fonts-freefont-ttf \
    fonts-freefont-otf \
    fonts-noto-core \
    fonts-inconsolata \
    fonts-font-awesome \
    fonts-roboto-unhinted \
    gsfonts \
    gcc \
    git \
    gnupg \
    htop \
    libevent-dev \
    libjpeg-dev \
    libldap2-dev \
    libpng-dev \
    libpq-dev \
    libssl-dev \
    libsasl2-dev \
    libxml2-dev \
    libxslt1-dev \
    libxrender1 \
    nano \
    net-tools \
    node-less \
    npm \
    procps \
    python3-dev \
    python3-pip \
    python3-venv \
    unzip \
    xfonts-75dpi \
    xfonts-base \
    xz-utils \
    zip

##################end python dependencies#####################

############## PG Update and install Postgresql ##############
# Default postgresql install package (old method)
#sudo apt-get install postgresql postgresql-client -y
#sudo  -u postgres  createuser -s $ODOO_USER
############## PG Update and install Postgresql ##############

############## PG Update and install Postgresql new way ######
sudo apt install -y -q curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt install -y -q postgresql-$PG_VERSION postgresql-client-$PG_VERSION postgresql-$PG_VERSION-pgvector
sudo  -u postgres  createuser -s $ODOO_USER
############## PG Update and install Postgresql ##############

sudo mkdir $PATHBASE
sudo mkdir $PATHREPOS
sudo mkdir $PATHREPOS_OCA
sudo mkdir $PATHREPOS_THEMES
sudo mkdir $PATH_LOG
sudo mkdir $BACKUPS_DIR
cd $PATHBASE
# Download Odoo from git source
sudo git clone https://github.com/odoo/odoo.git -b $ODOO_VERSION --depth $DEPTH $PATHBASE/odoo
# Clone Odoo enterprise repository (optional)
if $ODOO_INSTALL_ENTERPRISE ; then
    # validate if the GH_USER and PAT are set
    if [ -z "$GH_USER" ] || [ -z "$PAT" ]; then
        echo "GH_USER and PAT variables are required to install Odoo Enterprise, please set it before running the script"
        exit 1
    fi
    echo "Installing Odoo Enterprise"
    sudo git clone https://$GH_USER:$PAT@github.com/odoo/enterprise.git -b $ODOO_VERSION --depth $DEPTH $PATHBASE/enterprise

fi

# Download odoo themes oficial desing website
sudo git clone https://github.com/odoo/design-themes.git -b $ODOO_VERSION --depth $DEPTH $PATHREPOS_THEMES

# Download OCA/web (optional backend theme for community only)
# sudo git clone https://github.com/oca/web.git -b $OCA_VERSION --depth $DEPTH $PATHREPOS_OCA/web

#nodejs and less
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less

# Download & install WKHTMLTOPDF
sudo rm $PATHBASE/wkhtmltox*.deb

if [[ "`getconf LONG_BIT`" == "32" ]];

then
	sudo wget $wk32
else
	sudo wget $wk64
fi

sudo dpkg -i --force-depends wkhtmltox_0.12.6*.deb
sudo apt-get -f -y install
sudo ln -s /usr/local/bin/wkhtml* /usr/bin
sudo rm $PATHBASE/wkhtmltox*.deb

############ UV Python Package Manager Setup ########
# UV Documentation: https://docs.astral.sh/uv/getting-started/installation/
sudo wget https://astral.sh/uv/install.sh
sudo chmod +x install.sh
sudo -u $ODOO_USER bash -c 'source install.sh'
USER_HOME=$(getent passwd $ODOO_USER | cut -d: -f6)
UV=$USER_HOME/.local/bin/uv
echo "$UV"
echo 'eval "$(uv generate-shell-completion bash)"' >> $USER_HOME/.bashrc
$UV python install $PYTHON_VERSION
# Remove old venv and create a new one
sudo rm -rf $PATHBASE/venv
sudo rm -rf $PATHBASE/.venv
sudo mkdir $PATHBASE/.venv
sudo chown -R $ODOO_USER:root $PATHBASE/.venv
sudo -u $ODOO_USER $UV venv --python $PYTHON_VERSION
# Activate the virtual environment
source $PATHBASE/.venv/bin/activate
# upgrade pip and install python requirements file (Odoo)
$UV pip install --upgrade pip setuptools wheel
$UV pip install -r $PATHBASE/odoo/requirements.txt

######### Begin Add your custom python extra libs #############
# (e.g. phonenumbers for Odoo WhatsApp App, Account Peppol)
$UV pip install phonenumbers markdown2 geoip2

######### end extra python pip libs ###########################
cd $DIR_PATH

sudo mkdir $PATHBASE/config
sudo rm $PATHBASE/config/odoo$VCODE.conf
sudo touch $PATHBASE/config/odoo$VCODE.conf
echo "
[options]
; This is the password that allows database operations:
;admin_passwd =
db_host = False
db_port = False
;db_user =

;db_password =
data_dir = $PATHBASE/data
logfile= $PATH_LOG/odoo$VCODE-server.log
log_handler = :WARNING, :ERROR 
log_level = info
log_db = False

logrotate = True
http_port = $ODOO_PORT
;dbfilter = ^%d$
;list_db = False
limit_time_real = 6000
limit_time_cpu = 6000

gevent_port = $ODOO_GEVENT_PORT
proxy_mode = False

############# addons path ######################################

addons_path =
    $PATHREPOS,
    $PATHREPOS_THEMES,
    $PATHBASE/odoo/addons

#################################################################
" | sudo tee --append $PATHBASE/config/odoo$VCODE.conf

# Add Enterprise path to addons path
if [ -d "$PATHBASE/enterprise" ]; then
    sed -i.bak  "s|^\(addons_path *= *\)|\1\n    $PATHBASE/enterprise,|" "$PATHBASE/config/odoo$VCODE.conf"
fi

sudo rm /etc/systemd/system/$SERVICE_NAME.service
sudo touch /etc/systemd/system/$SERVICE_NAME.service
sudo chmod +x /etc/systemd/system/$SERVICE_NAME.service
echo "
[Unit]
Description=Odoo$VCODE-$SERVICE_NAME
After=postgresql.service

[Service]
Restart=on-failure
RestartSec=5s
Type=simple
User=$ODOO_USER
ExecStart=$PATHBASE/.venv/bin/python $PATHBASE/odoo/odoo-bin --config $PATHBASE/config/odoo$VCODE.conf --load=base,web --geoip-city-db $GEOIP_DIR/$GEOIP_City --geoip-country-db $GEOIP_DIR/$GEOIP_Country

[Install]
WantedBy=multi-user.target
" | sudo tee --append /etc/systemd/system/$SERVICE_NAME.service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME.service
sudo systemctl start $SERVICE_NAME.service
# set proper permissions to the odoo folder and backups
sudo chown -R $ODOO_USER: $PATHBASE
sudo chown -R $ODOO_USER:root $BACKUPS_DIR
## Add cron backup project folder (Backup everyday 4:30am)
sudo -u root bash << eof
cd /root
echo "Agregando crontab para backup carpeta instalacion Odoo..."

sudo crontab -l | sed -e '/zip/d; /$ODOO_PROJECT_NAME/d' > temporal

echo "
30 4 * * * zip -r /opt/$ODOO_PROJECT_NAME.zip $BACKUPS_DIR" >> temporal
crontab temporal
rm temporal
eof

# add sudoers permissions
# Create a new file in /etc/sudoers.d/odoo
SUDOERS_FILE="/etc/sudoers.d/odoo"

# Check if the file exists
if [ -f "$SUDOERS_FILE" ]; then
    echo "The file $SUDOERS_FILE already exists. Overriding."
    echo "" > $SUDOERS_FILE
else
    echo "Adding file $SUDOERS_FILE... to set Odoo permissions"
    touch $SUDOERS_FILE
fi
echo "$ODOO_USER ALL=(ALL) NOPASSWD: /bin/systemctl start $SERVICE_NAME.service" >> $SUDOERS_FILE
echo "$ODOO_USER ALL=(ALL) NOPASSWD: /bin/systemctl stop $SERVICE_NAME.service" >> $SUDOERS_FILE
echo "$ODOO_USER ALL=(ALL) NOPASSWD: /bin/systemctl restart $SERVICE_NAME.service" >> $SUDOERS_FILE

echo "Odoo $ODOO_VERSION Installation has finished!! ;) by odooerpcloud.com"
IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
echo "You can access from: http://$IP:$ODOO_PORT  or http://localhost:$ODOO_PORT"