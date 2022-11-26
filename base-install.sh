printf "\033c" #reset the terminal
echo "Base XFCE4 install script"

if [[ $EUID -ne 0 ]]; then
 echo "Please run as super user"
 exit 1
fi

# connect wifi
read -p "using wifi? [y/N] " WIFI
if [[ $WIFI = "y" ]]; then
  nmtui
fi

# microcodes
read -p "Intel or AMD? [I/a] " MCODE
if [[ $MCODE = "a" ]]; then
  pacman -S --noconfirm amd-ucode
else
  pacman -S --noconfirm intel-ucode
fi

# edit pacman conf
LIB32_MESA=""
LIB32_NVI_UTLS=""
echo ""
read -p "want 32-bit packages? [y/N] " BIT32
if [[ $BIT32 = "y" ]]; then
  vim /etc/pacman.conf
  acman -Syu --noconfirm
  LIB32_MESA="lib32-mesa"
  LIB32_NVI_UTLS="lib32-nvidia-utils"
fi

# display server
pacman -S --noconfirm xorg-server xorg-xinit xorg-apps xf86-video-intel mesa $LIB32_MESA

# nvidia
read -p "using nvidia? [y/N] " NVI
if [[ $NVI = "y" ]]; then
  echo ""
  pacman -S --noconfirm nvidia nvidia-utils $LIB32_NVI_UTLS nvidia-prime nvidia-settings
fi

# install other stuff
echo ""
pacman -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-iosevka-nerd ttf-hack-nerd ttf-jetbrains-mono ttf-font-awesome \
  ffmpeg mpv feh zathura zathura-pdf-mupdf firefox kitty qbittorrent \
  zip gzip unzip xdotool bluez bluez-utils git pulseaudio pulseaudio-bluetooth pavucontrol xdg-user-dirs numlockx brightnessctl sed \
  bash-completion htop neofetch \
  xfce4 xfce4-goodies lightdm lightdm-gtk-greeter

systemctl enable bluetooth --now
systemctl enable lightdm
xdg-user-dirs-update

sed -i "s/^#greeter-hide-users=false$/greeter-hide-users=false/" /etc/lightdm/lightdm.conf









# install qemu/kvm
read -p "install qemu/kvm? [y/N] " VM
if [[ $VM = "y" ]]; then
  pacman -S --noconfirm qemu dhclient openbsd-netcat virt-viewer libvirt dnsmasq dmidecode ebtables virt-install virt-manager bridge-utils edk2-ovmf
  systemctl enable libvirtd --now
  mkdir ~/.config/libvirt
  sudo cp -rv /etc/libvirt/libvirt.conf ~/.config/libvirt/
  read -p "user: " USER
  chown $USER:wheel ~/.config/libvirt/libvirt.conf
  virsh net-autostart default
fi

exit
