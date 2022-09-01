---
date: 2020-08-24 16:24:31 +03:00
last_modified_at: 2022-09-01 17:20:30 +03:00
---

# Email

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

See: [send-mail.py]({% link _posts/2020-03-18-send-mail.py.md %})
