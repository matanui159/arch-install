#!/usr/bin/env bash
set -ex

user=matanui159
repo=https://github.com/$user/arch-install.git
lang=en_US.UTF-8

chroot() {
   arch-chroot /mnt $@
}

usrdo() {
   chroot sudo -u $user $@
}

# Install Arch
pacstrap /mnt \
   base linux linux-firmware man \
   grub efibootmgr \
   networkmanager \
   pulseaudio pulseaudio-alsa \
   fish git \
   sway ttf-ibm-plex xorg-xwayland waybar swayidle swaylock \
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

# Add user and enable services
chroot useradd -G wheel -s /usr/bin/fish $user
chroot passwd $user
echo '%wheel ALL=(ALL) ALL' >> /mnt/etc/sudoers
usrdo systemctl --user enable \
   pulseaudio

# Clone dotfiles
usrdo git clone https://github.com/$user/arch-install.git /home/$user
usrdo rm -r /home/$user/{.git,install.sh}

# Reboot
reboot now
