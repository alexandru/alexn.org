---
layout: page
title: Privacy Policy
description: "This website does not collect personally identifiable information, and has a no-cookies policy."
date: 2017-01-16
last_modified_at: 2020-06-01
article_class: privacy_policy
---

<p class="intro withcap">
  This website does not collect personally identifiable information, and no cookies are installed that could be used to track visitors.
</p>

This website has a strict no-cookies policy. Third-parties used for providing the service may drop cookies; however, the implementation goes to great lengths to prevent that.

<p class="info-bubble">
  If you want to learn more about <em>cookies</em>, see the material at: <br/>
  <a href="https://www.cookiesandyou.com/" target="_blank" rel="nofollow">What are cookies? (cookiesandyou.com)</a>
</p>

## Analytics

This website uses a self-hosted (first-party) [Matomo](https://matomo.org/) instance for tracking users' visits, with these characteristics:

1. no tracking cookies are being set
2. no tracking cookies will be created in the future without explicit permission
3. IPs are anonymized
4. collected data is used by the website's owner for content optimizations, in full compliance of GDPR, and is never shared with third-party services

<p class="info-bubble">
  There is a "<code>MATOMO_SESSID</code>" being created when you load this page (<a href="https://matomo.org/faq/general/faq_146/" target="_blank" rel="nofollow">see details</a>), linked to the <a href="https://matomo.org/privacy/#step-3-include-a-web-analytics-opt-out-feature-on-your-site-using-an-iframe" target="_blank" rel="nofollow">"opt-out" dialog</a> shown below. This cookie is temporary, is only meant to prevent CSRF security issues, and is only set when this dialog is loaded (and not when visiting other pages).
</p>

While your visit cannot be traced to you, you can opt-out of these analytics:

<div id="opt_out_frame" class="content">
  <iframe src="https://ly.alexn.org/index.php?module=CoreAdminHome&action=optOut&language=en&backgroundColor=&fontColor=333&fontSize=1.1em&fontFamily=%22PT%20Serif%22%2CGeorgia%2CTimes%2Cserif">
  </iframe>
</div>

## Email Newsletter

The `alexn.org` website uses [Mailchimp](https://mailchimp.com/){:target="_blank",rel="nofollow"}. Email addresses collected via the newsletter subscription are processed by Mailchimp, acting as a data processor.

The collected email addresses are used solely to deliver notifications on new articles being published.

Read: [Mailchimp's Privacy Policy](https://mailchimp.com/legal/privacy/#3._Privacy_for_Contacts){:target="_blank",rel="nofollow"}.

## Cloudflare

The `alexn.org` website uses [Cloudflare](https://www.cloudflare.com/){:target="_blank",rel="nofollow"} as a proxy for caching content, and protecting against DDoS attacks.

Cloudflare sets a cookie named `__cfduid` that's [restricted](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#Restrict_access_to_cookies){:target="_blank",rel="nofollow"} with `HttpOnly` and `Secure` attributes, meaning that it is secure, and other parties cannot access it. Cloudflare can identify users via this cookie, but they consider it a technical cookie that's "*strictly necessary to provide the service*" (see [Understanding the Cloudflare Cookies](https://support.cloudflare.com/hc/en-us/articles/200170156-Understanding-the-Cloudflare-Cookies){:target="_blank",rel="nofollow"}). We cannot opt-out of this cookie, all websites being served through Cloudflare have it.

Read [Cloudflare's Privacy Policy](https://www.cloudflare.com/privacypolicy/).

## Video Players

Some embedded third-party services might drop cookies (e.g., YouTube, Vimeo players); however, the website's implementation activates "do not track" options whenever possible.

- Read [Google's Privacy Policy](https://policies.google.com/privacy){:rel="nofollow",target="_blank"}; note this website uses `youtube-nocookie.com` for activating YouTube's "privacy-enhanced mode," see [embedding options](https://support.google.com/youtube/answer/171780?hl=en){:rel="nofollow",target="_blank"}
- Read [Vimeo's Privacy Policy](https://vimeo.com/privacy){:rel="nofollow",target="_blank"}; note the website [embeds the player](https://vimeo.zendesk.com/hc/en-us/articles/360001494447-Using-Player-Parameters){:rel="nofollow",target="_blank"} with a `dnt=1` flag that deactivates session cookies and tracking

{% include legal-contact.html %}
