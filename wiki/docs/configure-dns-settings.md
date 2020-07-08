# Configure DNS settings

## MacOS

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
