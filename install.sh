#!/usr/bin/env bash
set -ex

user=matanui159
home=/home/$user
repo=https://github.com/$user/arch-install.git
lang=en_US.UTF-8

chroot() {
   arch-chroot /mnt $@
}

# Install Arch
pacstrap /mnt \
   base linux linux-firmware man \
   grub efibootmgr \
   networkmanager \
   pulseaudio pulseaudio-alsa \
   fish git \
   sway ttf-ibm-plex xorg-xwayland waybar swayidle swaylock \
   alacritty rofi pavucontrol firefox \
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
chroot useradd -d $home -s /usr/bin/fish -G wheel $user
chroot passwd $user
echo '%wheel ALL=(ALL) ALL' >> /mnt/etc/sudoers
chroot systemctl --machine $user@.host --user enable \
   pulseaudio

# Clone dotfiles
chroot git clone $repo $home
chroot rm -r $home/{.git,install.sh}
chroot chown -R $user $home

# Reboot
reboot now
