#!/usr/bin/env bash

STREAMKEY="skydivehoogeveen" # Can be anything, the nignx RTMP server is not configured to check the stream key
AVSERVER="rtmp://avserver.local:1935/live/${STREAMKEY}"


# Start PulseAudio
pulseaudio --kill						# Kill pulseaudio if it was still running
pulseaudio --start						# Start pluseaudio
pactl load-module module-combine-sink	# Use both HDMI and 3.5mm jack audio out by combining them into one sink
pactl set-default-sink combined			# Set the default PulseAudio interface to combined (see 'pactl list sinks short' for the names of your audio interfaces)

# Set volume to 100%
amixer set Master 100%					# Set master mixer volume to 100%
amixer -c 0 set PCM 100%				# Set 3.5mm jack audio output volume to 100%

# Start Command-line VLC and play the video+audio stream over HDMI, and audio over the 3.5mm jack
DISPLAY=:0 vlc \
	-I dummy \
	--no-video-title-show \
	--fullscreen \
	"${AVSERVER}"
