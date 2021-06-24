---
date: 2021-06-24 10:13:23+03:00
title: "TLS/SSL (HTTPS)"
---

Download the certificate of a domain:

```
echo -n | openssl s_client -connect google.com:443 -servername google.com | openssl x509
```

Verify that the certificate corresponds to CA certificate:

```
openssl verify -verbose -purpose sslserver -CAfile /path/to/cafile.pem /path/to/cert.pem
```
