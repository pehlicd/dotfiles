#!/bin/bash
# Cleanup old theme setup and migrate to custom Omarchy-style themes
# This script is intended to be run once to clean up the old Sugar Candy / adi1090x approach.

source "$HOME/.local/share/dotfiles/bin/lib/helpers.sh"

log_header "Cleaning up old theme setup"

# Remove old Sugar Candy SDDM theme if installed
if pacman -Qq sddm-theme-sugar-candy-git &>/dev/null; then
  log_info "Removing sddm-theme-sugar-candy-git..."
  sudo pacman -Rns --noconfirm sddm-theme-sugar-candy-git 2>/dev/null || true
fi

# Remove old adi1090x Plymouth themes if installed
if pacman -Qq plymouth-themes-adi1090x-git &>/dev/null; then
  log_info "Removing plymouth-themes-adi1090x-git..."
  sudo pacman -Rns --noconfirm plymouth-themes-adi1090x-git 2>/dev/null || true
fi

# Remove leftover Qt5 deps that were only needed for Sugar Candy
for pkg in qt5-graphicaleffects qt5-quickcontrols2 qt5-svg; do
  if pacman -Qq "$pkg" &>/dev/null; then
    log_info "Removing $pkg..."
    sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null || true
  fi
done

# Remove old Sugar Candy theme directory and config
if [ -d "/usr/share/sddm/themes/sugar-candy" ]; then
  log_info "Removing /usr/share/sddm/themes/sugar-candy/..."
  sudo rm -rf /usr/share/sddm/themes/sugar-candy
fi

# Remove old SDDM theme.conf.user if it references sugar-candy
if [ -f "/etc/sddm.conf.d/theme.conf" ]; then
  if grep -q "sugar-candy" /etc/sddm.conf.d/theme.conf; then
    log_info "Removing old SDDM theme.conf..."
    sudo rm -f /etc/sddm.conf.d/theme.conf
  fi
fi

# Remove old adi1090x plymouth theme directories
for theme_dir in /usr/share/plymouth/themes/abstract_ring /usr/share/plymouth/themes/vortex; do
  if [ -d "$theme_dir" ]; then
    log_info "Removing $theme_dir..."
    sudo rm -rf "$theme_dir"
  fi
done

# Deploy new custom themes
log_step "Deploying custom themes"

DOTFILES_DIR="$HOME/.local/share/dotfiles"

# Deploy custom Plymouth theme
log_info "Installing custom Plymouth theme..."
sudo rm -rf /usr/share/plymouth/themes/dotfiles
sudo cp -r "$DOTFILES_DIR/default/plymouth" /usr/share/plymouth/themes/dotfiles/
sudo plymouth-set-default-theme -R dotfiles

# Deploy custom SDDM theme
log_info "Installing custom SDDM theme..."
sudo rm -rf /usr/share/sddm/themes/dotfiles
sudo cp -r "$DOTFILES_DIR/default/sddm/dotfiles" /usr/share/sddm/themes/dotfiles/

# Update SDDM config
sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null
[Autologin]
User=$USER
Session=hyprland-uwsm

[Theme]
Current=dotfiles
EOF

log_success "Cleanup and migration complete!"
log_info "Reboot to see your new boot splash and login screen."
