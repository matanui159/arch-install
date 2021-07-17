#!/usr/bin/env bash
set -e

user=matanui159
repo=https://github.com/$user/arch-install.git

chroot() {
   arch-chroot /mnt $@
}

fishset() {
   chroot fish -c "set -Ux $@"
}

# Install Arch
pacstrap /mnt \
   base linux linux-firmware mandb \
   grub efibootmgr \
   networkmanager \
   fish git \
   sway waybar swayidle swaylock \
   alacritty rofi \
   pulseaudio pavucontrol \
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
echo 'en_US.UTF-8 UTF-8' >> /mnt/etc/locale.gen
chroot locale-gen
chroot localectl set-locale en_US.UTF-8

# Configure hostname
read -p 'Hostname: ' $hostname
hostnamectl hostname $hostname

# Add user and clone dotfiles
chroot useradd -G wheel -s /usr/bin/fish -m $user
chroot passwd $user
echo '%wheel ALL=(ALL) ALL' >> /mnt/etc/sudoers
chroot git clone https://github.com/$user/arch-install.git /home/$user
chroot rm -r /home/$user/{.git,install.sh}
chroot chown -R $user /home/$user

# Configuration for VirtualBox
fishset LIBGL_ALWAYS_SOFTWARE true
fishset WLR_NO_HARDWARE_CURSORS 1
