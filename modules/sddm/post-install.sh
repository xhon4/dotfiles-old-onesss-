#!/usr/bin/env bash
# Post-install hook for SDDM module

SDDM_THEME_DIR="/usr/share/sddm/themes/oxh-sddm"

if [[ -d "$RICECTL_ROOT/system/sddm-theme" ]]; then
    srun "mkdir -p $SDDM_THEME_DIR"
    srun "cp -r $RICECTL_ROOT/system/sddm-theme/* $SDDM_THEME_DIR/"

    if [[ ! -f /etc/sddm.conf.d/theme.conf ]]; then
        srun "mkdir -p /etc/sddm.conf.d"
        local tmp
        tmp="$(mktemp)"
        printf '%s\n%s\n' '[Theme]' 'Current=oxh-sddm' > "$tmp"
        srun "cp '$tmp' /etc/sddm.conf.d/theme.conf"
        rm -f "$tmp"
    fi
    success "SDDM OXH theme deployed"
fi
