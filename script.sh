#!/bin/bash

#set -e # exit script on error

if (( $EUID != 0 )); then
    echo "Please run this script with sudo"
    exit
fi

function archKde5 {

  sed -i 's/\#\[multilib\]/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/g' /etc/pacman.conf

  pacman -Sy --noconfirm --needed archlinux-keyring
  yes | pacman -Su
  pacman -Su --noconfirm

  if [[ $(glxinfo | grep -E "OpenGL vendor|OpenGL renderer") == *"AMD"* ]]; then
    pacman -S --noconfirm --needed vulkan-radeon lib32-vulkan-radeon mesa-utils vulkan-tools adriconf

  elif [[ $(glxinfo | grep -E "OpenGL vendor|OpenGL renderer") == *"Intel"* ]]; then
    pacman -S --noconfirm --needed vulkan-intel lib32-vulkan-intel mesa-utils vulkan-tools adriconf

  elif [[ $(glxinfo | grep -E "OpenGL vendor|OpenGL renderer") == *"NVIDIA"* ]]; then
    pacman -S --noconfirm --needed nvidia nvidia-utils lib32-nvidia-utils nvidia-settings
  fi

  pacman -S --noconfirm --needed pipewire
  #pacman -R --noconfirm pulseaudio
  yes | pacman -S --needed pipewire-pulse
  #systemctl enable pipewire{,-pulse}.{socket,service} pipewire-media-session.service


  pacman -S --noconfirm --needed discover packagekit-qt5 xdg-desktop-portal-kde flatpak fwupd partitionmanager filelight kolourpaint kcalc ufw ttf-droid noto-fonts-emoji net-tools docker go

  pacman -S --noconfirm --needed print-manager cups system-config-printer
  systemctl enable cups
  ufw allow 631/tcp

  pacman -S --noconfirm --needed chromium qbittorrent
  pacman -S --noconfirm --needed ark p7zip unarchiver
  pacman -S --noconfirm --needed gwenview qt5-imageformats
  pacman -S --noconfirm --needed virtualbox virtualbox-host-modules-arch

  pacman -S --noconfirm --needed plasma-wayland-session
  # Espaço de Trabalho > Inicialização e desligamento > Tela de autenticação (SSDM) > Comportamento > na Sessão: Plasma (Wayland)

  pacman -S --noconfirm --needed base-devel git
  sudo -u $SUDO_USER git clone https://aur.archlinux.org/yay.git
  cd yay
  sudo -u $SUDO_USER makepkg -si --noconfirm --needed
  cd ..
  rm -rf yay

  #sudo -u $SUDO_USER yay --save --answerclean A --answerdiff N

  #sudo -u $SUDO_USER yay -S --noconfirm --needed pamac-all
  #sudo -u $SUDO_USER yay -S --noconfirm --needed pamac-tray-icon-plasma
  sudo -u $SUDO_USER yay -S --noconfirm --needed dropbox
  sudo -u $SUDO_USER yay -S --noconfirm --needed cpu-x
  #sudo -u $SUDO_USER yay -S --noconfirm --needed timeshift

  pacman -S --noconfirm --needed steam-native-runtime gamemode lib32-gamemode lutris
  sudo -u $SUDO_USER yay -S --noconfirm --needed goverlay-bin mangohud # vkbasalt lib32-vkbasalt

  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak install -y com.github.tchx84.Flatseal org.onlyoffice.desktopeditors com.github.wwmm.easyeffects org.videolan.VLC org.kde.kdenlive com.heroicgameslauncher.hgl net.davidotek.pupgui2 com.obsproject.Studio
  #flatpak install -y com.leinardi.gst

  ### DEV
  #pacman -S --noconfirm --needed code
  #flatpak install -y com.google.AndroidStudio rest.insomnia.Insomnia
  #flatpak install -y com.unity.UnityHub org.freedesktop.Sdk.Extension.dotnet org.freedesktop.Sdk.Extension.mono6

  echo "[Desktop Entry]
  Name=Trash
  Name[pt_BR]=Lixeira
  Comment=Contains deleted files
  Comment[pt_BR]=Contém arquivos deletados
  Icon=user-trash-full
  EmptyIcon=user-trash
  Type=Link
  URL=trash:/" > /home/$SUDO_USER/trash.desktop

  echo '
  # Add in ~/.bashrc or ~/.bash_profile
  function parse_git_branch () {
    git branch 2> /dev/null | sed -e "/^[^*]/d" -e "s/* \(.*\)/(\1)/"
  }

  RED="\[\033[01;31m\]"
  YELLOW="\[\033[01;33m\]"
  GREEN="\[\033[01;32m\]"
  BLUE="\[\033[01;34m\]"
  NO_COLOR="\[\033[00m\]"

  # without host
  # PS1="$GREEN\u$NO_COLOR:$BLUE\w$YELLOW\$(parse_git_branch)$NO_COLOR\$ "
  # with host
  PS1="$GREEN\u@\h$NO_COLOR:$BLUE\w$YELLOW\$(parse_git_branch)$NO_COLOR\$ "' >> /home/$SUDO_USER/.bashrc


  ## FILESHARING
  pacman -S --noconfirm --needed kdenetwork-filesharing
  ufw allow CIFS
  mkdir /var/lib/samba/usershares
  groupadd -r sambashare
  chown root:sambashare /var/lib/samba/usershares
  chmod 1770 /var/lib/samba/usershares

  echo "[global]
    workgroup = WORKGROUP
    server string %h server (Samba, Arch)
    log file = /var/log/samba/log.%m
    max log size = 1000
    logging = file
    panic action = /usr/share/samba/panic-action %d
    server role = standalone server
    obey pam restrictions = yes
    unix password sync = yes
    passwd program = /usr/bin/passwd %u
    passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssucessfully* .
    pam password change = yes
    map to guest = bad user
    usershare allow guests = yes
    usershare max shares = 100
    usershare owner only = true
    usershare path = /var/lib/samba/usershares
    printing = CUPS

  [printers]
    comment = All Printers
    browseable = no
    path = /var/spool/samba
    printable = yes
    guest ok = no
    read only = yes
    create mask = 0700

  [print$]
    comment = Printer Drivers
    path = /var/lib/samba/printers
    browseable = yes
    read only = yes
    guest ok = no" > /etc/samba/smb.conf


  gpasswd sambashare -a $SUDO_USER

  #testparm

  systemctl enable smb

  reboot
}

archKde5
