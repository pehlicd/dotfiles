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

sudo rm -rf /usr/share/sddm/themes/sugar-candy 2>/dev/null
for theme_dir in /usr/share/plymouth/themes/abstract_ring /usr/share/plymouth/themes/vortex; do
  sudo rm -rf "$theme_dir" 2>/dev/null
done
if [ -f "/etc/sddm.conf.d/theme.conf" ]; then
  sudo rm -f /etc/sddm.conf.d/theme.conf
fi
sudo rm -rf /usr/share/backgrounds/dotfiles 2>/dev/null

# ─── 3. Deploy custom Plymouth theme ─────────────────────────────────────────

log_step "Deploying custom Plymouth theme"

sudo rm -rf /usr/share/plymouth/themes/dotfiles
sudo cp -r "$DOTFILES_DIR/default/plymouth" /usr/share/plymouth/themes/dotfiles/
sudo plymouth-set-default-theme dotfiles

# Fix mkinitcpio hooks — clean up duplicates and ensure plymouth is present once
if [ -f "/etc/mkinitcpio.conf" ]; then
  log_info "Fixing mkinitcpio hooks..."
  sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak

  # Remove ALL plymouth occurrences first, then add it back once in the right place
  sudo sed -i 's/ plymouth//g' /etc/mkinitcpio.conf

  # Insert plymouth ONCE after keyboard and before keymap/consolefont/block
  if grep -q "HOOKS=.*keyboard.*encrypt" /etc/mkinitcpio.conf; then
    sudo sed -i '/^HOOKS=/s/keyboard /keyboard plymouth /' /etc/mkinitcpio.conf
  elif grep -q "HOOKS=.*block.*encrypt" /etc/mkinitcpio.conf; then
    sudo sed -i '/^HOOKS=/s/block /block plymouth /' /etc/mkinitcpio.conf
  else
    sudo sed -i '/^HOOKS=/s/HOOKS=(/HOOKS=(plymouth /' /etc/mkinitcpio.conf
  fi

  # Ensure kms is present for early GPU init
  if ! grep -q "kms" /etc/mkinitcpio.conf; then
    sudo sed -i '/^HOOKS=/s/HOOKS=(/HOOKS=(kms /' /etc/mkinitcpio.conf
  fi

  log_info "Rebuilding initramfs..."
  sudo mkinitcpio -P
fi

# Add 'quiet splash' to kernel cmdline for systemd-boot
if [ -d "/boot/loader/entries" ]; then
  log_info "Configuring systemd-boot for Plymouth..."
  for entry in /boot/loader/entries/*.conf; do
    if [ -f "$entry" ] && ! grep -q "splash" "$entry"; then
      # Append 'quiet splash' to the options line
      sudo sed -i '/^options/s/$/ quiet splash/' "$entry"
      log_success "Added 'quiet splash' to $(basename "$entry")"
    fi
  done
# Fallback for GRUB
elif [ -f "/etc/default/grub" ]; then
  if ! grep -q "splash" /etc/default/grub; then
    log_info "Configuring GRUB for Plymouth..."
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
