# Step by step installation VBOX:
# Fuente: https://www.youtube.com/watch?v=pxTTp7gDRn4


# DESCARGA DE ARCH
# ---
# Fuente: https://www.archlinux.org/download/



# ACTUALIZACIÓN
# ---
# Fuente: https://wiki.archlinux.org/index.php/System_maintenance_(Espa%C3%B1ol)#Actualizar_el_sistema
# Paquetes: https://www.archlinux.org/packages/
### Actualizar el sistema:
# Evitar su uso: sudo pacman -Syy
sudo pacman -Syu

### Para enumerar todos los paquetes foráneos:
sudo pacman -Qm

### Para eliminar paquetes huerfanos:
sudo pacman -Qtd



# VAGRANT
# ---
ssh -p 2222 vagrant@127.0.0.1
# Pass: vagrant



# SYSTEMD
# ---
# Manejar servicios:
sudo systemctl enable vboxservice.service
sudo systemctl start vboxservice.service
sudo systemctl restart vboxservice.service
sudo systemctl status vboxservice.service


# INSTALACION DE ARCH LINUX
# ---
# Actualizando sistema:
# sudo pacman -Syy
sudo pacman -Syu
# Instalando paquetes:
sudo pacman -S nano
sudo loadkeys sunt5-es
sudo nano /etc/locale.gen
# es_ES.UTF-8 UTF-8
# es_ES ISO-8859-1
# es_ES@euro ISO-8859-15
sudo locale-gen 
sudo nano /etc/locale.conf
# LANG=es_ES.UTF-8
sudo nano /etc/vconsole.conf
# KEYMAP=es
sudo ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
sudo timedatectl set-ntp true
date

# Comprobar drivers:
lspci | grep VGA
sudo pacman -Ss xf86-video
# Instalar Xorg y drivers:
sudo pacman -S xorg-server xorg-xrandr xorg-xinput
# Si desea arrancar X sin un gestor de pantalla, instale el paquete:
sudo pacman -S extra/xorg-xinit
# glxinfo + glxgears
sudo pacman -S extra/mesa-demos
# Instalar "The GNOME Display Manager (GDM)" [~500MB]:
sudo pacman -S extra/gdm
sudo systemctl start gdm
sudo systemctl status gdm
cat /var/log/Xorg.0.log
glxinfo | grep -iP 'opengl | rendering'
sudo systemctl enable gdm.service
#Fuente: https://wiki.archlinux.org/index.php/GDM#Use_Xorg_backend

# Instalar soporte para VirtualBox:
sudo pacman -S community/virtualbox-guest-utils
# Drivers:
#sudo pacman -S virtualbox-host-modules-arch
# Guest Additions:
sudo pacman -S community/virtualbox-guest-iso
# Activa todas las características (clipboard, draganddrop, seamless, display, checkhostversion, vmsvga-x11):
VBoxClient-all
# Los modulos ya están en el fichero:
#sudo cat /usr/lib/modules-load.d/virtualbox-host-modules-arch.conf
# Carga manual de módulos:
# sudo modprobe -a vboxguest vboxsf vboxvideo
sudo lsmod | egrep '(vboxguest|vboxsf|vboxvideo)'
sudo systemctl enable vboxservice.service

# TODO: Ver si sobra:
#sudo pacman -S pulseaudio pulseaudio-alsa xf86-video-vesa xorg-init xorg-server bash-completion

sudo gpasswd -a vagrant video
sudo cp /etc/X11/xinit/xinitrc /home/vagrant/.xinitrc
sudo chown vagrant:vagrant /home/vagrant/.xinitrc
sudo cp /etc/X11/xinit/xinitrc /etc/skel/.xinitrc

# Instalar plasma + wayland sesion [~1GB]:
sudo pacman -S extra/plasma-desktop extra/plasma-wayland-session
  # With noto-fonts



# NOTE:
# ---
# Parece que habitualmente estás ejecutando pacman -Sy. No hagas eso.
# No veo dónde has actualizado todo el sistema, que es la causa de tu problema.
# Actualice todo, luego nunca, nunca ejecute -Sy nuevamente.



# ARRANCANDO DESDE EL CD:
# ---
systemctl enable sshd
passwd root
loadkeys sunt5-es
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
timedatectl set-ntp true
date

# Particionar:
# LABELTYPE: GPT
# TYPE: EFI System [512MB]
# TYPE: SWAP [16GB]
# TYPE: LINUX Filesystem [rest]

# Formatear:
mkfs.fat -F32 /dev/sda1 -n IFEFI
mkfs.ext4 /dev/sda3 -L ifroot

mkswap /dev/sda2 -L ifswap
swapon /dev/sda2

# Mount:
mountpoint /mnt || mount /dev/sda3 /mnt
[ -d /mnt/boot ] || mkdir /mnt/boot
[ -d /mnt/boot/EFI ] || mkdir /mnt/boot/EFI
mountpoint /mnt/boot/EFI || mount /dev/sda1 /mnt/boot/EFI

# Instalar esenciales para un sistema vivo:
pacstrap /mnt base base-devel linux linux-firmware networkmanager mlocate nano openssh bash-completion arch-install-scripts
pacman -Sy nano

