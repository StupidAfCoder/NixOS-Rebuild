#!/usr/bin/env bash
mkdir -p ~/Videos
n=$(ls ~/Videos 2>/dev/null | grep -oP 'recording-\K[0-9]+' | sort -n | tail -1)
n=$((n + 1))
notify-send -u low "Recording" "⏹ Started (recording-$n.mp4)" -t 1500
wf-recorder -f ~/Videos/recording-"$n".mp4