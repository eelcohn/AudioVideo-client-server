#!/usr/bin/env bash

APP_NAME="AudioVideo-client-server"
APP_ITEM="avclient"
APP_SOURCE="https://github.com/eelcohn/${APP_NAME}"
LOG_FILE="/var/log/${APP_NAME}/install.log"

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
# 
# avahi-daemon			: mDNS support
# git					: 
# nano					: 
# pulseaudio			: Audio support
# pulseaudio			: Audio support utils
# sed					: 
# unattended-upgrades	:
# vlc					: Output the RTMP stream to audio and video outputs
# ----------------
echo "$(date +%c) Installing packages" >> "${LOG_FILE}" 2>&1
apt-get install -y alsa-utils avahi-daemon git nano pulseaudio pulseaudio-utils sed unattended-upgrades vlc >> "${LOG_FILE}" 2>&1

# -------------------
# Install application
# -------------------
echo "$(date +%c) Installing ${APP_NAME} - ${APP_ITEM}" >> "${LOG_FILE}" 2>&1
git clone "${APP_SOURCE}" "/opt/${APP_SOURCE}" >> "${LOG_FILE}" 2>&1
chmod +x "/opt/${APP_NAME}/${APP_ITEM}/*.sh" >> "${LOG_FILE}" 2>&1
chmod +x "/opt/${APP_NAME}/${APP_ITEM}/*.service" >> "${LOG_FILE}" 2>&1

# ----------------------------
# Install application service
# ----------------------------
cp "/opt/${APP_NAME}/${APP_ITEM}/${APP_ITEM}.service" "/etc/systemd/system/" >> "${LOG_FILE}" 2>&1
sed -i "s/^User=pi/User=${SUDO_USER}/" "/etc/systemd/system/${APP_ITEM}.service"
chmod +x "/etc/systemd/system/${APP_ITEM}.service"
sudo systemctl enable ${APP_ITEM}.service

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
