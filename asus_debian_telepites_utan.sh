#!/bin/bash

# ------------------------
# root account tiltása

echo "***** 1/10 root account tiltása... *****"
sleep 5
sudo passwd -l root
echo "***** A root account tiltása sikeres! *****"
sleep 5

# -------------------------------------------------------------
# Debian backports beállítása az /etc/apt/sources.list fájlban

echo "***** 2/10 Debian backports beállítása az /etc/apt/sources.list fájlban *****"
sleep 5
echo '# Backports

deb http://ftp.bme.hu/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src http://ftp.bme.hu/debian/ bookworm-backports main contrib non-free non-free-firmware' | sudo tee -a /etc/apt/sources.list

feltetel=$(sudo tail -n 2 /etc/apt/sources.list)
szoveg="deb http://ftp.bme.hu/debian/ bookworm-backports main contrib non-free non-free-firmware
deb-src http://ftp.bme.hu/debian/ bookworm-backports main contrib non-free non-free-firmware"

if [ "$feltetel" == "$szoveg" ]; then
  echo "***** A Debian backports beállítása sikeres! *****"
fi
sleep 5

# -------------------------------------------------------------------------------------------
# Tárolófrissítés

echo "***** 3/10 Tárolófrissítés... *****"
sleep 5
sudo apt update
sudo apt upgrade -y
sudo apt full-upgrade -y
sudo apt autoremove -y

echo "***** A tárolófrissítés befejeződött! *****"
sleep 5

# -------------------------------------------------
# intel-microcode és firmware-linux telepítése

echo "***** 4/10 intel-microcode és firmware-linux telepítése *****"
sleep 5
sudo apt install intel-microcode firmware-linux -y
echo "***** Az intel-microcode és firmware-linux telepítése befejeződött! *****"
sleep 5

# ----------------------------------------------------------------
# swapfile létrehozása

echo "***** 5/10 Swapfile létrehozása... *****"
sleep 5
sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '# swapfile
/swapfile	none	swap	sw	0	0' | sudo tee -a /etc/fstab

feltetel=$(sudo tail -n 1 /etc/fstab)
szoveg="/swapfile	none	swap	sw	0	0"

if [ "$feltetel" == "$szoveg" ]; then
  echo "***** A swapfile beállítása sikeres! *****"
fi
sleep 5

# ----------------------------------------------------------------
# swappiness beállítása

echo "***** 6/10 A swappiness beállítása... *****"
sleep 5
echo '# swappiness
vm.swappiness=15' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
cat /proc/sys/vm/swappiness

if [ $(cat /proc/sys/vm/swappiness) == "15" ]; then
  echo "***** A swappiness beállítása sikeres! *****"
fi
sleep 5

# -------------------------------------------------------------------------
# nftables beállítása

echo "***** 7/10 Az nftables beállítása... *****"
sleep 5
sudo apt update && sudo apt install nftables -y
sudo systemctl enable nftables
sudo systemctl start nftables
echo '#!/usr/sbin/nft -f

flush ruleset

table inet filter {
	chain input {
		type filter hook input priority 0;
		policy drop;
		iif lo accept
		ct state established,related accept
		ct state invalid drop
		udp dport { 3478, 3479, 19302-19309, 10000-20000 } accept
		tcp dport 443 ct state new accept
	}
	chain forward {
		type filter hook forward priority 0;
		policy drop;
	}
	chain output {
		type filter hook output priority 0;
		policy accept;
	}
}' | sudo tee /etc/nftables.conf
sudo nft -f /etc/nftables.conf
feltetel=$(sudo nft list ruleset)
szoveg='table inet filter {
	chain input {
		type filter hook input priority filter; policy drop;
		iif "lo" accept
		ct state established,related accept
		ct state invalid drop
		udp dport { 3478-3479, 10000-20000 } accept
		tcp dport 443 ct state new accept
	}

	chain forward {
		type filter hook forward priority filter; policy drop;
	}

	chain output {
		type filter hook output priority filter; policy accept;
	}
}'
if [ "$feltetel" == "$szoveg" ]; then
  echo "***** Az nftables beállítása sikeres! *****";
fi
sleep 5

# -------------------------------------------------------------------------
# i3 telepítése

echo "***** 8/10 i3 telepítése... *****"
sleep 5
sudo apt install i3 xinit x11-utils xserver-xorg lightdm lightdm-gtk-greeter dmenu i3status i3blocks xfce4-terminal lxappearance brightnessctl fonts-dejavu thunar thunar-volman gvfs gvfs-fuse gvfs-common gvfs-backends feh network-manager-gnome nm-tray mousepad -y
echo "***** Az i3 telepítése sikeres! *****"
sleep 5

# -------------------------------------------------------------------------
# Pipewire telepítése

echo "***** 9/10 A pipewire telepítése... *****"
sleep 5
sudo apt update
sudo apt install pipewire-audio wireplumber pipewire-pulse pipewire-alsa libspa-0.2-bluetooth volumeicon-alsa pavucontrol pulseaudio-utils -y
systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
systemctl --user enable wireplumber
systemctl --user start pipewire
systemctl --user start pipewire-pulse
systemctl --user start wireplumber

feltetel=$(pactl info | grep "Server Name")
szoveg="Server Name: PulseAudio (on PipeWire 0.3.65)"

if [ "$feltetel" == "$szoveg" ]; then
  echo "***** A Pipewire beállítása sikeres! *****";
fi
sleep 5

# ------------------------------------------------------------------------------------------------------
# Rendszertisztítás

echo "***** 10/10 Rendszertisztítás... *****"
sleep 5
sudo apt install -f -y
sudo apt autoremove -y
sudo apt clean -y

echo "***** A rendszertisztítás befejeződött! *****"
sleep 5
echo '**************************************************
      A gép újraindul a telepítések és beállítások után!
**************************************************'
sleep 5
sudo reboot
