---
title: "Proprietary Environments are a Trap"
image: /assets/media/articles/2022-me-and-my-son-on-laptops.jpg
image_caption: Me, with my son, learning the Lua programming language on proprietary macOS laptops.
tags:
  - Open Source
date: 2022-09-22 10:00:00 +03:00
last_modified_at: 2022-09-22 14:39:41 +03:00
description: >
  What to learn in order to not become obsolete as a software developer, and then being forced into early retirement from programming? What platforms to prefer for building products that last with minimal maintenance?
---

<p class="intro withcap" markdown=1>
What to learn in order to not become obsolete as a software developer, and then being forced into early retirement from programming? What platforms to prefer for building products that last with minimal maintenance?
</p>

Jeremy Allison ([bio](https://en.wikipedia.org/wiki/Jeremy_Allison)) is a computer programmer, contributor to Samba, and Free Software proponent that I have long admired.  In [Working for The Man](https://web.archive.org/web/20150309050037/http://tuxdeluxe.org/node/122), he has a paragraph on proprietary platforms that stuck in my head...

> *Proprietary environments are a trap*
>
> *I used to be a Microsoft Windows programmer, as well as a UNIX/POSIX programmer.*
> 
> *The knowledge I've gained about programming POSIX is still useful, even though I learned a lot of it over twenty years ago. My Windows knowledge is now rather out of date, and getting more so over the years. It isn't worth my time anymore to keep up with each increasingly baroque change to the Windows environment. Just as an example, over this time the latest "hot" communication paradigm that Microsoft recommended developers use in Windows changed from NetBEUI, to NetDDE, then OLE, followed by OLE2, then COM, DCE/RPC, DCOM, and now currently seems to be Web Services (SOAP and the like).*
> 
> *Meanwhile, in the UNIX world the Berkeley socket API was useful in the 1980s and is still the core of all communications frameworks in the open standards world. All the UNIX RPC, object and Web Service environments are built on that stable base. Learn as much about the proprietary environments as you need to be able to help people port programs over to open standards. You'll never be lost for work. The same is true of any proprietary environment, not just Windows. Windows just happens to be the one I know best.*
> 
> *What will get very interesting in the future is the effect a fully open Java platform will have on the software environment in the next ten years. After initially ignoring Java due to its proprietary restrictions, I now believe Java and it's associated libraries have the potential to be the next POSIX.*

This was written in 2007, so 15 years ago. Was Jeremy Allison right? 

I know people that left the software industry due to obsoletion, not able to keep up with the latest and greatest. Learning proprietary platforms is planned obsolesce for your career. Windows, a shadow of its former self, is now just an ads-delivery vehicle and a GUI toolkit for MS Office. Java, propelled by its openness and availability on all platforms, grew and is now more popular than ever, although it's not alone in being popular, or a POSIX-like platform, others being JavaScript, .NET, or LLVM, and all are FOSS.

There is one dimension that this misses – learning the latest and greatest can also be a losing bet. What young programmers should focus on is standards. And de facto standards happen with age, solutions becoming more entrenched and better as time passes, much like good wine.

The Atom[^1] text editor is dead. GitHub killed it, because it was acquired by Microsoft, and Microsoft has its own editor, VS Code[^2]. These editors were inspired by TextMate[^3], a once popular, but proprietary editor for macOS that died, and the resurrection attempt via open sourcing failed. VS Code is right now the most popular editor. I don't know if it will be around in another 20 years. But I do know that Emacs and Vi, both released in 1976 (46 years ago), will still be around in another 20 years, and the skills you acquire while using them won't be obsolete any time soon.

Programming languages become entrenched faster, because programs get built with them and then those programs need to be maintained. But Borland's Pascal[^4] or FoxPro are dead, and C isn't. Although, oddly, at the time of writing the TIOBE Index[^5] has Object Pascal / Delphi in 13th place 🤦‍♂️

Embrace open platforms, open standards, build on top of Open Source. But there's also wisdom in "embracing boring technology"[^6], as boring is simply a signal for older, more entrenched, more stable, that survived fashion trends. And boring technology is usually Open Source / Free Software, because FOSS survives for much longer 😉

In addition to preferring boring FOSS technology, I'd also add ... *learn math and algorithms*. Math is the ultimate language and open standard for what we do, and it will never be obsolete. And not much progress happened in CS algorithms, except for machine learning. These are the fundamentals, which you may shun, but if all you're doing is to call library functions, one of these days that job will get automated.

Also, and perhaps this is the most important advice — engage in building software that helps people. If you're not proud of your work, like for example if you work on an unscrupulous ads-delivery network or some online bets platform, or maybe if you work on military drones, quit your job and go work on software that doesn't make the world more miserable than it is. You may find your job technically challenging and stimulating, but working on immoral products is just not worth it.

---

I grew up as a software developer with such words, with essays instilling ideas of software freedom, and I see such advice less and less these days.

What changed is that Open Source won. It won the hearts and minds of software developers. Most of us build on top of FOSS libraries, and deploy on top of FOSS runtimes and operating systems, using many FOSS tools in the process. But it seems to me like the trend is reversing.

> *"Life swings like a pendulum backward and forward between pain and boredom."*
> 
> — Arthur Schopenhauer

When freedom is abundant, we begin taking it for granted, forgetting why it is needed, forgetting to contribute. Oblivion is how freedom dies.

---

[^1]: [Atom.io](https://atom.io/) ([archive](https://web.archive.org/web/20220922061411/https://atom.io/)), also see [Wikipedia](https://en.wikipedia.org/wiki/Atom_(text_editor)) — is a text editor developed by GitHub, based on Electron, scriptable via JavaScript/CoffeeScript;
[^2]: [VS Code](https://code.visualstudio.com/), also see [Wikipedia](https://en.wikipedia.org/wiki/Visual_Studio_Code) — is a text editor developed by Microsoft, also based on Electron, scriptable in TypeScript;
[^3]: [TextMate](https://en.wikipedia.org/wiki/TextMate) was a proprietary editor built for macOS, made popular by the screencasts of [DHH](https://en.wikipedia.org/wiki/David_Heinemeier_Hansson) and others;
[^4]: [Turbo Pascal](https://en.wikipedia.org/wiki/Turbo_Pascal) was the programming language and environment I learned in high school;
[^5]: [Tiobe Index](https://www.tiobe.com/tiobe-index/) ([archive](https://web.archive.org/web/20220922063355/https://www.tiobe.com/tiobe-index/)) is a piece of shit that people take way too seriously — the [GitHub language stats](https://madnight.github.io/githut/#/pull_requests/2022/1) ([archive](https://web.archive.org/web/20220909230229/https://madnight.github.io/githut/#/pull_requests/2022/1)) are IMO far better at assessing a language's popularity, as even if biased, it shows the FOSS output of the language's community, and that's a much stronger signal than Google searches, or whatever crap the TIOBE Index does;
[^6]: [Choose boring technology](https://mcfunley.com/choose-boring-technology) ([archive](https://web.archive.org/web/20220922063839/https://mcfunley.com/choose-boring-technology)) is an essay by Dan McKinley that became an instant hit;
