#!/bin/bash

printf "\033c" #reset the terminal
echo "Arch install script"

if [[ $EUID -ne 0 ]]; then
 echo "Please run as super user"
 exit 1
fi

# setup wifi
read -p "using wifi? [y/N] " wifi
if [[ $wifi = "y" ]]; then
 read -p "SSID: " SSID
 read -p "passphrase: " passphrase
 read -p "device: " device
 iwctl --passphrase $passphrase station $device connect $SSID
fi

sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring

loadkeys us
timedatectl set-ntp true

# disk partition
echo ""
lsblk
echo "Enter the drive: "
read drive
cfdisk $drive 

# FS fmt
lsblk
echo ""
echo "Enter the linux partition: "
read partition
mkfs.ext4 $partition
mount $partition /mnt

echo ""
echo "Enter the EFI partition: "
read partition
mkfs.fat -F 32 $partition
mount --mkdir $partition /mnt/boot

echo ""
echo "Enter the swap partition: "
read partition
mkswap $partition
swapon $partition

# base install
pacstrap -K /mnt base base-devel linux linux-firmware man-db man-pages texinfo networkmanager xterm vim
genfstab -U /mnt >> /mnt/etc/fstab

sed '1,/^#part2$/d' `basename $0` > /mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit

#part2
printf '\033c'

pacman -S --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 10/" /etc/pacman.conf

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "KEYMAP=us" > /etc/vconsole.conf

echo "Hostname: "
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname" >> /etc/hosts

mkinitcpio -P

passwd

pacman --noconfirm -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager

# create user
read -p "create new user: " username
useradd -m -g users -G audio,video,network,storage,rfkill,wheel -s /bin/bash $username
passwd $username
EDITOR=vim visudo
exit
