# oxh-dotfiles

Personal Arch Linux + Hyprland dotfiles. The repo is meant to be
cloned and run on a clean Arch+Hyprland install on any laptop/PC.

## Goals
- Single-command bootstrap via `install.sh`
- Idempotent: re-running install.sh should not break anything
- Configs share a consistent style and carry an `oxh-dotfiles` signature
- All inline comments in English

## Conventions
- Comment style: section-level only, not line-by-line
- Signature header on every config file (see hypr/hyprland.conf for the canonical form)
- Shell scripts: bash, `set -euo pipefail`, shellcheck-clean

## Layout
- `hypr/`, `waybar/`, `kitty/`, etc. — per-app configs
- `scripts/` — helper scripts invoked by install.sh
- `install.sh` — entry point
- `assets/fonts/` — fonts used in ricing (if vendored)