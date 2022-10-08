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





#######################
# Connect to Wi-Fi
#######################
station wlan0 scan
sleep 5
station wlan0 get-networks

echo -n "Please type the name of the Wi-Fi network: "
read SSID
echo -n "Please type the password of the Wi-Fi network: "
read PSK

iwctl --passphrase=$PSK station wlan0 connect SSID




#######################
# Configure ISO for installation
#######################
# Download up to 30 things at once so it's significantly faster
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 30/" /etc/pacman.conf

# Update archlinux-keyring to avoid unnecessary errors
pacman --noconfirm -Sy archlinux-keyring


# Load US keyboard layout
loadkeys us

# Fix date and time
timedatectl set-ntp true


#######################
# Format Disks
#######################

# Get drive names
# "sda"
# "sdb"
Drives=$(lsblk -J | jq ".blockdevices[]" | jq ".name") 




Partitions=



# Select drive to partition
echo -n "Enter the drive (ie, /dev/sda) to install on: "
read Drive

# Wipe the drive
wipefs -a $Drive



# Create GPT Partition Table
sudo sgdisk -o $Drive 
sfdisk $Drive 





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






#######################
# Pacstrap Packages
#######################
$PacstrapPackages=[
	base,
	base-devel,
	linux,
	linux-firmware,
	NetworkManager, # So I can connect to Wi-Fi on reboot
	amd-ucode,
	reflector,
]
pacstrap /mnt $PacstrapPackages





# Generate an /etc/fstab and append it to /mnt/etc/fstab
genfstab -U /mnt >> /mnt/etc/fsta
# Don't know what this really does, bugswriter does, though.
sed '1,/^#part2$/d' `basename $0` > /mnt/arch-install2.sh
#mv /home/arch-install2.sh /mnt
chmod +x /mnt/arch-install2.sh
arch-chroot /mnt ./arch-install2.sh
exit

#part2
clear


#######################
# Install Essential Packages
#######################
$Apps=[
	
	
]


# Install Intel Microcode
pacman -S --noconfirm intel-ucode
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




#######################
# Install Applications
#######################
$Apps=[
	# Standard Install
	vim,
	xorg,
	xorg-xinit,
	xorg-server,
	git,
	firefox,
	feh, # Image viewer
	lightdm,
	lightdm-webkit2-greeter,
	dm-tool,
	ufw,
	openssh,
	bitwarden,
	bitwarden-cli,
	rofi, # FAR superior to dmenu
	zsh, # Better than bash
	maim, # Screenshots
	scot, # Terminal Screenshots
	xclip, # Copying from the command line is essential
	mpv, # media player
	alcritty, # terminal emulator
	pipewire,
	pipewire-alsa,
	pipewire-pulse,
	pavucontrol,
	ttf-cascadia-code,
	sudo,
	bluez,
	bluez-utils,
	jq, # Appearntly this is essential for me now

	# Multilib Apps
	lib32-pipewire,
	discord,
	steam,
	ttf-liberation

	# nvidia GPU 
	nvidia,
	nvidia-utils,
	lib32-nvidia-utils,
	nvidia-settings,
	vulkan-icd-loader,
	lib32-vulkan-icd-loader,
]


# Update mirrorlist
reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# Enable Multilib then install
sed -i "s/^#[multilib]$/^[multilib]$/" /etc/pacman.conf
sed -i "s/^#Include = /etc/pacman.d/mirrorlist/^Include = /etc/pacman.d/mirrorlist$/" /etc/pacman.conf
pacman -S --noconfirm $Apps


#######################
# Configure Applications
#######################

# Configure lightdm
sed -i 's/^.greeter-session=.*$/greeter-session=lightdm-webkit2-greeter' /etc/lightdm/lightdm.conf


# Configure pacman
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 30/" /etc/pacman.conf


#######################
# Configure Home
#######################
$Username=jstiverson
mkdir /home/$Username/{Downloads,Documents,Desktop,Videos,Scripts,.config,Pictures}
mkdir -p /home/$Username/Pictures/Wallpapers/



#######################
# Enable Services
#######################
systemctl enable lightdm
systemctl enable NetworkManager







# Update after enabling multilib and other pacman.conf options
pacman -Syu
# Install a few multilib programs
# Update grub after configuration
grub-mkconfig -o /boot/grub/grub.cfg
# Install Paru (AUR helper)
git clone https://aur.archlinux.org/paru.git /home/$username/paru
cd /home/$username/paru
makepkg -fsri


# remove dotfiles directory
rm -rf /home/$username/dotfiles

# Chown the home directory
chown -R /home/$username $username

clear
echo "Installation Complete! Please reboot now!"

sleep 2s
exit
