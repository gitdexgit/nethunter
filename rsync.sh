#!/bin/bash
#
# Dotfile sync script — adapted for Kali NetHunter (Android)
# Always runs as root on NetHunter
set -e

# --- User Detection (NetHunter — always root) ---
if [[ $EUID -ne 0 ]]; then
    echo "❌ Run as root."
    exit 1
fi

ORIGINAL_USER="root"
HOME_DIR="/root"

echo "🚀 Syncing for user '$ORIGINAL_USER' from '$HOME_DIR'"

# --- Configuration ---
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
EXCLUDE_ARRAY=(--exclude='*.dat' --exclude='.git')

# --- System Targets (NetHunter/Kali adapted) ---
SYSTEM_TARGETS=(
    "/etc/fstab"
    "/etc/environment"
    "/etc/sudoers"
    "/etc/sudoers.d"
    "/etc/nftables.conf"
    "/etc/i3"
    "/etc/hostname"
    "/etc/locale.gen"
    "/etc/keyd"
    "/etc/de"
    "/usr/bin/keyd-application-mapper"
    "/usr/bin/keyd-application-mapper.bak"
    "/usr/local/bin"
    "/etc/apt/sources.list"
    "/etc/apt/sources.list.d"
)

# --- Home Targets ---
HOME_TARGETS=(
    ".zshrc"
    ".urxvt"
    ".Xresources"
    ".zshenv"
    ".gitconfig"
    "programming_challenges_for_learning.md"
    "challenges.md"
    ".tmux.conf"
    ".xprofile"
    ".xbindkeysrc"
    ".bashrc"
    ".vimrc"
    "scripts"
    ".oh-my-zsh/custom"
    ".tmux"
    ".themes"
    "themes"
    "Documents/Bookmarks"
    ".config/yazi"
    ".config/warpd"
    ".config/zk"
    ".config/feh"
    ".config/alacritty"
    ".config/kitty"
    ".config/pipewire"
    ".config/wireplumber"
    ".config/mimeapps.list"
    ".config/picom/picom.conf"
    ".config/espanso"
    ".config/copyq"
    ".config/vimb"
    ".config/autostart"
    ".config/lxqt"
    ".config/gtk-3.0"
    ".config/Thunar"
    ".config/vlc"
    ".config/qterminal.org"
    ".config/mpv"
    ".config/nvim2"
    ".config/input-remapper-2"
    ".config/openbox"
    ".config/gh/config.yml"
    ".config/openrazer"
    ".config/rofi"
    ".config/i3"
    ".config/zathura"
    ".config/skippy-xd"
    ".config/devilspie2"
    ".config/zsh"
    ".config/tmux-sessionizer"
    ".local/share/applications"
    ".local/share/fonts"
    ".local/scripts"
    ".local/bin"
)

# --- Sync Home ---
echo ""
echo "👤 Syncing home targets from $HOME_DIR..."
for target in "${HOME_TARGETS[@]}"; do
    source_path="$HOME_DIR/$target"
    dest_path="$REPO_DIR/$target"
    if [ -f "$source_path" ]; then
        echo "   - file: ~/$target"
        mkdir -p "$(dirname "$dest_path")"
        rsync -a "$source_path" "$dest_path"
    elif [ -d "$source_path" ]; then
        echo "   - dir:  ~/$target/"
        mkdir -p "$dest_path"
        rsync -a --delete "${EXCLUDE_ARRAY[@]}" "$source_path/" "$dest_path/"
    else
        echo "   - SKIP: ~/$target not found."
    fi
done

# --- Sync System ---
echo ""
echo "⚙️  Syncing system targets..."
for target in "${SYSTEM_TARGETS[@]}"; do
    if [ -e "$target" ]; then
        echo "   - $target"
        rsync -aR --delete "${EXCLUDE_ARRAY[@]}" "$target" "$REPO_DIR/"
    else
        echo "   - SKIP: $target not found."
    fi
done

# --- Package Lists ---
echo ""
echo "📦 Capturing package lists..."
PKG_DIR="$REPO_DIR/package-lists"
mkdir -p "$PKG_DIR"

# Manually installed packages (what you explicitly apt install'd)
apt-mark showmanual > "$PKG_DIR/apt-manual.txt"
echo "   - apt-manual.txt"

# Full installed list with versions
dpkg --get-selections > "$PKG_DIR/apt-all.txt"
echo "   - apt-all.txt"

# NetHunter/Kali meta-packages only
dpkg --get-selections | grep "kali\|nethunter" > "$PKG_DIR/nethunter-tools.txt" || true
echo "   - nethunter-tools.txt"

# Flatpak if installed
if command -v flatpak &>/dev/null; then
    flatpak list --app --columns=application > "$PKG_DIR/flatpak.txt"
    echo "   - flatpak.txt"
fi

# pip global packages
if command -v pip3 &>/dev/null; then
    pip3 freeze > "$PKG_DIR/pip-global.txt"
    echo "   - pip-global.txt"
fi

# npm global packages
if command -v npm &>/dev/null; then
    npm list -g --depth=0 2>/dev/null > "$PKG_DIR/npm-global.txt"
    echo "   - npm-global.txt"
fi

# --- Fix Perms ---
echo ""
echo "🔐 Fixing ownership → '$ORIGINAL_USER'..."
chown -R "$ORIGINAL_USER":"$(id -gn "$ORIGINAL_USER")" "$REPO_DIR"
echo "✅ Done."
