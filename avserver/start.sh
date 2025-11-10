#!/usr/bin/env bash

STREAMKEY="skydivehoogeveen" # Can be anything, the nignx RTMP server is not configured to check the stream key
RTMP_SERVER="rtmp://localhost:1935/live/${STREAMKEY}" # RTMP server address
ICECAST_SERVER="icecast://localhost:8000/live"
URL="https://www.skydivehoogeveen.nl/" # URL of the website to be streamed as video over RTMP
SCREEN_ID="44"



# See https://stackoverflow.com/a/79399916 for info on the commands below

# First start the virtual screen
xvfb-run \
	--listen-tcp \
	--server-num ${SCREEN_ID} \
	-s "-ac -screen 0 1920x1080x24" \
	chromium \
		--password-store=basic \
		--disable-session-crashed-bubble \
		--disable-infobars \
		--start-fullscreen \
		--window-size=1920,1080 \
		--window-position=0,0 ${URL} &

# Generate a audio/video stream to the nginx RTMP and an audio-only stream to the Icecast2 server
ffmpeg \
	 -nostats \
	-f x11grab -video_size 1920x1080 -i :${SCREEN_ID} \
	-f alsa -i default \
	-codec:v h264_v4l2m2m -r 30 -codec:a aac -b:a 192k -f flv ${RTMP_SERVER} \
	-vn -c:a libmp3-lame -b:a 192k -f mp3 "${ICECAST_SERVER}"

pkill chromium
pkill xvfb-run
