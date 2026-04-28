# AUDIT.md — Pre-Refactor Senior-Engineer Audit
**Repository:** `/home/occhi/dotfiles-old-onesss-`
**Date:** 2026-04-28
**Auditor:** Claude Sonnet 4.6 (automated senior-engineer pass)

---

## 1. Repo Map

### Top-Level Files and Directories

| Path | Description |
|------|-------------|
| `install.sh` | One-shot bootstrap: checks OS/user/internet, installs git/rsync/curl/base-devel, clones repo, hands off to `ricectl install` |
| `ricectl` | Main CLI (~825 lines): commands `install`, `uninstall`, `doctor`, `sync`, `backup`, `module`, `profile`, `secrets`, `update`, `version`, `help` |
| `Makefile` | Convenience wrappers around common `ricectl` invocations |
| `VERSION` | Single-line semantic version string (`1.0.0`) |
| `CLAUDE.md` | Project conventions for Claude Code: goals, conventions, layout description |
| `README.md` | User-facing docs, includes the `curl | bash` one-liner |
| `.gitignore` | Ignores logs, backups, secrets plaintext, `.bak` files, `.cache/` |
| `.zshrc` | Root-level zshrc deployed to `~/.zshrc` by the zsh module post-install |
| `.p10k.zsh` | Powerlevel10k prompt config deployed to `~/.p10k.zsh` |
| `install.log` | Log written on a prior run (committed to repo) |

### `lib/` — Shell Libraries

| File | Description |
|------|-------------|
| `lib/core.sh` | Logging helpers, `run()`/`srun()`, YAML parser (`parse_yaml`, `yaml_list`), `sudo_keepalive`, `confirm` |
| `lib/deploy.sh` | `deploy_configs()`, `deploy_file()`, `fix_permissions()`, `deploy_module()` |
| `lib/os.sh` | `detect_os()`, `detect_os_pretty()`, `require_arch()`, `detect_gpu()`, `detect_chassis()`, `is_wayland()`, `get_hostname()` |
| `lib/packages.sh` | `pkg_installed()`, `install_pacman()`, `install_aur()`, `ensure_yay()`, `install_module_packages()`, `enable_services()` |
| `lib/tui.sh` | `gum`-backed interactive UI components with plain-text fallbacks; profile/module/variant selectors |

### `modules/` — Module Definitions

Each `modules/<name>/` contains at minimum a `module.yaml`. Some also have a `post-install.sh`.

| Module | Category | Key Packages | Post-Install | `config_dir` Override |
|--------|----------|-------------|--------------|----------------------|
| `alacritty` | terminal | alacritty | — | — |
| `btop` | monitoring | btop | — | — |
| `cava` | audio | cava | — | — |
| `docker` | dev | docker, docker-compose | adds user to docker group | — |
| `dunst` | notifications | dunst, libnotify | — | — |
| `fastfetch` | tools | fastfetch | — | — |
| `gpu-amd` | system | *(none)* | — | — |
| `gtk` | theming | gtk3, gtk4 | deploys gtk-3.0 and gtk-4.0 configs | — |
| `hyprland` | wm | hyprland + 15 pkgs, AUR: hyprshot | — | `hypr` |
| `kitty` | terminal | kitty | — | — |
| `kvantum` | theming | kvantum | — | `Kvantum` |
| `pipewire` | audio | pipewire stack (8 pkgs) | — | — |
| `qt6ct` | theming | qt6ct | — | — |
| `rofi` | launcher | AUR: rofi-wayland | — | — |
| `sddm` | system | sddm | deploys OXH theme + writes `/etc/sddm.conf.d/theme.conf` | — |
| `waybar` | bar | *(none — pacman: [])* | — | — |
| `yazi` | tools | yazi | — | — |
| `zsh` | shell | zsh, zsh-completions | sets default shell, installs Zinit, deploys .zshrc/.p10k.zsh | — |

### `profiles/` — Install Profiles

| Profile | Description | Variant | Modules |
|---------|-------------|---------|---------|
| `full.yaml` | Full rice — Hyprland + all modules + aesthetics | auto | 17 modules |
| `rice.yaml` | Aesthetic rice only — WM + bar + theming | auto | 14 modules |
| `dev.yaml` | Development environment — shell + tools + docker | (none) | 6 modules |
| `minimal.yaml` | Minimal setup — shell + terminal + basic tools | (none) | 5 modules |

### `configs/`

| Path | Description |
|------|-------------|
| `configs/common/alacritty/` | Alacritty TOML config + unexpectedly-nested `zsh/` subtree (see findings) |
| `configs/common/btop/` | btop.conf + custom OXH theme |
| `configs/common/cava/` | cava config + GLSL shaders + two color themes |
| `configs/common/dunst/` | dunstrc notification daemon config |
| `configs/common/fastfetch/` | fastfetch config.jsonc + custom ASCII logo |
| `configs/common/gtk-3.0/` | GTK3 dark theme settings.ini |
| `configs/common/gtk-4.0/` | GTK4 dark theme settings.ini |
| `configs/common/hypr/` | hyprland.conf, hypridle.conf, hyprlock.conf, duplicate root-level scripts, `scripts/` subdir |
| `configs/common/rofi/` | config.rasi, PowerMenu.rasi, OXH theme, 2 extra themes, emote files, scripts |
| `configs/common/yazi/` | yazi theme.toml |
| `configs/variants/laptop/waybar/` | Waybar config, style, spotify/clock scripts — adapted for 1366×768 |
| `configs/variants/pc/waybar/` | Waybar config, style, spotify/clock scripts — adapted for desktop |

### `system/`

| Path | Description |
|------|-------------|
| `system/sddm-theme/` | Full SDDM Sugar Candy theme (QML, SVG assets, theme.conf, metadata). References wallpaper `y8yxlx.jpg`. |

### `secrets/`

