#!/bin/bash

printf "\033c" #reset the terminal
echo "Arch install script"

if [[ $EUID -ne 0 ]]; then
 echo "Please run as super user"
 exit 1
fi

# setup wifi
read -p "using wifi? [y/N] " WIFI
if [[ $WIFI = "y" ]]; then
 read -p "SSID: " SSID
 read -p "passphrase: " PASSPHRS
 read -p "device: " DEVICE
 iwctl --passphrase $PASSPHRS station $DEVICE connect $SSID
fi

sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring

loadkeys us
timedatectl set-ntp true

# disk partition
echo ""
lsblk
echo "Enter the drive: "
read DRIVE
cfdisk /dev/$DRIVE

# FS fmt
lsblk
echo ""
echo "Enter the linux partition: "
read PRTN
mkfs.ext4 /dev/$PRTN
mount /dev/$PRTN /mnt

echo ""
echo "Enter the EFI partition: "
read PRTN
mkfs.fat -F 32 /dev/$PRTN
mount --mkdir /dev/$PRTN /mnt/boot

echo ""
echo "Enter the swap partition: "
read PRTN
mkswap /dev/$PRTN
swapon /dev/$PRTN

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
read HOSTNAME
echo $HOSTNAME > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $HOSTNAME" >> /etc/hosts

#mkinitcpio -P

passwd

pacman --noconfirm -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager

# create user
read -p "create new user: " USRNAME
useradd -m -g users -G audio,video,network,storage,rfkill,wheel -s /bin/bash $USRNAME
passwd $USRNAME
EDITOR=vim visudo
exit
