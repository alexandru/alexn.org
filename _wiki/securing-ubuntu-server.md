---
date: 2022-03-11 13:59:24+0200
title: "Securing Ubuntu Server"
---

## Initial setup (firewall, user, updates)

As `root`:

```bash
# Installing available security updates
apt update && apt upgrade

# Enabling firewall (super important!)
apt install ufw
ufw default deny incoming
ufw allow OpenSSH
ufw --force enable
```

Creating a new user and disabling `root`:

```bash
adduser alex
# Adds the user to sudoers
usermod -aG sudo alex

# Create its OpenSSH config
mkdir /home/alex/.ssh
vim /home/alex/.ssh/authorized_keys
chmod -R go-rwx /home/alex/.ssh
chown -R alex:alex /home/alex/.ssh

# Disable root's password
passwd -l root

# It's a good time to reboot
reboot
```

Setup automatic updates:

```sh
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

Edit `/etc/apt/apt.conf.d/50unattended-upgrades` for customizations.

## Secure OpenSSH

Edit the config file:

```bash
sudo vim /etc/ssh/sshd_config
```

Add these options:

```
Port 22
Protocol 2
LoginGraceTime 30
PermitRootLogin no
AllowUsers alex
StrictModes yes
MaxAuthTries 3
IgnoreRhosts yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
UsePAM no
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
PrintMotd no
ClientAliveInterval 6m
ClientAliveCountMax 0
UseDNS no
PermitTunnel no
```

## Configure sending emails via FastMail (or another SMTP server)

```
sudo apt-get install postfix mailutils libsasl2-2 ca-certificates libsasl2-modules
```

Add the following lines in `/etc/postfix/main.cf`:

```
relayhost = [smtp.fastmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/postfix/cacert.pem
smtp_use_tls = yes
```

Create `/etc/postfix/sasl_passwd`:

```
[smtp.fastmail.com]:587 username:password
```

Fix the permissions:

```bash
sudo chmod 400 /etc/postfix/sasl_passwd
```

Tell postfix about the password entry:

```bash
sudo postmap /etc/postfix/sasl_passwd
```

Download the [Thawte Primary Root CA](https://www.thawte.com/roots/) if not available:

```
cd /etc/ssl/certs/
sudo wget https://www.thawte.com/roots/thawte_Primary_Root_CA.pem
```

Then create `cacert.pem`:

```sh
sudo cp /etc/ssl/certs/thawte_Primary_Root_CA.pem /etc/postfix/cacert.pem
```

Restart the service:

```sh
sudo /etc/init.d/postfix reload
```

Test it:

```sh
echo "Test Email message body" | mail -s "Email test subject"  test@domain.tld
```

## Install ClamAV anti-virus

```sh
sudo apt install clamav clamav-daemon -y
```

Update its definitions:

```sh
sudo systemctl stop clamav-freshclam

sudo freshclam

sudo systemctl start clamav-freshclam
```

Start the daemon:

```sh
sudo systemctl start clamav-daemon
```

## Install swap file

```sh
# Let's check if a SWAP file exists and it's enabled before we create one.
sudo swapon -s

# To create the SWAP file, you will need to use this.
sudo fallocate -l 4G /swapfile	# same as "sudo dd if=/dev/zero of=/swapfile bs=1G count=4"

# Secure swap.
sudo chown root:root /swapfile
sudo chmod 0600 /swapfile

# Prepare the swap file by creating a Linux swap area.
sudo mkswap /swapfile

# Activate the swap file.
sudo swapon /swapfile

# Confirm that the swap partition exists.
sudo swapon -s

# This will last until the server reboots. Let's create the entry in the fstab.
sudo nano /etc/fstab
: /swapfile	none	swap	sw	0 0

# Swappiness in the file should be set to 0. Skipping this step may cause both poor performance,
# whereas setting it to 0 will cause swap to act as an emergency buffer, preventing out-of-memory crashes.
echo 0 | sudo tee /proc/sys/vm/swappiness
echo vm.swappiness = 0 | sudo tee -a /etc/sysctl.conf
```
