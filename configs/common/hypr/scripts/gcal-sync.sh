#!/bin/bash
# oxh-hyprland-dotfiles by occhi

CACHE="$HOME/.cache/gcalcli"
mkdir -p "$CACHE"

gcalcli agenda --nocolor --nostarted \
  --details location \
  --details description \
  --tsv > "$CACHE/calendar.tsv"