| Path | Description |
|------|-------------|
| `secrets/.gitkeep` | Empty placeholder; rest of `secrets/*` is gitignored |

### `.github/`

| Path | Description |
|------|-------------|
| `.github/workflows/ci.yaml` | GitHub Actions: shellcheck on all `.sh` files, YAML syntax validation, module structure checks, profile→module reference checks, dry-run smoke test |

---

## 2. Findings

---

### Bugs & Logic Errors

---

#### [HIGH] `hyprlock.conf` — duplicate `path =` key (syntax error)
**File:** `configs/common/hypr/hyprlock.conf`, line 4
```
path = path = /usr/share/backgrounds/y8yxlx.jpg
```
`path` is assigned the literal string `path = /usr/share/backgrounds/y8yxlx.jpg`. Hyprlock will fail to find the background. The correct value is:
```
path = /usr/share/backgrounds/y8yxlx.jpg
```

---

#### [HIGH] `cava/config` — unclosed single-quote on `foreground` (syntax error)
**File:** `configs/common/cava/config`, line 20
```ini
foreground = 'default
```
The closing `'` is missing. Cava will fail to parse this config and either crash or use built-in defaults, ignoring all subsequent settings in the file.

---

#### [HIGH] Wallpaper filename mismatch — `awww` / `y8yxlx.jpg` vs `oxh-wallpaper.jpg`
**Files involved:**
- `configs/common/hypr/hyprland.conf`, line 15: `exec-once = sleep 1 && awww img /usr/share/backgrounds/y8yxlx.jpg`
- `configs/common/hypr/hyprlock.conf`, line 4: references `y8yxlx.jpg`
- `system/sddm-theme/theme.conf`, line 4: `Background="/usr/share/backgrounds/y8yxlx.jpg"`
- `ricectl`, line 149: deploys `assets/wallpaper.jpg` as `/usr/share/backgrounds/oxh-wallpaper.jpg`

The deployed wallpaper is named `oxh-wallpaper.jpg`; all three configs reference `y8yxlx.jpg`. After a clean install the wallpaper will not load in Hyprland, Hyprlock, or SDDM.

Additionally, `hyprland.conf` uses `awww`/`awww-daemon` for wallpaper, but the `hyprland` module installs `hyprpaper` (and starts nothing for it). These are two different, incompatible tools — `awww` is never installed and will silently fail at login.

---

#### [HIGH] `waybar` package is never installed
**File:** `modules/waybar/module.yaml`
```yaml
pacman: []
```
The `waybar` module explicitly installs no packages. The `depends: [hyprland]` field is decorative only — `deploy_module` never reads `depends:` (confirmed: not referenced anywhere in `lib/deploy.sh` or `ricectl`). The `waybar` binary must be manually pre-installed or come in as a transitive pacman dependency of Hyprland, which is not guaranteed. Profiles `full.yaml` and `rice.yaml` list `waybar` as a module but the package is never installed.

---

#### [HIGH] `cmd_sync push` and `cmd_backup create` use `mod_name` instead of `config_name` — silently skips `hypr` configs
**File:** `ricectl`, lines 272–275 and 537–541

`cmd_sync push` iterates `configs/common/*/` and reads from `$HOME/.config/$mod_name`. The loop variable `mod_name` is the *directory basename from `configs/common/`*, not the value of `config_dir` in the module's YAML. This is fine for most modules, but:
- The directory in `configs/common/` is named `hypr` (not `hyprland`) — so sync correctly finds `~/.config/hypr`.
- This is coincidentally OK because it uses the *common config directory name*, which happens to match `config_dir`. However `cmd_backup create` (lines 537–541) also uses `$mod_name` from `configs/common/*/` basenames, so it has the same pattern but works for the same coincidental reason.

The deeper problem: `cmd_module list` (line 356) checks `$HOME/.config/$mod_name` where `mod_name` comes from `modules/` basenames. For `kvantum` the deploy target is `~/.config/Kvantum` (capital K), but the list checks `~/.config/kvantum` (all lowercase) — so a deployed Kvantum module always shows as "not deployed" (red dot).

---

#### [MED] `module.yaml` `configs:` key is silently ignored
**File:** `modules/zsh/module.yaml`, lines 9–13
```yaml
configs:
  - source: .zshrc
    dest: ~/.zshrc
```
`deploy_module()` in `lib/deploy.sh` does not read or process the `configs:` key. The zsh module's post-install hook (`modules/zsh/post-install.sh`) deploys these files directly via `deploy_file`, so the effect is the same — but the `configs:` declaration in the YAML is misleading dead data.

---

#### [MED] `module.yaml` `depends:` key is silently ignored
No code in `lib/deploy.sh` or `ricectl` reads the `depends:` field. Dependencies are never automatically installed when a module is installed individually via `ricectl module install`. A user installing `waybar` directly will get an empty install (no packages, no configs, no services).

---

#### [MED] `yaml_list` with an empty list emits an empty string; callers consume it safely but inconsistently
**File:** `lib/core.sh`, line 153
```bash
echo "${items[@]}"
```
When `items=()`, `echo "${items[@]}"` outputs an empty line (or nothing). Callers do:
```bash
read -ra arr <<< "$(yaml_list ...)"
```
In bash, `read -ra arr <<< ""` sets `arr` to an empty array `()`, so the guard `[[ ${#arr[@]} -gt 0 ]]` correctly skips. This is safe in practice, but only because of the coincidental behavior of `read -ra` on an empty string — not explicit design. If `yaml_list` were ever called and its output were passed directly (without the `read -ra` idiom), a spurious empty-string element would be injected.

---

#### [MED] `mod_count` in install summary counts all YAML list items, not just modules
**File:** `ricectl`, line 85
```bash
mod_count="$(grep -c '^ *- ' "$profile_yaml" || echo 0)"
```
For `full.yaml`, this counts every `-` item across all sections (base_packages, modules, fonts, aur_fonts, networking, networking_services, extras_aur). The displayed "Modules: 45" is misleading — there are only 17 actual modules. The `ricectl profile list` command has the same bug (line 406, pattern `'^ *-'`).

