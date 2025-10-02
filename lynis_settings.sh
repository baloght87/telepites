#!/bin/bash


# Check for loaded ip_tables modules

lsmod | grep -E 'ip_tables|iptable|xt_|nf_'

# if I don't need something: "echo "blacklist ip_tables" | sudo tee -a /etc/modprobe.d/disable-iptables.conf"
# Utana mkinitcpio -P


echo "***** Felesleges tesztek beírása... *****"
sleep 5

cat <<EOF | sudo tee /root/lynis/custom.prf
machine-role=personal
skip-upgrade-test=yes
test-scan-mode=normal
skip-test=KRNL-6000
skip-test=BOOT-5264
skip-test=FILE-6310
skip-test=NAME-4028
skip-test=LOGG-2154
skip-test=LOGG-2190
skip-test=ACCT-9628
skip-test=TOOL-5002
skip-test=FILE-7524
EOF

echo "***** /root/lynis/custom.prf létrehozva! *****"
sleep 5

echo "[*] Installing useful packages..."
sleep 5
sudo apt install -y debsums apt-show-versions unattended-upgrades libpam-pwquality aide acct
echo "[*] Installing useful packages...DONE"
sleep 5

echo "[*] Configuring core dump restrictions..."
sleep 5
echo "* hard core 0" | sudo tee -a /etc/security/limits.conf
echo "fs.suid_dumpable = 0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w fs.suid_dumpable=0
echo "[*] Configuring core dump restrictions... DONE"
sleep 5

echo "[*] Setting password hashing rounds..."
sleep 5
sudo sed -i '/^SHA_CRYPT_/d' /etc/login.defs
echo "SHA_CRYPT_MIN_ROUNDS 10000" | sudo tee -a /etc/login.defs
echo "SHA_CRYPT_MAX_ROUNDS 15000" | sudo tee -a /etc/login.defs
echo "[*] Setting password hashing rounds...DONE"
sleep 5

echo "[*] Configuring password policy..."
sleep 5
sudo sed -i 's/^UMASK.*/UMASK	027/' /etc/login.defs
sudo sed -i '/^PASS_/d' /etc/login.defs
cat <<EOF | sudo tee -a /etc/login.defs
PASS_MAX_DAYS   90
PASS_MIN_DAYS   10
PASS_WARN_AGE   7
EOF

echo "[*] Configuring password policy...DONE"
sleep 5

echo "[*] Enforcing strong password policy via pam_pwquality..."
sleep 5
sudo sed -i '/pam_pwquality.so/d' /etc/pam.d/common-password
echo "password requisite pam_pwquality.so retry=3 minlen=12 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1" | sudo tee -a /etc/pam.d/common-password
echo "[*] Enforcing strong password policy via pam_pwquality...DONE"
sleep 5

echo "[*] Setting password expiration for current user..."
sleep 5
sudo chage --mindays 10 --maxdays 90 --warndays 7 "$USER"
echo "[*] Setting password expiration for current user...DONE"
sleep 5

echo "[*] Setting up automatic updates..."
sleep 5
sudo dpkg-reconfigure --priority=low unattended-upgrades
echo "[*] Setting up automatic updates...DONE"
sleep 5

echo "[*] Disabling USB and FireWire storage modules..."
sleep 5
echo "blacklist usb-storage" | sudo tee /etc/modprobe.d/blacklist-usb.conf
echo "blacklist firewire-core" | sudo tee /etc/modprobe.d/blacklist-firewire.conf
echo "[*] Disabling USB and FireWire storage modules...DONE"
sleep 5

echo "[*] Disabling unused network protocols..."
sleep 5
cat <<EOF | sudo tee /etc/modprobe.d/disable-protocols.conf
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF

echo "[*] Disabling unused network protocols...DONE"
sleep 5

echo "***** Sysstat engedélyezése... *****"
sleep 5
echo 'ENABLED="true"' | sudo tee /etc/default/sysstat
echo "***** Sysstat beállítása kész! *****"
sleep 5

echo "***** Debsums engedélyezése... *****"
sleep 5
echo "CRON_CHECK=monthly" | sudo tee /etc/default/debsums
sudo debsums -s
echo "***** Debsums beállítása kész! *****"
sleep 5

echo "***** sudoers.d jogosultságok... *****"
sleep 5
sudo chmod 750 /etc/sudoers.d/
echo "***** sudoers.d jogosultságok beáálítva! *****"
sleep 5

echo "[*] Enabling process accounting and audit logging..."
sleep 5
sudo systemctl enable --now acct
echo "[*] Enabling process accounting and audit logging...DONE"
sleep 5

echo "[*] Removing /etc/issue and /etc/issue.net..."
sleep 5
sudo rm -f /etc/issue
sudo rm -f /etc/issue.net
echo "[*] Removing /etc/issue and /etc/issue.net...DONE"
sleep 5

echo "***** Régi csomagok eltávolítása... *****"
sleep 5
sudo apt-get purge $(dpkg -l | grep '^rc' | awk '{print $2}')
echo "***** Régi csomagok eltávolítva! *****"
sleep 5

echo "[*] Initializing AIDE file integrity database..."
sleep 5
echo "NORMAL = p+i+n+u+g+s+m+c+sha512" | sudo tee -a /etc/aide/aide.conf
sudo aide -c /etc/aide/aide.conf --init
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
echo "[*] Initializing AIDE file integrity database...DONE"
sleep 5

echo "[✔] Basic system hardening complete. Reboot recommended."
echo 'Grub passwd beállítás!
grub-mkpasswd-pbkdf2
PBKDF2 hash of your password is grub.pbkdf2.sha512.10.....
# cp /etc/grub.d/40_custom /etc/grub.d/40_custom.old
# nano /etc/grub.d/40_custom
set superusers="root"
password_pbkdf2 root grub.pbkdf2.sha512.10...

Update the grub File'
