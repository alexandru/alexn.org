---
date: 2020-08-24 16:24:31+0300
title: "Email Tips"
---

## Send email from localhost

```sh
brew install swaks
```

```sh
swaks --auth \
	--server smtp.mailgun.org \
	--au postmaster@mail.mydomain.com \
	--ap password \
  --from alex@mail.mydomain.com \
	--to user@domain.com \
	--h-Subject: "Hello" \
	--body 'World!'
```

## Via Python script

See: [send-mail.py]({% link _snippets/2020-03-18-send-mail.py.md %})