---

#### [MED] `cmd_module list` deployment-detection heuristic is inaccurate
**File:** `ricectl`, line 356

The detection check is:
```bash
if [[ -d "$HOME/.config/$mod_name" ]] || \
   [[ "$mod_name" == "zsh" && -f "$HOME/.zshrc" ]] || \
   [[ "$mod_name" == "docker" && -f "/usr/bin/docker" ]]; then
```
Problems:
1. `kvantum` deploys to `~/.config/Kvantum` (capital K) but check uses lowercase `kvantum`. Always reports as "not deployed."
2. `gtk` deploys to `~/.config/gtk-3.0` and `~/.config/gtk-4.0`, never `~/.config/gtk`. Always reports as "not deployed."
3. `gpu-amd`, `pipewire`, `sddm`, `qt6ct` are hardcoded exceptions in `cmd_doctor` (line 218) but NOT in `cmd_module list`, so these also always show as "not deployed" regardless of install status.
4. The `cmd_doctor` check hardcodes exceptions for `zsh`, `gtk`, `gpu-amd`, and `docker` but inconsistently — `gpu-amd` is excluded from package checks in doctor but `kvantum` is not.

---

#### [MED] `btop.conf` — typo `rounded_corners = Trues`
**File:** `configs/common/btop/btop.conf`, line 11
```ini
rounded_corners = Trues
```
Should be `True`. btop will silently ignore or misinterpret this value.

---

#### [MED] `gpu-amd` module installs no packages and has no effect
**File:** `modules/gpu-amd/module.yaml`
The module is a no-op: `pacman: []`, no post-install script, no configs. The AMD GPU environment variables (`RADV_PERFTEST`, `AMD_VULKAN_ICD`, etc.) are hardcoded in `.zshrc` unconditionally — they apply to all users even on non-AMD hardware. The module is listed in `full.yaml` and `rice.yaml` but does nothing when deployed.

---

#### [LOW] `parse_yaml` — variable collision when prefix reuse occurs
**File:** `lib/core.sh`, line 88

`deploy_module` always uses `prefix="mod"`. When the function is called for a second module in the same process, `parse_yaml` first runs `compgen -v "mod_"` and calls `unset` on every matching variable. However, the clear loop uses `IFS='=' read -r var _` against output from `compgen -v` which outputs just variable names (no `=` character). This means the IFS split has no effect, `var` gets the full name, and `unset` correctly runs. The clearing logic therefore works, but is written in a confusing/misleading style that implies key=value parsing.

---

#### [LOW] `parse_yaml` — cannot handle indented keys, nested maps, or multiline values
**File:** `lib/core.sh`, line 111
```bash
if [[ "$line" =~ ^($w): *(.*) ]]; then
```
The pattern anchors to column 0 (`^`). Any indented key (e.g. under a map value) is silently skipped. This is documented implicitly by the comment "Parses *simple* YAML," but the `configs:` list in `zsh/module.yaml` uses indented sub-keys (`source:`, `dest:`) that are silently ignored — reinforcing the dead-data finding above.

---

#### [LOW] `configs/common/alacritty/zsh/` subtree deployed to wrong location
**File:** `configs/common/alacritty/`

When `deploy_module alacritty` runs, `deploy_configs` rsync-copies all of `configs/common/alacritty/` to `~/.config/alacritty/`. This includes the `zsh/` subdirectory, so `~/.config/alacritty/zsh/` is created on the target system. The `.zshrc` then iterates `"$HOME/.config/alacritty/zsh/helpers/"` to add directories to `PATH` — but the deployed structure has `utils/` and `configs/`, not `helpers/`. The PATH augmentation silently does nothing (loop finds no directory, `nullglob` suppresses error). Additionally, the four files `.aliases`, `.colors`, `.configs`, `.hooks` in that subtree are zero-byte placeholders with no content.

---

### Security Issues

---

#### [HIGH] `curl | bash` in README
**File:** `README.md`, line 67
```
curl -sL https://raw.githubusercontent.com/xhon4/dotfiles/main/install.sh | bash
```
This is an unauthenticated download-and-execute pattern. There is no checksum verification, no GPG signature check, and no integrity guarantee. If GitHub or the CDN is compromised, or if the repo is taken over, users are silently pwned. The `install.sh` comment on line 4 also documents this pattern as the recommended usage.

**Mitigation:** At minimum, document a hash-verified alternative; ideally switch to "clone first, inspect, then run."

---

#### [HIGH] `eval` in `run()` executes arbitrary shell from YAML values
**File:** `lib/core.sh`, line 45
```bash
eval "$@"
```
`run()` is called with strings constructed from YAML values, package names, and file paths. If any YAML value (e.g., a package name or `config_dir`) contains shell metacharacters, `eval` will execute them. Example attack vector: a maliciously crafted or accidentally broken `module.yaml` with a `config_dir: $(rm -rf ~)` value would execute on `deploy_module`. This is the intentional design (eval allows the `cd '...' && makepkg` pattern in `ensure_yay`), but it means all data flowing into `run()` must be trusted.

---

#### [HIGH] `emote-picker.sh` — `sed /e` flag executes shell commands from stats file
**File:** `configs/common/rofi/scripts/emote-picker.sh`, line 61
```bash
sed -i "s/^\([0-9]*\)|$SELECTED$/echo \$((\1+1))|$SELECTED/e" "$STATS_FILE"
```
The `/e` flag in GNU sed executes the replacement string as a shell command. The replacement embeds `$SELECTED` (the emoji chosen by the user, taken from `$HOME/.config/rofi/emotes.txt`). While emojis are low-risk, the `$STATS_FILE` itself could be written by another process or pre-seeded with a malicious entry. Additionally, if `$SELECTED` ever contains a shell command (e.g., via a crafted `emotes.txt`), arbitrary code execution occurs. This pattern should be replaced with a Python/awk counter update.

