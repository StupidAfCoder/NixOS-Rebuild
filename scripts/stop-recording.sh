#!/usr/bin/env bash
killall -SIGINT wf-recorder
notify-send -u low "Recording" "⏹ Stopped, saved to ~/Videos" -t 2000