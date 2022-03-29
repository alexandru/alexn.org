---
title: "DNS Lookup - Check Domain's DNS Records"
date: 2020-07-30 13:00:27 +03:00
last_modified_at: 2022-03-29 10:40:02 +03:00
---

For MX records (email):

```
dig mydomain.com MX
```

Checking records using different resolvers:

```sh
dig @1.1.1.1 mydomain.com MX # Cloudflare

dig @8.26.56.26 mydomain.com MX # Comodo

dig @8.8.8.8 mydomain.com MX # Google

dig @9.9.9.9 mydomain.com MX # Quad

dig @64.6.65.6 mydomain.com MX # Verisign

dig @192.71.245.208 mydomain.com MX # OpenNIC

dig @91.239.100.100 mydomain.com MX # UncensoredDNS

dig @77.88.8.7 mydomain.com MX # Yandex

dig @156.154.70.1 mydomain.com MX # Ultrarecursive DNS

dig @198.101.242.72 mydomain.com MX # Alternate DNS

dig @176.103.130.130 mydomain.com MX
```
