#!/usr/bin/env bash
set -ex

user=matanui159
home=/home/$user
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
   sway ttf-ibm-plex xorg-xwayland swayidle swaylock \
   alacritty rofi pavucontrol firefox neovim \
   base-devel cmake meson ninja yasm clang \
   yarn go \
   ffmpeg

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

# Add user and enable user services
chroot useradd -k /skel -m -d $home -s /usr/bin/fish -G wheel $user
chroot passwd $user
echo '%wheel ALL=(ALL) ALL' >> /mnt/etc/sudoers
chroot systemctl --machine $user@.host --user enable \
   pulseaudio

# Clone dotfiles
usrdo git clone $repo $home
usrdo rm -r $home/{.git,install.sh}

# Install yay
chroot git clone https://aur.archlinux.org/yay.git
arch-chroot /mnt bash -c 'cd /yay && makepkg -si'
chroot rm -r /yay
usrdo yay -S --noconfirm \
   google-chrome \
   emsdk

# Install Yarn and N
usrdo yarn global add yarn n
usrdo n lts
chroot pacman -Rs --noconfirm yarn

# Install emsdk
chroot emsdk install latest
chroot emsdk activate latest

# Reboot
reboot now
