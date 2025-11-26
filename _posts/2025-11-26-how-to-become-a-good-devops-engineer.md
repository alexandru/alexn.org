---
title: "How To Become a DevOps Engineer"
image: /assets/media/articles/2025-cat-on-macbook.jpeg
image_hide_in_post: true
tags:
  - DevOps
  - Teaching
  - Self Hosting
---

<p class="intro" markdown=1>
The TLDR: *Eat your own dogfood* by practicing DevOps on your own infrastructure, change mentality to one oriented towards automation, and grow your hard engineering skills, such as learning to do programming, because it's in the job description.
</p>

While working in this industry, at some point it becomes clear that good DevOps engineers may be more rare than good developers. Senior people end up interviewing for engineering roles, and as an interviewer, I started being happy to see people knowing what `$?` is for.

I may even understand why that happens. Depending on the organization, the job of a DevOps is less about engineering per se, and more about dealing with manual investigations and paperwork. Few devs have the stomach to become DevOps, so the normal pipeline for creating DevOps engineers goes through Support departments. DevOps was coined to highlight that Operations teams need to invest in automation and fast problem detection mechanisms, which requires software development. But in many projects it becomes clear that the "dev" in DevOps may be missing entirely.

Be as it may, if you want to grow as a DevOps engineer, you need to grow your inner "dev". Knowing how to use your Windows laptop and browser isn't enough of a hard skill to get by. So here's what you need to do:

### 1) Use the Linux command line every day

First, Linux dominates on the server-side. If you're administering Windows servers, the days of your job are numbered, even if you're a believer in Microsoft's tech.

I can't stress this enough. It's embarrassing to notice people not being able to do basic tasks, such as:

- Navigate the file system, find files, view file contents, edit files.
- Handle `tar.gz` archives.
- Finding out if a package is installed and what version.
- Finding if a certain process is running.
- Getting the logs of a process.
- Filter errors from those logs. Read those errors.
- Kill that process.
- Investigate CPU, RAM or disk usage.
- Check that a server is up and running.

The easiest way to do that is to install Linux on your laptop. If you can't do that on your work laptop, maybe because your organization has rigid ideas about security and support, go for Apple's macOS, or try [WSL](https://learn.microsoft.com/en-us/windows/wsl/about), or at the very least, install Linux on your personal laptop.

Then force yourself to use Unix/Linux command line tools, every day. Given the advent of LLM tools, it's easier than ever to get answers.

If you're Romanian, check out ["Utilizarea sistemelor de operare"](https://github.com/systems-cs-pub-ro/carte-uso/releases/tag/uso-ed1-2021). This is a book used as support for a course at University Politehnica of Bucharest, however, it's also used by 15-year-olds participating in the [AcadNet](https://concurs.acadnet.eu/) competition. I think that professional DevOps engineers should have more knowledge than high-schoolers participating in local competitions 🧑‍🎓

### 2) Have your own Virtual Private Server (VPS) and self-host stuff

There are cheap VPS providers around, like [Hetzner](https://www.hetzner.com/) or [Netcup](https://www.netcup.com/). Get your own VPS. Then work your way to self-hosting your own services like:

- Static websites, served by Nginx (easiest)
- VPN (WireGuard)
- [WordPress](https://wordpress.org/) 
- [Isso commenting widget](https://isso-comments.de/)
- [Matomo](https://matomo.org/)
- [Linkding](https://linkding.link/)
- [Vaultwarden](https://github.com/dani-garcia/vaultwarden)
- [FreshRSS](https://freshrss.org/)
- [Mastodon](https://docs.joinmastodon.org/user/run-your-own/)
- [NextCloud](https://nextcloud.com/)

There are many services you might want to host, depending on what you fancy (not email, don't do that). Providing your family with online services might be good motivation. In the process you may learn how to:

1. Keep backups, after you lose everything, which will happen at least once, [multiple kinds of backups](https://alexn.org/blog/2022/12/02/personal-server-backups/), actually.
2. Harden your Linux server, after you leave a Redis port open on the Internet, and your server gets infected by malware mining for Bitcoin (true story).
3. Do automated upgrades and cleanups, because you don't have the time or the attention span to keep it up to date, or to intervene when that server crashes due to low disk space.
5. Simplify hosting by using Docker containers, because you want easy installations, and a predictable environment that can be replicated.
6. Reinstall that Linux server from scratch, every once in a while, by switching VPS providers or taking advantage of lowering prices.
7. Write portable scripts for automated provisioning of new Linux servers, because remembering stuff just won't cut it.
8. Keep those scripts in a Git repository, alongside other configuration or documentation you need; you need the ability to rebuild that server from scratch in a couple of hours, tops.
9. Find ways for continuous monitoring, to make your server as resilient as possible, because your personal brand or your family depends on it.
10. Find ways to block AI bots that can consume your bandwidth, or DDoS attacks; or optimize the server to withstand traffic sent due to your links trending on social media.

<p class="info-bubble" markdown="1">
**NOTE:** Pain is good! Embrace it, witness it, but don't normalize it. It tells you when you need to find better solutions. Have the guts to say *"this sucks, I can do better!"* Pain-driven development, as I like calling it 😄
</p>

<p class="warn-bubble" markdown="1">
**WARN:** You can also do home-automation, which can be a great motivation, but unless a Linux server is involved, a server that you administer, and that's exposed to danger, it doesn't count. Home automation stuff can be very user friendly and you won't learn much.
</p>

### 3) Learn Programming

The job of a DevOps includes "dev". It's in the job description. You mustn't be just a user.

The mentality of a DevOps engineer should be *"automate and monitor all the things"*, with everything else being just red tape and drudgery getting in the way, also ripe for automation. So of course you need programming.

As programming languages, at the very least, you need Bash and Python. Bash sucks, everyone hates it, but it's everywhere and works for very simple scripts. You'll need more than Bash, though.

But don't stop at just superficial knowledge about syntax. Learn basic algorithms and data structures, because you need to get into the right mindset. If you need motivation, consider that you need the knowledge of a 15-year-old in their freshman year at a high-school with a computer-science curriculum (from Romania, at least, I don't know what high-schools teach in other countries). And don't fool yourself about the existence of LLMs (AKA "AI"), because at the very least you need to know what to ask for, or to [review the generated code](./2025-11-16-programming-languages-in-the-age-of-ai-agents.md).

The good news is that it's easier than ever to learn, the Internet being filled with (often free) books or video tutorials, and you can also use ChatGPT for learning (when used in the right way, it can be useful). You can also join like-minded communities and seek help from others. Teach others, too, as becoming a teacher is the best way to go deep.

<p class="warn-bubble" markdown="1">
**WARN:** you may expect your employer or your government to invest in your training, and that surely would be nice and wise, but it's not really how the free market works. If you stagnate, or if you find yourself unable to get new jobs, it's not your past or present employers' responsibility, it's not your government's responsibility, it's mostly yours. Sorry, I don't make the rules.
</p>

### 4) Be a Cat owner

You're not a true DevOps if you don't have a cat occasionally sitting on your keyboard, wreaking havoc.

<figure>
  <img src="{% link assets/media/articles/2025-cat-on-macbook.jpeg %}" />
  <figcaption markdown=1>
Cat sitting on Macbook keyboard ([source](https://commons.wikimedia.org/wiki/File:Cat_on_a_macbook.JPG))
  </figcaption>
</figure>

Now go forth, self-host stuff, do programming, have fun, pet your cat, and learn some hard engineering skills 💪