---

#### [MED] `sddm/post-install.sh` — `sudo tee` bypasses `DRY_RUN`
**File:** `modules/sddm/post-install.sh`, line 12
```bash
echo -e '[Theme]\nCurrent=oxh-sddm' | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
```
This line uses `sudo tee` directly, outside of `run()`. It therefore always executes even when `DRY_RUN=true`, writing to `/etc/sddm.conf.d/theme.conf` unconditionally. All other privileged operations use `srun()` → `run()` → eval (which respects DRY_RUN).

---

#### [MED] `sudo_keepalive` — background process may orphan after parent exit
**File:** `lib/core.sh`, line 80
```bash
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
```
`kill -0 "$$"` checks if the parent PID still exists. If the parent exits cleanly, the background loop will exit on the next `sleep 60` cycle boundary — meaning up to 60 seconds of orphaned sudo credential refreshing after the parent completes. On a system with multiple users or a shared session this is a small but real privilege escalation window. The loop should use a shorter sleep, or use `wait` / a trap on EXIT to explicitly kill the background PID.

---

#### [MED] `ensure_yay` — tmpdir used in `run()` via single-quoted path inside double quotes
**File:** `lib/packages.sh`, lines 57–58
```bash
run "git clone https://aur.archlinux.org/yay.git '$tmpdir/yay'"
run "cd '$tmpdir/yay' && makepkg -si --noconfirm"
```
`$tmpdir` is expanded *before* `run()` is called (it's inside the double-quoted string). The single quotes around the path are literal characters in the string passed to `eval`. Since `mktemp -d` always returns a path without spaces, this is safe in practice, but the quoting is confusing and fragile. If the temp path ever contained a quote character (non-standard but possible on exotic configs), it would break.

---

#### [MED] `srun()` uses `$*` (word splitting)
**File:** `lib/core.sh`, line 51
```bash
srun() {
    run "sudo $*"
}
```
`$*` expands all positional parameters separated by `IFS`. If arguments contain spaces, they will be word-split at this point before being folded into the `run` string. In practice, `srun` is only called with a single quoted-string argument, so this is safe today, but the interface is misleading — callers might reasonably try `srun cp "$src" "$dest"` and get incorrect behavior.

---

#### [LOW] Hardcoded `HDMI-A-2` monitor name
**File:** `configs/common/hypr/hyprland.conf`, line 1
```
monitor = HDMI-A-2, 1920x1080@75.000, auto, 1
```
This is machine-specific configuration committed as the only monitor line. On any other system this will either not match (no outputs configured) or fail outright. Should be `monitor = ,preferred,auto,1` as the baseline with machine-specific overrides left to the user.

---

#### [LOW] `secrets/.gpg-id` is excluded from `.gitignore`
**File:** `.gitignore`, line 19
```
!secrets/.gpg-id
```
The GPG key ID is committed to the repository. While a key ID alone is not secret, it reveals which GPG key is used for secrets on this system and links the user's identity to this repo. Consider whether this should be gitignored.

---

### Race Conditions & Ordering

---

#### [MED] `sudo_keepalive` called after user confirmation prompt — credential may have expired
**File:** `ricectl`, line 94

`sudo_keepalive` is called after interactive prompts (profile selection, variant detection, install summary, and the "Proceed?" confirm). On a system where the sudo timestamp has already expired, the `sudo -v` inside `sudo_keepalive` will prompt for a password — which is correct. However, the call to `tui_install_summary` and `tui_confirm` (which involve significant user interaction) occurs BEFORE `sudo_keepalive`. If a user takes a long time on these prompts, the keepalive starts from a correct baseline. This is fine, but `sudo_keepalive` would be more robust called at the top of `cmd_install` before any prompts, so the background process starts immediately.

---

#### [MED] `ensure_yay` changes directory inside `eval` subshell but does not restore CWD
**File:** `lib/packages.sh`, line 58
```bash
run "cd '$tmpdir/yay' && makepkg -si --noconfirm"
```
Because `run()` calls `eval "$@"` in the **current shell** (not a subshell), `cd '$tmpdir/yay'` changes the *current process's working directory* if DRY_RUN is false. After `ensure_yay` completes, the shell's CWD is `$tmpdir/yay`, not the original directory. This doesn't crash anything because subsequent paths all use absolute paths, but it is a side effect. `cmd_sync` later calls `cd "$RICECTL_ROOT"` explicitly to compensate for this, but any code path through `ensure_yay` followed by relative-path operations would break.

---

#### [LOW] `cmd_sync push` uses `git add -A` — may accidentally stage secrets or logs
**File:** `ricectl`, line 290
```bash
git add -A
```
This stages all untracked changes in the repo. While `.gitignore` excludes `*.log`, `backups/`, and `secrets/*`, any file not covered by the ignore rules would be staged and committed with a generic `sync:` message. The `add -A` approach is especially risky when the repo is the live `~/.dotfiles` directory.

---

### Dead Code / Unused Configs / Orphaned Scripts

---

#### [HIGH] Scripts duplicated at two paths — `configs/common/hypr/` root AND `configs/common/hypr/scripts/`
**Files:**
- `configs/common/hypr/power_menu.sh` == `configs/common/hypr/scripts/power_menu.sh` (byte-identical)
- `configs/common/hypr/toggle_desktop.sh` == `configs/common/hypr/scripts/toggle_desktop.sh` (byte-identical)
- `configs/common/hypr/waybar-fullscreen.sh` == `configs/common/hypr/scripts/waybar-fullscreen.sh` (byte-identical)

`hyprland.conf` references `~/.config/hypr/scripts/power_menu.sh` (the subdirectory path), so the root-level copies are dead. Both sets get deployed (rsync copies everything), but only the `scripts/` copies are invoked.

---

#### [MED] `configs/common/alacritty/zsh/` — mostly empty placeholder files
**Files:**
- `configs/common/alacritty/zsh/.aliases` — 0 bytes
- `configs/common/alacritty/zsh/.colors` — 0 bytes
- `configs/common/alacritty/zsh/.configs` — 0 bytes
- `configs/common/alacritty/zsh/.hooks` — 0 bytes
- `configs/common/alacritty/zsh/configs/plugins/fzf` — 0 bytes
- `configs/common/alacritty/zsh/configs/prompts/p10k` — 0 bytes

These appear to be stubs for a zsh-config-as-files architecture that was never completed. They are deployed to `~/.config/alacritty/zsh/` on every install but serve no function. The `configs/managers/zinit` file (1688 bytes) duplicates Zinit bootstrap logic already present in `.zshrc`.

---

#### [MED] `gpu-amd` module is a structural no-op
**File:** `modules/gpu-amd/module.yaml`
The module has no packages, no configs, no services, and no post-install hook. Its only purpose is as a profile entry that causes `deploy_module` to run with no effect. The AMD env var exports it presumably intends to own live in `.zshrc` unconditionally.

---

#### [MED] `rofi/themes/gruvbox-dark.rasi` and `rofi/themes/liminal.rasi` are unused
**Files:** `configs/common/rofi/themes/gruvbox-dark.rasi`, `configs/common/rofi/themes/liminal.rasi`

`configs/common/rofi/config.rasi` references only `~/.config/rofi/themes/oxh.rasi`. Neither of the two other themes is referenced anywhere in hyprland keybinds, scripts, or rofi configs. They are deployed but never activated.

---

#### [LOW] `modules/zsh/module.yaml` declares a `configs:` block that is never processed
**File:** `modules/zsh/module.yaml`, lines 9–13
```yaml
configs:
  - source: .zshrc
    dest: ~/.zshrc
  - source: .p10k.zsh
    dest: ~/.p10k.zsh
```
`deploy_module` does not implement `configs:` processing. The zsh post-install hook deploys these files independently via `deploy_file`. This YAML block is dead metadata.

---

#### [LOW] `cava/themes/solarized_dark` and `cava/themes/tricolor` — deployed but not default
**Files:** `configs/common/cava/themes/solarized_dark`, `configs/common/cava/themes/tricolor`

`configs/common/cava/config` uses `color = 'default'` (and `'default` — unclosed quote). The theme files are deployed but the config does not reference them. They must be manually activated.

---

### Style Inconsistencies

---

#### [MED] Inconsistent comment style in `configs/common/` config files

The CLAUDE.md convention is "section-level comments only, not line-by-line." Observed violations:
- `configs/variants/laptop/waybar/style.css` — inline Spanish comments on property values (`/* reducido de 15 → 12 */`) — violates both the English-only rule and the section-level-only rule.
- `configs/common/rofi/scripts/volume.sh` — line-by-line comments on nearly every function (`# Get current volume status`, `# Determine the icon based on volume status`, etc.).
- `configs/common/alacritty/zsh/configs/managers/zinit` — duplicated Zinit bootstrap block with a comment referencing "engineering students."

---

#### [MED] Inconsistent function naming: `run` vs `srun` vs direct `sudo`
`lib/core.sh` defines `run()` and `srun()`. However, `modules/sddm/post-install.sh` uses a bare `sudo tee` outside these wrappers. All privileged operations should go through `srun()` for consistent dry-run support.

---

#### [MED] `pc/waybar/config.jsonc` has no header comment; `laptop/waybar/config.jsonc` has one
The laptop variant has a 5-line header block (`hyprland-ricing by occhi`, path, adapted-for note). The pc variant has none. These are inconsistent with each other and both are inconsistent with the "canonical" form used in other config files.

---

#### [LOW] `pc/waybar/style.css` — `#custom-sep` and `#custom-sep2` declared separately; laptop combines them
- PC: two separate identical rules for `#custom-sep` and `#custom-sep2`
- Laptop: combined selector `#custom-sep, #custom-sep2 { ... }`

Both produce the same output but the styles are not synchronized in maintenance.

---

#### [LOW] Profile YAMLs — inconsistent `variant` values
- `full.yaml`: `variant: auto`
- `rice.yaml`: `variant: auto`
- `dev.yaml`: `variant: ""`
- `minimal.yaml`: `variant: ""`

The empty-string `""` variant and the missing variant have subtly different parse behavior. An empty `""` value will be parsed as an empty string by `parse_yaml`, and `[[ -z "$prof_variant" ]]` evaluates it as "no variant" — so the behavior is equivalent. But the inconsistency (`auto` vs `""` vs omitted) is confusing.

---

### English in Comments / Text

---

#### [HIGH] Spanish inline comments in `configs/variants/laptop/waybar/style.css`
**File:** `configs/variants/laptop/waybar/style.css`, lines 9, 35, 52, 54

```css
font-size: 12px;        /* reducido de 15 → 12 */
padding: 0 5px;         /* reducido de 6 → 5 */
padding: 0 7px;         /* reducido de 9 → 7 */
font-size: 14px;        /* reducido de 18 → 14 */
```
These are in Spanish ("reducido" = "reduced"). CLAUDE.md explicitly states: "All inline comments in English."

---

#### [MED] Misspelling in CSS comment: "calendary"
**Files:** `configs/variants/pc/waybar/style.css` line 172, `configs/variants/laptop/waybar/style.css` line 174

```css
/* ── tooltip (calendary) ───────────────────── */
```
"calendary" is not an English word. Intended: "calendar" or "calendar tooltip."

---

#### [MED] English phrasing in Python string: "without events this month..."
**Files:** `configs/variants/pc/waybar/scripts/clock_calendar.sh` line 79, `configs/variants/laptop/waybar/scripts/clock_calendar.sh` line 79

```python
gcal_section = divider + f'<span ... size="smaller">without events this month...</span>'
```
Grammatically should be "No events this month" (idiomatic English).

---

#### [LOW] Comment in `zinit` helper references "engineering students"
**File:** `configs/common/alacritty/zsh/configs/managers/zinit`, lines 15–16
```
# These are the ones commonly used by engineering students for productivity:
```
This is placeholder/boilerplate text from a generated template, not a meaningful comment for this repository.

---

### OXH Signature Audit

The canonical form (per CLAUDE.md referencing `hypr/hyprland.conf`) should be found in `hyprland.conf` — but `hyprland.conf` has **no header at all**. Based on files that do carry a header, there are two variants in use:

**Variant A** (most common): `# oxh-hyprland-dotfiles by occhi`
**Variant B** (laptop waybar): `// hyprland-ricing by occhi`

| Status | Files |
|--------|-------|
| Has Variant A | `configs/common/alacritty/alacritty.toml`, `configs/common/btop/btop.conf`, `configs/common/cava/config`, `configs/common/cava/themes/tricolor`, `configs/common/cava/themes/solarized_dark`, `configs/common/btop/themes/oxh.theme`, `configs/common/alacritty/zsh/utils/source`, `configs/common/alacritty/zsh/configs/managers/zinit` |
| Has Variant B | `configs/variants/laptop/waybar/config.jsonc`, `configs/variants/laptop/waybar/style.css` |
| Missing entirely | `configs/common/hypr/hyprland.conf`, `configs/common/hypr/hypridle.conf`, `configs/common/hypr/hyprlock.conf`, `configs/common/dunst/dunstrc`, `configs/common/rofi/config.rasi`, `configs/common/rofi/PowerMenu.rasi`, `configs/common/rofi/themes/gruvbox-dark.rasi`, `configs/common/rofi/themes/liminal.rasi`, `configs/common/fastfetch/config.jsonc`, `configs/common/gtk-3.0/settings.ini`, `configs/common/gtk-4.0/settings.ini`, `configs/common/yazi/theme.toml`, `configs/variants/pc/waybar/config.jsonc`, `configs/variants/pc/waybar/style.css`, all 12 `.sh` scripts in `configs/` |

---

## 3. install.sh Deep Review

### Installation Order

`install.sh` is a thin bootstrap that:
1. Checks OS, non-root, internet
2. `sudo pacman -S --needed --noconfirm git rsync curl base-devel`
3. Clones or updates the dotfiles repo
4. `exec "$DOTFILES_DIR/ricectl" install "$@"` — hands off completely

`ricectl install` then runs:
1. `require_not_root`, `require_internet`, `require_arch`
2. Profile selection (interactive or `--profile=`)
3. Variant detection
4. Display summary → confirm
5. `sudo_keepalive`
6. `base_packages` → `install_pacman`
7. `fonts` → `install_pacman`
8. `aur_fonts` → `install_aur` (triggers `ensure_yay` which installs `yay` if absent, pulling base-devel and git — already installed in step 2)
9. `networking` → `install_pacman`
10. `networking_services` → `enable_services`
11. `extras_aur` → `install_aur`
12. For each module: `deploy_module` (packages → common configs → variant configs → services → post-install → fix perms)
13. Wallpaper deployment (`srun`)

**Assessment:** The ordering is reasonable. Prerequisites (git, rsync) are installed by `install.sh` before `ricectl` is reached. `yay` is only bootstrapped when first needed. Services are enabled after packages are installed. The wallpaper deploys last.

**Issue:** There is no explicit step to start or restart `NetworkManager` after enabling it. The service is enabled for next boot but not started in the current session.

### Idempotency

- `install_pacman` and `install_aur` both check `pkg_installed` before installing — idempotent.
- `enable_services` checks `systemctl is-enabled` before enabling — idempotent.
- `deploy_configs` uses rsync with `--backup --suffix=.bak` — re-runs overwrite configs and create `.bak` files, accumulating backups on repeated runs.
- `deploy_file` checks `diff -q` before overwriting — idempotent.
- `ensure_yay` checks `command -v yay` — idempotent.
- `sudo_keepalive` always starts a background loop — on second run, a new background loop is started alongside any existing one. Minor resource leak.
- SDDM post-install checks `[[ ! -f /etc/sddm.conf.d/theme.conf ]]` before writing — idempotent.
- Docker post-install checks `groups "$USER"` before `usermod` — idempotent.

**Overall:** Reasonably idempotent. The rsync `.bak` accumulation on repeated runs is the main maintenance concern.

### Error Handling

- `set -euo pipefail` is set in `install.sh`, `ricectl`, and all `lib/*.sh` — any unhandled error exits immediately.
- `install.sh` wraps `error()` as `error() { ...; exit 1; }` — immediate exit on error.
- `ricectl`'s `error()` (from core.sh) only prints — does NOT exit. Callers must explicitly `exit 1` after calling `error()`. This inconsistency is not a correctness issue in current code (all callers do exit), but it's a maintenance trap.
- Missing internet is checked, but no retry logic exists.
- `git pull --rebase || warn "Git pull failed, using existing version"` — silently continues on pull failure. This could leave the repo in a partially-conflicted state.
- There is no handling for disk-full conditions or partial package installation failures (pacman errors propagate through `eval` and exit via `set -e`).

### Font Coverage

Fonts referenced in configs vs. what profiles install:

| Font | Where Referenced | Installed By |
|------|-----------------|--------------|
| Terminus | `dunstrc`, `hyprlock.conf`, `alacritty.toml`, `sddm/theme.conf` | `ttf-terminus-font` (AUR, `full.yaml` + `rice.yaml` only) |
| JetBrainsMono Nerd Font | `rofi/config.rasi`, `rofi/PowerMenu.rasi`, `rofi/themes/oxh.rasi`, `emote-picker.sh`, waybar CSS | `ttf-jetbrains-mono-nerd` (all profiles) |
| Inconsolata Semi Condensed Bold | waybar CSS (both variants) | **NOT INSTALLED** — no package covers this |
| Iosevka Nerd Font | waybar CSS (both variants) | **NOT INSTALLED** — no package covers this |
| Material Design Icons Desktop | waybar CSS (both variants) | **NOT INSTALLED** — no package covers this |
| Font Awesome 6 Free Solid | waybar CSS (both variants) | `ttf-font-awesome` (`full.yaml`, `rice.yaml`) |
| Noto fonts | general coverage | `noto-fonts`, `noto-fonts-cjk`, `noto-fonts-emoji` |

**Critical gaps:** `Inconsolata Semi Condensed Bold`, `Iosevka Nerd Font`, and `Material Design Icons Desktop` are referenced in the waybar CSS font-family stack but are not installed by any module or profile. Waybar will fall back to `monospace` for these, degrading the UI.

`Terminus` is only installed by `full.yaml` and `rice.yaml` (via `ttf-terminus-font` in `aur-fonts`). `dev.yaml` and `minimal.yaml` do not install it, but `alacritty.toml` (deployed by `alacritty` module, which is in all profiles) requires Terminus. `dev` and `minimal` users will get a fallback font in Alacritty.

### Tool Coverage

External binaries referenced in configs vs. installation status:

| Binary | Where Used | Installed By |
|--------|-----------|--------------|
| `dunst` | hyprland.conf exec-once | `dunst` module (pacman) |
| `waybar` | hyprland.conf exec-once | **waybar module has pacman: []** — NOT installed |
| `hypridle` | hyprland.conf exec-once | `hyprland` module (pacman) |
| `nm-applet` | hyprland.conf exec-once | `network-manager-applet` (profiles) |
| `awww` / `awww-daemon` | hyprland.conf exec-once | **NOT installed anywhere** |
| `hyprpaper` | hyprland module.yaml (installed but unused) | `hyprland` module (pacman) — but not exec'd |
| `hyprlock` | power_menu.sh | `hyprland` module (pacman) |
| `grim` | hyprland.conf keybind | `hyprland` module (pacman) |
| `slurp` | hyprland.conf keybind | `hyprland` module (pacman) |
| `wl-copy` | hyprland.conf keybind | `wl-clipboard` via `hyprland` module (pacman) |
| `hyprctl` | multiple scripts | part of `hyprland` package |
| `rofi` | hyprland.conf keybind, scripts | `rofi` module (AUR: rofi-wayland) |
| `playerctl` | waybar spotify scripts, hypridle.conf | `pipewire` module (pacman) |
| `gcalcli` | hyprland.conf exec-once, waybar clock | `full.yaml` extras_aur — **MISSING from `rice.yaml`** |
| `python3` | waybar clock script | typically system package; not explicitly installed |
| `socat` | waybar-fullscreen.sh | **NOT installed anywhere** |
| `jq` | toggle_desktop.sh | `full.yaml`, `dev.yaml`, `minimal.yaml` base_packages — **MISSING from `rice.yaml`** |
| `pamixer` | rofi/scripts/volume.sh | `pipewire` module (pacman) |
| `dunstify` | rofi/scripts/volume.sh | part of `dunst` package (libnotify provides dunstify) |
| `wtype` | emote-picker.sh | `hyprland` module (pacman) |
| `pavucontrol` | waybar config on-click | `pipewire` module (pacman) |
| `pactl` | waybar config on-click | part of `pipewire-pulse` |
| `wlogout` | `full.yaml` extras_aur | installed in `full.yaml` but **not referenced in any config** |
| `hyprshot` | `hyprland` module AUR | installed but **not referenced in any keybind** |
| `gum` | tui.sh (optional) | not installed by any module/profile (documented as optional) |

**Critical missing:** `awww`, `socat`, `waybar` (binary), and several fonts are not installed. The `rice.yaml` profile is missing `jq` and `gcalcli` which are required by scripts it deploys.

---

## 4. Prioritized Refactor Plan

Batches are independent — each can be applied without depending on later batches.

---

### Batch 1 — Critical Bugs (Break on First Run)

These must be fixed before the dotfiles are used on any new machine.

1. **Fix `hyprlock.conf` double-path typo**
   - File: `configs/common/hypr/hyprlock.conf`, line 4
   - Change: `path = path = /usr/share/backgrounds/y8yxlx.jpg` → `path = /usr/share/backgrounds/y8yxlx.jpg`

2. **Fix `cava/config` unclosed single-quote**
   - File: `configs/common/cava/config`, line 20
   - Change: `foreground = 'default` → `foreground = 'default'`

3. **Resolve wallpaper filename mismatch**
   - Pick one canonical name. Recommendation: rename `assets/wallpaper.jpg` to `assets/y8yxlx.jpg` and deploy it as `/usr/share/backgrounds/y8yxlx.jpg` (aligning with hyprland.conf, hyprlock.conf, sddm theme.conf).
   - File: `ricectl`, lines 148–150: change `oxh-wallpaper.jpg` → `y8yxlx.jpg`

4. **Replace `awww` with `hyprpaper` in `hyprland.conf`**
   - File: `configs/common/hypr/hyprland.conf`, lines 14–15
   - Remove `exec-once = awww-daemon` and `exec-once = sleep 1 && awww img ...`
   - Add: `exec-once = hyprpaper` and a `hyprpaper.conf` with the wallpaper path
   - Or: remove `hyprpaper` from `hyprland` module and add `swww` (AUR) instead

5. **Add `waybar` package to `waybar` module**
   - File: `modules/waybar/module.yaml`
   - Change: `pacman: []` → `pacman:\n  - waybar`

6. **Install missing tools: `socat`, `jq` (rice profile), `gcalcli` (rice profile)**
   - File: `profiles/rice.yaml`
   - Add `jq` and `gcalcli` to `base-packages` and `extras-aur` respectively
   - Add `socat` to `hyprland` module's pacman list (`modules/hyprland/module.yaml`)

7. **Fix `btop.conf` typo**
   - File: `configs/common/btop/btop.conf`, line 11
   - Change: `rounded_corners = Trues` → `rounded_corners = True`

---

### Batch 2 — High-Priority Logic Bugs

8. **Fix `cmd_module list` deployment detection for `kvantum` and `gtk`**
   - File: `ricectl`, lines 354–361
   - Read `config_dir` from each module's YAML before the check, or at minimum add explicit exceptions for `kvantum` → `Kvantum`, `gtk` → `gtk-3.0`, `pipewire`, `sddm`, `qt6ct`

9. **Remove duplicate scripts from `configs/common/hypr/` root**
   - Files: `configs/common/hypr/power_menu.sh`, `toggle_desktop.sh`, `waybar-fullscreen.sh`
   - Delete the root-level copies; keep only `configs/common/hypr/scripts/`

10. **Fix `sddm/post-install.sh` to use `run()` for DRY_RUN compliance**
    - File: `modules/sddm/post-install.sh`, line 12
    - Replace `echo -e '...' | sudo tee ...` with `run "sudo tee /etc/sddm.conf.d/theme.conf <<< '[Theme]\\nCurrent=oxh-sddm'"` or write a temp file approach through `run`

11. **Fix hardcoded monitor name in `hyprland.conf`**
    - File: `configs/common/hypr/hyprland.conf`, line 1
    - Change to `monitor = ,preferred,auto,1` as the common config baseline
    - Document machine-specific overrides as a user-added file (e.g., `~/.config/hypr/monitor-local.conf` sourced via `source`)

---

### Batch 3 — Font and Tool Coverage

12. **Install missing fonts: Inconsolata, Iosevka Nerd Font**
    - Files: `profiles/full.yaml`, `profiles/rice.yaml`
    - Add `ttf-iosevka-nerd` (AUR) to `aur-fonts`
    - Add `otf-inconsolata-nerd` or equivalent to `aur-fonts`
    - OR update the waybar CSS font-family to only use installed fonts

13. **Install `Terminus` in all profiles that deploy `alacritty`**
    - Files: `profiles/dev.yaml`, `profiles/minimal.yaml`
    - Add `ttf-terminus-font` to `aur-fonts` in both profiles

14. **Remove `wlogout` and `hyprshot` from profiles/modules or add keybinds for them**
    - `wlogout` is installed by `full.yaml` but never referenced in any config
    - `hyprshot` is installed by `hyprland` module but not in any keybind
    - Either add keybinds in `hyprland.conf` or remove the packages

---

### Batch 4 — Security Hardening

15. **Replace `curl | bash` recommendation in README with a clone-verify-run flow**
    - File: `README.md`, line 67
    - Replace with a two-step: clone the repo, inspect `install.sh`, then `./install.sh`

16. **Replace `sed /e` in `emote-picker.sh` with safe arithmetic**
    - File: `configs/common/rofi/scripts/emote-picker.sh`, line 61
    - Use `awk` or `python3` to increment the counter without shell execution

17. **Reduce `sudo_keepalive` loop interval or add cleanup trap**
    - File: `lib/core.sh`, line 80
    - Add `trap 'kill $sudo_keepalive_pid 2>/dev/null' EXIT` in callers, or reduce sleep to 30s

---

### Batch 5 — Dead Code Cleanup

18. **Remove empty placeholder files in `configs/common/alacritty/zsh/`**
    - Files: `.aliases`, `.colors`, `.configs`, `.hooks`, `configs/plugins/fzf`, `configs/prompts/p10k`
    - Decide: either implement the zsh helper architecture (populate the files) or remove the entire `zsh/` subtree from `configs/common/alacritty/` and clean up the `helpers` PATH loop in `.zshrc`

19. **Remove unused rofi themes**
    - Files: `configs/common/rofi/themes/gruvbox-dark.rasi`, `configs/common/rofi/themes/liminal.rasi`
    - Delete, or document them as optional themes in a comment

20. **Clean up `gpu-amd` module or make it functional**
    - File: `modules/gpu-amd/module.yaml`
    - Either add a post-install hook that conditionally sets env vars only for AMD GPUs (checking `lspci`), or remove the module from profiles and gate the env vars in `.zshrc` on a GPU check

21. **Remove dead `configs:` block from `zsh/module.yaml` or implement it**
    - File: `modules/zsh/module.yaml`
    - If `deploy_module` will never process `configs:`, delete the block to avoid confusion

---

### Batch 6 — Style / Convention Alignment

22. **Translate Spanish comments to English in `laptop/waybar/style.css`**
    - File: `configs/variants/laptop/waybar/style.css`, lines 9, 35, 52, 54
    - Convert to English or remove — the values are self-explanatory

23. **Add the canonical signature header to all config files missing it**
    - All 12 shell scripts in `configs/`, `hyprland.conf`, `hypridle.conf`, `hyprlock.conf`, `dunstrc`, `rofi/config.rasi`, `rofi/PowerMenu.rasi`, `fastfetch/config.jsonc`, `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`, `yazi/theme.toml`, `pc/waybar/config.jsonc`, `pc/waybar/style.css`
    - Unify on a single variant: `# oxh-hyprland-dotfiles by occhi` (or update CLAUDE.md to define the canonical form explicitly, since `hyprland.conf` has none)

24. **Fix the misleading `mod_count` in install summary**
    - File: `ricectl`, line 85
    - Count only items under the `modules:` section, not all list items across the entire YAML

25. **Standardize profile YAML `variant` field**
    - Files: `profiles/dev.yaml`, `profiles/minimal.yaml`
    - Change `variant: ""` to `variant: none` (or remove the key entirely if `[[ -z "$prof_variant" ]]` handles absent keys correctly — it does via `${prof_variant:-}`)

---

*End of audit — 25 refactor items across 6 independent batches.*
