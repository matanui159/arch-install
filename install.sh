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
   bluez bluez-utils \
   pulseaudio pulseaudio-alsa pulseaudio-bluetooth pamixer \
   fish git \
   sway ttf-ibm-plex xorg-xwayland swayidle swaylock \
   alacritty rofi firefox imv mpv ranger neovim \
   base-devel cmake meson ninja yasm clang \
   yarn python-pip go \
   ffmpeg

chroot systemctl enable \
   NetworkManager \
   bluetooth

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

# Configure bluetooth
echo 'AutoEnable=true' >> /mnt/etc/bluetooth/main.conf

# Clone repo into skeleton
chroot rm -r /etc/skel
chroot git clone $repo /etc/skel
chroot rm -r /etc/skel/{.git,install.sh}

# Add user and enable user services
chroot useradd -d $home -s /usr/bin/fish -G wheel -m $user
chroot passwd $user
echo '%wheel ALL=(ALL) ALL' >> /mnt/etc/sudoers
chroot systemctl --machine $user@.host --user enable \
   pulseaudio

# Install yay
usrdo git clone https://aur.archlinux.org/yay.git $home/yay
arch-chroot /mnt sudo -u $user bash -c "cd $home/yay && makepkg -si --noconfirm"
chroot rm -r $home/yay
usrdo yay -S --noconfirm \
   google-chrome \
   emsdk

# Install Yarn and N
usrdo yarn global add yarn n
usrdo N_PREFIX=$home/.local $home/.yarn/bin/n lts
chroot pacman -Rs --noconfirm yarn

# Install VirtualFish
usrdo pip install virtualfish
usrdo $home/.local/bin/vf install auto_activation

# Install Emscripten
chroot emsdk install latest
chroot emsdk activate latest

# Reboot
reboot now
