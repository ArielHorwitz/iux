#!/bin/bash

layer=$1
keyboard_layout=$2

if [[ $layer = "base" ]]; then
    setxkbmap us
    polybar-msg action kmd hook 0
    gamma &
elif [[ $layer = "text" ]]; then
    setxkbmap $keyboard_layout
    polybar-msg action kmd hook 1
    gamma cyan &
else
    echo "No such layer '$layer'" >&2; exit 1
fi
