#!/usr/bin/env bash

# Obtiene la clase de la ventana activa
active_class=$(hyprctl activewindow -j | jq -r ".class")

case "$active_class" in
    "Steam")
        # Steam: minimizar en lugar de cerrar
        xdotool windowunmap $(xdotool getactivewindow)
        ;;
    "Spotify" | "spotify")
        # Spotify: mover a workspace especial
        hyprctl dispatch movetoworkspacesilent special:spotify
        ;;
    *)
        # Cualquier otra app: cerrar normal
        hyprctl dispatch killactive ""
        ;;
esac
