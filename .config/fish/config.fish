if status is-login && test (tty) = /dev/tty1
   timedatectl set-ntp true
   timedatectl set-timezone Australia/Brisbane
   sway
end
