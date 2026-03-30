#!/usr/bin/env bash

# Detectar monitores
INTERNAL="eDP-1"
HDMI="HDMI-A-5"

choice=$(printf "Duplicar\nExtender\nSolo Laptop\nSolo HDMI" | rofi -dmenu -i -p "Pantallas")

case "$choice" in
  Duplicar)
    hyprctl keyword monitor $INTERNAL,1920x1080@60,0x0,1
    hyprctl keyword monitor $HDMI,preferred,auto,1.25,mirror,$INTERNAL
    ;;
  Extender)
    hyprctl keyword monitor $INTERNAL,1920x1080@60,0x0,1
    hyprctl keyword monitor $HDMI,preferred,auto,1.25,1920x0
    ;;
  "Solo Laptop")
    hyprctl keyword monitor $HDMI,disable
    hyprctl keyword monitor $INTERNAL,1920x1080@60,0x0,1
    ;;
  "Solo HDMI")
    hyprctl keyword monitor $INTERNAL,disable
    hyprctl keyword monitor $HDMI,preferred,auto,1.25
    ;;
esac
