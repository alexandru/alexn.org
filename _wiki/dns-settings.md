# DNS settings

## MacOS

### Refresh DNS

To flush the local DNS cache:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### Set DNS to Cloudflare

To set the DNS to Cloudflare's 1.1.1.1:

```
sudo networksetup -setdnsservers Wi-Fi 1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001

sudo networksetup -setdnsservers "USB 10/100/1000 LAN" 1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
```

To revert the setup:

```
sudo networksetup -setdnsservers "Wi-Fi" empty

sudo networksetup -setdnsservers "USB 10/100/1000 LAN" empty
```

To see what DNS service the connection is using:

```
$ nslookup google.com
Server:		1.1.1.1
Address:	1.1.1.1#53

Non-authoritative answer:
Name:	google.com
Address: 172.217.21.238
```

### Split DNS

Source: <https://gist.github.com/dferg/0472269333be4aca6aaa21cf3b165c02>

Sometimes you may want to use a DNS server for specific domain requests and another DNS server for all other requests. This is helpful, for instance, when connected to a VPN. For hosts behind that VPN you want to use the VPN's DNS server but all other hosts you want to use Google's public DNS. This is called "DNS splitting."

Here, we run `dnsmasq` as a background service on macOS. The dnsmasq configuration described below implements DNS splitting.

Install via Homebrew:

```sh
brew install dnsmasq
```

Edit `$(brew --prefix)/etc/dnsmasq.conf`:

```conf
# Ignore /etc/resolv.conf
no-resolv

# For queries *.domain.com and *.domain.net, forward to the specified DNS server
# Servers are queried in order (if the previous fails)
# -- Note: These are EXAMPLES. Replace with your desired config.
server=/domain.com/domain.net/IP_ADDR_OF_SERVER1
server=/domain.com/domain.net/IP_ADDR_OF_SERVER2

# Forward all other requests to Google's public DNS server
server=8.8.8.8

# Only listen for DNS queries on localhost
listen-address=127.0.0.1

# Required due to macOS limitations
bind-interfaces
```

Start the service:

```
sudo brew services start dnsmasq
```

Point to the new local DNS server:

```sh
sudo networksetup -setdnsservers "Wi-Fi" 127.0.0.1

sudo networksetup -setdnsservers "USB 10/100/1000 LAN" 127.0.0.1
```

#### Uninstall dnsmasq

```sh
sudo brew services stop dnsmasq
brew uninstall dnsmasq
rm "$(brew --prefix)/etc/dnsmasq.conf"
sudo networksetup -setdnsservers "Wi-Fi" empty
```
