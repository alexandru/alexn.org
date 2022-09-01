---
date: 2022-03-11 13:59:24 +02:00
last_modified_at: 2022-09-01 17:25:55 +03:00
---

# Ubuntu Server

## Initial setup (firewall, user, updates)

As `root`:

```bash
# Installing available security updates
apt update && apt upgrade

# Enabling firewall (super important!)
apt install ufw
ufw default deny incoming
# I've decided to be super strict and block everything by default

# SSH
ufw allow in 22
# HTTP(S)
ufw allow in 80
ufw allow in 443
```

We can also configure the firewall to deny outgoing connections:

```bash
ufw default deny outgoing
# SSH
ufw allow out 22
# HTTP(S)
ufw allow out 80
ufw allow out 443

# Allow DNS requests
ufw allow out 53

# Allow outgoing SMTP via FastMail
ufw allow out 587
```

Enable ufw (after making sure that SSH is enabled):

```bash
ufw --force enable
```

Status should now look like this:

```
root@vm~# ufw status
Status: active

To                         Action      From
--                         ------      ----
OpenSSH                    ALLOW       Anywhere
80                         ALLOW       Anywhere
443                        ALLOW       Anywhere
OpenSSH (v6)               ALLOW       Anywhere (v6)
80 (v6)                    ALLOW       Anywhere (v6)
443 (v6)                   ALLOW       Anywhere (v6)

80                         ALLOW OUT   Anywhere
443                        ALLOW OUT   Anywhere
53                         ALLOW OUT   Anywhere
587                        ALLOW OUT   Anywhere
80 (v6)                    ALLOW OUT   Anywhere (v6)
443 (v6)                   ALLOW OUT   Anywhere (v6)
53 (v6)                    ALLOW OUT   Anywhere (v6)
587 (v6)                   ALLOW OUT   Anywhere (v6)
```

Fix the UFW+Docker combination via [ufw-docker](https://github.com/chaifeng/ufw-docker) utility (otherwise Docker will just ignore your firewall rules):

```
wget -O /usr/local/bin/ufw-docker \
  https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker

chmod +x /usr/local/bin/ufw-docker

ufw-docker install

systemctl restart ufw
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
PrintMotd yes
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
sudo apt install clamav -y
```

Update its definitions:

```sh
sudo systemctl stop clamav-freshclam

sudo freshclam

sudo systemctl start clamav-freshclam
```

## Install swap file

Source: <https://bookofzeus.com/harden-ubuntu/server-setup/add-swap/>

```sh
# Let's check if a SWAP file exists and it's enabled before we create one.
sudo swapon -s

# To create the SWAP file, you will need to use this.
sudo fallocate -l 4G /swapfile

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
