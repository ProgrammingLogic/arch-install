#!/bin/bash

# ARCH INSTALL
#   ____ _  __
#  / ___| |/ /
# | |   | ' /
# | |___| . \
#  \____|_|\_\
#
# https://github.com/CalvinKev/arch-install
#
# DISCLAIMER: This script is not meant to work for everyone. This script is meant only meant for myself.
#
# Credit to bugswriter for many of this stolen code.
#
# Make sure to run as root.

#part1
clear

  echo "Welcome to CalvinKev's Arch installer."

# Change ParallelDownloads from "5" to "15"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
# Update archlinux-keyring to avoid unnecessary errors
pacman --noconfirm -Sy archlinux-keyring
# Load US keyboard layout
loadkeys us
# Fix date and time
timedatectl set-ntp true

# Select drive to partition
lsblk
echo "Enter the drive you wish to partition: "
read drive
cfdisk $drive

# Select partitions to format

# Root/Linux partition
lsblk
echo "Enter the root partiton/Linux filesystem: "
read partition
mkfs.ext4 $partition

# Boot partition
lsblk
echo "Enter boot partition (EFI): "
read efipartition
mkfs.fat -F32 $efipartition

# Mount root partition to /mnt
lsblk
mount $partition /mnt
# Pacstrap the needed packages
pacstrap /mnt base base-devel linux linux-firmware
# Generate an /etc/fstab and append it to /mnt/etc/fstab
genfstab -U /mnt >> /mnt/etc/fstab
# Don't know what this really does, bugswriter does, though.
sed '1,/^#part2$/d' `basename $0` > /mnt/arch-install2.sh
#mv /home/arch-install2.sh /mnt
chmod +x /mnt/arch-install2.sh
arch-chroot /mnt ./arch-install2.sh
exit

#part2
clear

# Install Intel Microcode
pacman -S --noconfirm intel-ucode dhcpcd
# Change ParallelDownloads from 5 to 15
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
# Set timezone
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
# Sync hardware clock with Arch Linux
hwclock --systohc
# Set locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
# Generate locale
locale-gen
# Set locale.conf
echo "LANG=en_US.UTF-8" > /etc/locale.conf
# Set hostname
echo "Hostname: "
read hostname
echo $hostname > /etc/hostname

# Configure /etc/hosts
echo "127.0.0.1		localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.1.1		$hostname.localdomain	$hostname >> /etc/hosts"

# Change root password
passwd
# Select a username
echo "Enter your desired username: "
read username
# Groups
echo "What groups do you want your user to be a part of? (Ex: wheel,audio,video) "
read groups
# Create user account
useradd -mG $groups $username
# Set user password
passwd $username
# Configure sudo
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# GRUB
pacman --noconfirm -S grub efibootmgr

lsblk
echo "Enter EFI partition: "
read efipartition
mkdir /boot/efi
mount $efipartition /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable dhcpcd.service
systemctl enable dhcpcd.service

pacman -S --noconfirm feh vim neofetch htop xorg xorg-xinit git ttf-cascadia-code firefox picom git dmenu mpv zsh sxhkd maim xclip scrot alacritty pipewire pipewire-alsa pipewire-pulse pavucontrol

#part3

mkdir /home/$username/.config

# dwm
git clone https://github.com/CalvinKev/dwm-arch.git /home/$username/.config/dwm
make -C /home/$username/.config/dwm clean install
rm -rf /home/$username/.config/dwm/.git*
rm -rf /home/$username/.config/dwm/LICENSE
rm -rf /home/$username/.config/dwm/README.md
rm -rf /home/$username/.config/dwm/config.h

# st
#git clone https://github.com/CalvinKev/st.git /home/$username/.config/st
#make -C /home/$username/.config/st clean install
#rm -rf /home/$username/.config/st/.git*
#rm -rf /home/$username/.config/st/LICENSE
#rm -rf /home/$username/.config/st/README.md
#rm -rf /home/$username/.config/st/config.h

mkdir /home/$username/Downloads
mkdir /home/$username/Documents
mkdir /home/$username/Videos
mkdir /home/$username/Scripts

# wallpapers
git clone https://github.com/CalvinKev/wallpapers.git /home/$username/Pictures/wallpapers
rm -rf /home/$username/Pictures/wallpapers/.git
rm -rf /home/$username/Pictures/wallpapers/LICENSE
rm -rf /home/$username/Pictures/wallpapers/README.md

# dotfiles
git clone https://github.com/CalvinKev/dotfiles.git /home/$username/dotfiles
# alacritty
mkdir -p /home/$username/.config/alacritty
mv /home/$username/dotfiles/alacritty/alacritty.yml /home/$username/.config/alacritty
# sxhkd
mkdir -p /home/$username/.config/sxhkd
mv /home/$username/dotfiles/sxhkd/sxhkdrc-standalone /home/$username/.config/sxhkd
mv /home/$username/.config/sxhkd/sxhkdrc-standalone /home/$username/.config/sxhkd/sxhkdrc
# zsh
mv /home/$username/dotfiles/shells/.zshrc /home/$username
# .xinitrc
mv /home/$username/dotfiles/xorg/xinitrc /home/$username
mv /home/$username/xinitrc /home/$username/.xinitrc
# date.sh
mv /home/$username/dotfiles/scripts/date.sh /home/$username/Scripts
chmod +x /home/$username/Scripts/date.sh
# pacman.conf
rm -rf /etc/pacman.conf
mv /home/$username/dotfiles/arch/pacman.conf /etc/
# GRUB
rm -rf /etc/default/grub
mv /home/$username/dotfiles/arch/grub /etc/default/
# picom
mkdir -p /home/$username/.config/picom
mv /home/$username/dotfiles/picom/picom.conf /home/$username/.config/picom
# nvidia
mkdir -p /etc/X11/xorg.conf.d
mv /home/$username/dotfiles/nvidia/20-nvidia.conf /etc/X11/xorg.conf.d
# remove dotfiles directory
rm -rf /home/$username/dotfiles

# Chown the home directory
chown -R /home/$username $username

# Update after enabling multilib and other pacman.conf options
pacman -Syu
# Install a few multilib programs
pacman -S --noconfirm lib32-pipewire discord steam ttf-liberation
# Install NVIDIA drivers
pacman -S --noconfirm --needed nvidia nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader
# Update grub after configuration
grub-mkconfig -o /boot/grub/grub.cfg
# Install Paru (AUR helper)
git clone https://aur.archlinux.org/paru.git /home/$username/paru
cd /home/$username/paru
makepkg -fsri
#rm -rf /home/$username/paru

clear
echo "Installation Complete! Please reboot now!"

sleep 2s
exit
