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

codeext() {
   usrdo code --install-extension $1
}

# Install Arch
pacstrap -i /mnt \
   base linux linux-firmware mkinitcpio man-db man-pages mesa \
   grub efibootmgr \
   networkmanager \
   bluez bluez-utils \
   pulseaudio pulseaudio-alsa libldac pamixer \
   fish fscrypt git git-lfs \
   noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono \
   sway swayidle swaylock xorg-xwayland mako wl-clipboard grim slurp \
   alacritty rofi firefox imv mpv ranger discord \
   base-devel cmake ninja yasm clang \
   yarn python-pip \
   chromium ffmpeg

chroot systemctl enable NetworkManager bluetooth
genfstab /mnt >> /mnt/etc/fstab

# Install multilib
cat >> /mnt/etc/pacman.conf << EOF
[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
chroot pacman -Sy lib32-mesa steam

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
chroot hostnamectl set-hostname $hostname

# Configure bluetooth
chroot sed s/\#AutoEnable=false/AutoEnable=true/ -i /etc/bluetooth/main.conf

# Add user
chroot useradd -k empty -d $home -s /usr/bin/fish -G wheel -m $user
chroot passwd $user
echo '%wheel ALL=(ALL) ALL' >> /mnt/etc/sudoers

# Encrypt home directory
chroot fscrypt setup
chroot sed -i /etc/pam.d/system-login \
   -e '/auth.*system-auth/a\auth optional pam_fscrypt.so' \
   -e '/session.*pam_systemd.so/i\session optional pam_fscrypt.so'
echo 'password optional pam_fscrypt.so' >> /mnt/etc/pam.d/passwd
usrdo fscrypt encrypt --source=pam_passphrase

# Clone dotfiles
usrdo git clone $repo $home
usrdo rm -r $home/{.git,install.sh}

# Install Yay and Yay packages
usrdo git clone https://aur.archlinux.org/yay.git $home/yay
arch-chroot /mnt sudo -u $user bash -c "cd $home/yay && makepkg -si --noconfirm"
chroot rm -r $home/yay
usrdo yay -S --noconfirm \
   pulseaudio-modules-bt \
   ttf-twemoji \
   visual-studio-code-bin slack-desktop \
   emsdk \
   google-cloud-sdk google-cloud-sdk-app-engine-python google-cloud-sdk-app-engine-python-extras google-cloud-sdk-datastore-emulator \

# Install Yarn packages
usrdo yarn global add yarn n
usrdo N_PREFIX=$home/.local $home/.yarn/bin/n lts
chroot pacman -Rs --noconfirm yarn

# Install Pip packages
usrdo pip install virtualfish meson
usrdo $home/.local/bin/vf install auto_activation

# Install VSCode Extensions
codeext monokai.theme-monokai-pro-vscode
codeext vscodevim.vim
codeext skattyadz.vscode-quick-scope
codeext bmalehorn.vscode-fish
codeext ms-vscode.cpptools
codeext ms-vscode.cmake-tools
codeext asabil.meson
codeext dbaeumer.vscode-eslint

# Install Emscripten
chroot emsdk install latest
chroot emsdk activate latest

# Reboot
chroot timedatectl status
sleep 60
systemctl reboot
