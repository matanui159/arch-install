#!/usr/bin/env bash
set -ex

user=matanui159
repo=https://github.com/$user/arch-install.git
lang=en_US.UTF-8

chroot() {
   arch-chroot /mnt $@
}

fishset() {
   chroot fish -c "set -Ux $@"
}

# Install Arch
pacstrap /mnt \
   base linux linux-firmware man \
   grub efibootmgr \
   networkmanager \
   fish git \
   sway xwayland waybar swayidle swaylock \
   alacritty rofi pavucontrol \
   base-devel cmake meson ninja yasm clang \
   ffmpeg \
   nano

chroot systemctl enable \
   NetworkManager

genfstab /mnt >> /mnt/etc/fstab

# Install GRUB
chroot grub-install --efi-directory=/efi
chroot grub-mkconfig -o /boot/grub/grub.cfg

# Configure timezone
chroot timedatectl set-ntp true
chroot timedatectl set-timezone Australia/Brisbane

# Configure locale
echo "$lang UTF-8" >> /mnt/etc/locale.gen
chroot locale-gen
chroot localectl set-locale $lang

# Configure hostname
read -p 'Hostname: ' hostname
hostnamectl set-hostname $hostname

# Add user and clone dotfiles
chroot useradd -G wheel -s /usr/bin/fish $user
chroot passwd $user
echo '%wheel ALL=(ALL) ALL' >> /mnt/etc/sudoers
chroot git clone https://github.com/$user/arch-install.git /home/$user
chroot rm -r /home/$user/{.git,install.sh}
chroot chown -R $user /home/$user

# Configuration for VirtualBox
fishset LIBGL_ALWAYS_SOFTWARE true
fishset WLR_NO_HARDWARE_CURSORS 1

# Reboot
reboot now
