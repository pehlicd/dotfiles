#!/bin/bash
# Cleanup old theme setup and migrate to custom Omarchy-style themes
# Run this ONCE to clean up old Sugar Candy / adi1090x and deploy new custom themes.

source "$HOME/.local/share/dotfiles/bin/lib/helpers.sh"

DOTFILES_DIR="$HOME/.local/share/dotfiles"

log_header "Cleaning up old theme setup"

# ─── 1. Remove old packages ───────────────────────────────────────────────────

for pkg in sddm-theme-sugar-candy-git plymouth-themes-adi1090x-git qt5-graphicaleffects qt5-quickcontrols2 qt5-svg; do
  if pacman -Qq "$pkg" &>/dev/null; then
    log_info "Removing $pkg..."
    sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null || true
  fi
done

# ─── 2. Remove old theme directories ─────────────────────────────────────────

# Sugar Candy
sudo rm -rf /usr/share/sddm/themes/sugar-candy 2>/dev/null

# adi1090x themes
for theme_dir in /usr/share/plymouth/themes/abstract_ring /usr/share/plymouth/themes/vortex; do
  sudo rm -rf "$theme_dir" 2>/dev/null
done

# Old SDDM config pointing to sugar-candy
if [ -f "/etc/sddm.conf.d/theme.conf" ]; then
  sudo rm -f /etc/sddm.conf.d/theme.conf
fi

# Old wallpaper sync directory (no longer needed with custom theme)
sudo rm -rf /usr/share/backgrounds/dotfiles 2>/dev/null

# ─── 3. Deploy custom Plymouth theme ─────────────────────────────────────────

log_step "Deploying custom Plymouth theme"

sudo rm -rf /usr/share/plymouth/themes/dotfiles
sudo cp -r "$DOTFILES_DIR/default/plymouth" /usr/share/plymouth/themes/dotfiles/
sudo plymouth-set-default-theme dotfiles

# Configure mkinitcpio hooks for Plymouth + LUKS
if [ -f "/etc/mkinitcpio.conf" ]; then
  if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
    log_info "Adding plymouth hook to mkinitcpio.conf..."
    sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak

    # Insert plymouth AFTER kms/keyboard and BEFORE encrypt
    if grep -q "HOOKS=(.*keyboard.*encrypt.*)" /etc/mkinitcpio.conf; then
      sudo sed -i 's/keyboard /keyboard plymouth /' /etc/mkinitcpio.conf
    elif grep -q "HOOKS=(.*block.*encrypt.*)" /etc/mkinitcpio.conf; then
      sudo sed -i 's/block /block plymouth /' /etc/mkinitcpio.conf
    else
      sudo sed -i 's/HOOKS=(/HOOKS=(plymouth /' /etc/mkinitcpio.conf
    fi
  fi

  # Ensure kms is early in hooks (required for Plymouth to display graphics)
  if ! grep -q "kms" /etc/mkinitcpio.conf; then
    log_info "Adding kms hook for early GPU init..."
    sudo sed -i 's/HOOKS=(/HOOKS=(kms /' /etc/mkinitcpio.conf
  fi

  log_info "Rebuilding initramfs..."
  sudo mkinitcpio -P
fi

# Configure GRUB for quiet splash boot
if [ -f "/etc/default/grub" ]; then
  if ! grep -q "splash" /etc/default/grub; then
    log_info "Adding 'quiet splash' to GRUB..."
    sudo cp /etc/default/grub /etc/default/grub.bak
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash /' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi
fi

log_success "Plymouth deployed"

# ─── 4. Deploy custom SDDM theme ─────────────────────────────────────────────

log_step "Deploying custom SDDM theme"

sudo rm -rf /usr/share/sddm/themes/dotfiles
sudo cp -r "$DOTFILES_DIR/default/sddm/dotfiles" /usr/share/sddm/themes/dotfiles/

sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null
[Autologin]
User=$USER
Session=hyprland-uwsm

[Theme]
Current=dotfiles
EOF

log_success "SDDM deployed"

# ─── 5. Done ─────────────────────────────────────────────────────────────────

log_success "Cleanup and migration complete!"
log_info "Reboot to see your new boot splash and login screen."
