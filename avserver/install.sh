#!/usr/bin/env bash

APP_NAME="AudioVideo-client-server"
APP_ITEM="avserver"
LOG_FILE="/var/log/${APP_NAME}/install.log"

ICECAST_HOSTNAME="avserver.local"
ICECAST_USERNAME="avserver"
ICECAST_PASSWORD="password"

# ----------------------------------
# Check if user has root permissions
# ----------------------------------
if [ "$EUID" -ne 0 ]
then
	echo "Please run as root"
	exit
fi

# ------------------------------------------------------------------------------------------------------
# Create log directory and tail the log file so the user can see what's going on during the installation
# ------------------------------------------------------------------------------------------------------
mkdir -m 755 -p "/var/log/${APP_NAME}/"
chown root:root "/var/log/${APP_NAME}/"
touch "${LOG_FILE}"
tail -f "${LOG_FILE}" &
echo "$(date +%c) Installer start for ${APP_NAME}" >> "${LOG_FILE}" 2>&1
echo "$(date +%c) Window manager: ${XDG_SESSION_TYPE}" >> "${LOG_FILE}" 2>&1

# ----------------------------
# Expand the rootfs filesystem
# ----------------------------
echo "$(date +%c) Expanding rootfs" >> "${LOG_FILE}" 2>&1
sudo raspi-config --expand-rootfs >> "${LOG_FILE}" 2>&1

# -------------
# Update system
# -------------
echo "$(date +%c) Updating system" >> "${LOG_FILE}" 2>&1
apt-get -y autoremove >> "${LOG_FILE}" 2>&1
apt-get -y update >> "${LOG_FILE}" 2>&1
apt-get -y dist-upgrade >> "${LOG_FILE}" 2>&1
apt-get -y --with-new-pkgs upgrade >> "${LOG_FILE}" 2>&1
apt-get -y clean >> "${LOG_FILE}" 2>&1 
apt-get -y autoremove >> "${LOG_FILE}" 2>&1

# ----------------
# Install packages
# ----------------
# avahi-daemon			: mDNS support
# chromium-browser		: Web browser for video input
# ffmpeg				: Convert incoming RTMP stream to Icecast format
# git					: 
# icecast2				: Audio streaming server
# nano					: Text editor
# nginx					: RTMP server
# libnginx-mod-rtmp		: RTMP server
# sed					: Tool for auto-editing /boot/config.txt
# unattended-upgrades	: 
# xvfb					: Run an application in a virtual X server environment
# ----------------
echo "$(date +%c) Installing packages" >> "${LOG_FILE}" 2>&1
echo "icecast2 icecast2/start_daemon boolean true" | debconf-set-selections >> "${LOG_FILE}" 2>&1
echo "icecast2 icecast2/shutdown_mode select shutdown" | debconf-set-selections >> "${LOG_FILE}" 2>&1
echo "icecast2 icecast2/hostname string ${ICECAST_HOSTNAME}" | debconf-set-selections >> "${LOG_FILE}" 2>&1
echo "icecast2 icecast2/username string ${ICECAST_USERNAME}" | debconf-set-selections >> "${LOG_FILE}" 2>&1
echo "icecast2 icecast2/password string ${ICECAST_PASSWORD}" | debconf-set-selections >> "${LOG_FILE}" 2>&1
echo "icecast2 icecast2/relay_password string ${ICECAST_PASSWORD}" | debconf-set-selections >> "${LOG_FILE}" 2>&1
echo "icecast2 icecast2/crypt_password string ${ICECAST_PASSWORD}" | debconf-set-selections >> "${LOG_FILE}" 2>&1

apt-get install -y avahi-daemon chromium ffmpeg git icecast2 nano nginx libnginx-mod-rtmp sed unattended-upgrades xvfb >> "${LOG_FILE}" 2>&1

# -------------------
# Install application
# -------------------
echo "$(date +%c) Installing ${APP_NAME} - ${APP_ITEM}" >> "${LOG_FILE}" 2>&1
git clone ${APP_SOURCE} "/opt/" >> "${LOG_FILE}" 2>&1
chmod +x "/opt/${APP_NAME}/${APP_ITEM}/*.sh" >> "${LOG_FILE}" 2>&1
chmod +x "/opt/${APP_NAME}/${APP_ITEM}/*.service" >> "${LOG_FILE}" 2>&1

# ---------------------------
# Configure nginx RTMP server
# ---------------------------
mv -f "rtmp.conf" >> "/etc/nginx/modules-enabled/" >> "${LOG_FILE}" 2>&1
chmod 644 "/etc/nginx/modules-enabled/rtmp.conf" >> "${LOG_FILE}" 2>&1
chown root:root "/etc/nginx/modules-enabled/rtmp.conf" >> "${LOG_FILE}" 2>&1
#sudo usermod -aG audio www-data # Give nginx permission to use the audio ports
#sudo usermod -aG video www-data # Give nginx permission to use the video ports

# ----------------------------
# Install application service
# ----------------------------
cp "/opt/${APP_NAME}/${APP_ITEM}/${APP_ITEM}.service" "/etc/systemd/system/" >> "${LOG_FILE}" 2>&1
sed -i "s/^User=pi/User=${SUDO_USER}/" "/etc/systemd/system/avserver.service" >> "${LOG_FILE}" 2>&1
chmod +x "/etc/systemd/system/avserver.service" >> "${LOG_FILE}" 2>&1
sudo systemctl enable avserver.service >> "${LOG_FILE}" 2>&1

# -------
# Restart
# -------
echo "$(date +%c) Installer done for ${APP_NAME} - ${APP_ITEM}" >> "${LOG_FILE}" 2>&1
echo -n 'Restarting in 10 seconds'
for i in {0..10}
do
	sleep 1
 	echo -n .
done

shutdown -r 1 >> "${LOG_FILE}" 2>&1