# CHROOT
# ---
arch-chroot /mnt

user=jaime
useradd -m ${user}
echo "source /usr/share/bash-completion/bash_completion" >> root/.bashrc
echo "source /usr/share/bash-completion/bash_completion" >> home/${user}/.bashrc



ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
timedatectl set-ntp true
hwclock --systohc
date


genfstab -U / >> /etc/fstab

nano /etc/locale.gen
# Descomentar es_ES ...
locale-gen

nano /etc/locale.conf
 LANG=es_ES.UTF-8

nano /etc/vconsole.conf
 KEYMAP=es

nano /etc/hostname
 arch

nano /etc/hosts
  # Static table lookup for hostnames.
  # See hosts(5) for details.

  127.0.0.1     localhost
  ::1           localhost
  127.0.0.1     arch.localdomain    arch

nano /etc/ssh/sshd_config
  PermitRootLogin yes

systemctl enable NetworkManager
systemctl enable sshd
passwd root

pacman -S intel-ucode grub efibootmgr

# TODO: Removable device, para que se pueda cambiar el disco de máquina.
# TODO  Fuente: https://wiki.archlinux.org/index.php/GRUB#Installation_2
grub-install --target=x86_64-efi --efi-directory=/boot/EFI /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
efibootmgr -v
# nano /etc/defaut/grub
#   GRUB_DISABLE_LINUX_UUID=true
#   GRUB_ENABLE_LINUX_LABEL=true
# 
# grub-install --target=x86_64-efi --efi-directory=/boot
#    --bootloader-id=%whateveryouwanttoshow%
# grub-mkconfig -o /boot/grub/grub.cfg
# 
# nano /boot/grub/grub.cfg
#   search --no-floppy --label root --set=root
#   linux   /boot/vmlinuz-4.9.0-3-amd64 root=LABEL=root ro single
# Fuente: https://unix.stackexchange.com/questions/507752/using-label-in-grub-on-debian-9

sync && exit

umount -a

reboot




# Comprobar drivers:
lspci | grep VGA
#sudo pacman -Ss xf86-video
# Instalar Xorg y drivers:
sudo pacman -S xorg-server xorg-xrandr xorg-xinput extra/gdm plasma-desktop plasma-wayland-session
  # NOTE: noto-fonts
# Si desea arrancar X sin un gestor de pantalla, instale el paquete:
# sudo pacman -S extra/xorg-xinit
# Para instalar glxinfo + glxgears
sudo pacman -S extra/mesa-demos
# Instalar "The GNOME Display Manager (GDM)" [~500MB]:
# sudo pacman -S extra/gdm # << Ya se instala más arriba.
sudo systemctl start gdm
sudo systemctl status gdm
# cat /var/log/Xorg.0.log
# glxinfo | grep -iP 'opengl | rendering'
sudo systemctl enable gdm.service
#Fuente: https://wiki.archlinux.org/index.php/GDM#Use_Xorg_backend

# Instalar soporte para VirtualBox:
sudo pacman -S community/virtualbox-guest-utils
# Drivers:
#sudo pacman -S virtualbox-host-modules-arch
# Guest Additions:
# sudo pacman -S community/virtualbox-guest-iso
# Activa todas las características (clipboard, draganddrop, seamless, display, checkhostversion, vmsvga-x11):
# VBoxClient-all
# Los modulos ya están en el fichero:
#sudo cat /usr/lib/modules-load.d/virtualbox-host-modules-arch.conf
# Carga manual de módulos:
# sudo modprobe -a vboxguest vboxsf vboxvideo
sudo lsmod | egrep '(vboxguest|vboxsf|vboxvideo)'
sudo systemctl enable vboxservice.service


pacman -S powerdevil
pacman -S extra/kwallet extra/kwalletmanager
pacman -S extra/chromium
pacman -S konsole
pacman -S community/virtualbox
  # NOTE: Select virtualbox-host-modules-arch
pacman -S extra/dolphin extra/dolphin-plugins
pacman -S extra/vlc
pacman -S extra/kate

pacman -S extra/gimp extra/inkscape
#community/darktable
pacman -S extra/meld community/viewnior 
#community/filezilla community/audacity
pacman -S extra/gparted extra/gnome-disk-utility
pacman -S extra/htop extra/spectacle community/galculator
pacman -S extra/xournalpp extra/ark
pacman -S extra/kleopatra
pacman -S community/arduino
  # NOTE: *1) jre-openjdk  2) jre11-openjdk  3) jre8-openjdk
reboot



# Actualizando sistema:
# ---
# sudo pacman -Syy
sudo pacman -Syu
# Instalando paquetes:
sudo pacman -S nano
sudo loadkeys sunt5-es
sudo nano /etc/locale.gen
# es_ES.UTF-8 UTF-8
# es_ES ISO-8859-1
# es_ES@euro ISO-8859-15
sudo locale-gen 
sudo nano /etc/locale.conf
# LANG=es_ES.UTF-8
sudo nano /etc/vconsole.conf
# KEYMAP=es
sudo ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
sudo timedatectl set-ntp true
date