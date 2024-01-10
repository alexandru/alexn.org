---
title: "Scala's Future"
image: /assets/media/articles/2024-scala-hexa.png
image_caption: The Scala logo, in the shape of a hexagon, meant to fit the logos of certain well known libraries, as a hint 😜
date: 2024-01-10 19:37:53 +02:00
last_modified_at: 2024-01-11 13:49:21 +02:00
redirect_from:
  - /blog/2024/01/10/is-scala-in-trouble/
tags:
  - Scala
  - Scala3
  - Programming
  - Opinion
---

<p class="intro">
As software developers, we invest a lot in our tools. Time, energy, and feelings. We recommend tools to others; we build on top; we belong to a community; we contribute; hence we're eventually becoming stakeholders. And there's no other tool more clamored or risky in our belt than the programming language. Well, gather around, kids, let me tell you two stories from my past with the software industry…
</p>

## The Dot-Com Bubble

I joined the workforce in the aftermath of the [dot-com boom and bust](https://en.wikipedia.org/wiki/Dot-com_bubble). It was quite a bad time to be a rookie in the software industry, especially in Romania, a country still recovering from the dissolution of the Soviet Union. My first salary was $150 per month. And I remember a depressing article on [java.net](https://en.wikipedia.org/wiki/Java.net), advising Java developers that were left without a job to go back to school. The general feeling was that Java was dying, but as times proved, news of its death are always greatly exaggerated. And this was during the time I was learning Java, hoping to replace PHP, which I deeply disliked, but paid the bills. PHP is still one of the most popular programming languages on the web. We'll never get rid of it.

**Déjà vu:** We just experienced a bubble bursting. The year 2023 was no longer an employee's market. Have you noticed all the high-profile layoffs? In 2023, more than 260,000 people lost their job in tech, from over 1100 companies, surpassing the layoffs of 2022. The numbers are shocking because the industry seemed to be invincible during the pandemic. And these were just the numbers visible to Western media; e.g., countries from Eastern Europe don't have good stats, and markets like China's are opaque. Certainly, things aren't as bad as in 2001, with cause for optimism due to the AI hype, but the big layoffs and the downsizing are hard facts you can't ignore.

When you compare the activity on job websites that most people ignore, or the activity on Reddit, or on X/Twitter, or elsewhere, the activity for most programming languages seems to be declining. On StackOverflow too, and this one is interesting because activity for mainstream languages is also going down due to most interesting questions being answered. It may not be just the tech bubble bursting, but also the pandemic-induced fatigue, with many people being tired of spending time online.

In the Scala community, we sometimes talk of Rust or Kotlin as being shiny lights, but the proxies used for assessing a language's popularity show that both Rust and Kotlin [have stalled growth](https://redmonk.com/sogrady/2023/05/16/language-rankings-1-23/). It's funny how perception works. Don't get me wrong, I think Rust has had and will continue to have good growth and has a great future, and that's because it's positioned to compete with C++, which otherwise has no real competition. Rust is not a competitor of garbage-collected languages, because it's more difficult to use. For instance, it makes FP hard, actually, never mind the interactive development people are used to in dynamic languages. And also, your average code has a better chance of having good throughput in a managed language like Java. Which is counterintuitive for people romanticizing about native code and "zero-cost abstractions", and you can see how the hype cycles get fueled by people's hopes and dreams instead of hard facts, which are missing (computer science is still not a science).

<p class="warn-bubble" markdown="1">
This is my personal experience which you should take with a grain of salt. There's [an observational study](https://opensource.googleblog.com/2023/06/rust-fact-vs-fiction-5-insights-from-googles-rust-journey-2022.html) that disagrees with the point on productivity, from Google, which you should [also take with a grain of salt](https://examine.com/guides/how-to-read-a-study/). The field is so devoid of data, that results of surveys from beginners are interpretted as rigurous research, but at least Google tries to have some data, and we should encourage companies to do more of this.
</p>

All languages are having setbacks in this climate. Another example is TypeScript, which had some noteworthy libraries that decided to drop it from their codebase, like Svelte, Drizzle, or Turbo. Time may prove that there's more going on, but if we don't put any observations we make in context, we may miss the confounders, and it's a shame, given Scala's awesome trajectory thus far.

## Python's Plateau of Productivity

I've also been a Python and a Ruby developer, and I remember well the onslaught of Ruby on Python's seemingly fragile market share. Python (and Java) fans were actually afraid of Ruby burgeoning on the scene, and they had good reasons, because the languages seemed to be used for the same kind of problems, and are similar, despite the somewhat different philosophies. Ruby was fresh, Ruby seemed better for DSLs, and it has had "Ruby on Rails" as the killer app, which is a great showcase of what Ruby can do. At that time, Python fans were patting themselves on the back, reminding one another of the [hype cycle](https://en.wikipedia.org/wiki/Gartner_hype_cycle), hoping for the promised "plateau of productivity". I'm pretty sure that's where Li Haoyi [got the idea for his Scala article](https://www.lihaoyi.com/post/TheDeathofHypeWhatsNextforScala.html) on the same topic, since he's also a Python developer and fan. And yes, the "plateau of productivity" folks were right.

Python also went through a really slow and painful migration to Python 3 (AKA Python 3000). Version 3 came with a bunch of [breaking changes](https://docs.python.org/3.0/whatsnew/3.0.html), and because the language is dynamic and dependent on C extensions, it took forever for libraries to migrate. My sore spot was [Django](https://www.djangoproject.com/). As a side note, Django was also tightly coupled with the native MySQL client, which also made it hard to introduce async I/O via monkey patching, but that's another story. Python's reliance on native libraries is both a blessing and a curse. Consider that the last official Python 2.7.x release was in 2020, 12 year after the Python 3 release. And in 2023 it finally reached EOL on Ubuntu, while many organizations still use Python 2, unable to migrate.

In the meantime, Python became the world's most popular programming language. It had to do with market fitness, of course, being the language of choice for data science, due to projects such as Numpy, Scipy, Matplotlib, TensorFlow, Jupyter, others. And note that Python was not targeted at data science, it just happened organically. And data science is not the only domain Python is good at. For many years, Python has been one of the languages recommended for developing Linux applications, being distributed by default in most Linux distros, with GUI bindings being well-maintained. Python is also very decent for doing web development, with the aforementioned Django also being a killer app, despite its limitations.

Python had a BDFL, and was definitely designed with taste; however its direction went where the community wanted it, by open consensus, not committee. People just used Python because it solved their needs, and it grew from there. Do you know what [Python.org](https://www.python.org/)'s selling point is? That's a rhetorical question because you didn't know before I asked, and nobody cares. Nobody picks Python because of the official marketing brochure.

Also, when Python 3 was released, it was ignored. But in time, more and more new features were added to Python 3, making migration more enticing, such as [optional type hints](https://docs.python.org/3/library/typing.html), or [couroutines/tasks for async I/O](https://docs.python.org/3/library/asyncio-task.html), thus removing the need for previous hacks. When you introduce breaking changes, you need carrots to entice people to migrate despite the pain. Sorry, I don't make the rules 😉

**Déjà vu:** Doesn't the above story sound similar with Scala 3 and the fears some of you have regarding it? Of course, Python isn't Scala, and the past doesn't necessarily repeat itself.

However, here are some lessons we can learn from Python's history:

1. Community-driven direction, simply by people doing their thing, is good; you don't need a committee to decide what people build with the language, and complaining that multiple options exist, or complaining about certain libraries or techniques being more popular than others is silly.
2. Having multiple choices is not bad — Python may pride itself on being a "batteries included" language with an "only one way of doing things" philosophy, but those are just aspirations, as in practice it couldn't be further from the truth, Python having had multiple well-maintained libraries for doing the same thing, and non-orthogonal language features that were added to cope with the fact that the language can't have multi-line anonymous functions.
3. We want good build tools, but build tools don't make or break a language; here we should look at Python's `easy_install`, `pip`, `pyenv`, `virtualenv`, `pyenv-virtualenv`, `scons`, etc. or how they haven't solved yet the problem of depending on native libraries, therefore they need Docker for reproducible builds and deployments; the irony here being that Python needs a standard library with "batteries included" because depending on libraries turns out to be challenging for rookies. Having tools is great, but having fun and ways to get things done is more important.
4. Languages that break compatibility need new features to entice the community into migrating. When the migration isn't painless, the greatest competition comes from older versions of the language (i.e., Scala 2.13.x is already quite good, just as Python 2.17 was already quite good). And we need to be open to new developments, while giving constructive feedback; otherwise we sound like a bunch of old farts complaining about the changing times and the kids these days. The FUD around new features may end up discouraging some [really cool developments](https://github.com/scala-native/scala-native/pull/3286) that may even help the status quo.
5. Migrations, given breaking changes, can take a really long time, but established languages with active projects can afford to wait. What are companies going to do? Throw everything in the bin? That would be silly, and for this reason, incumbents rarely wither away, with very few notable exceptions. Instead, well maintained programming languages age like fine wine, only growing in popularity.

To keep in mind, at least until AGI takes over 🤖

## How's Scala doing?

YMMV, but here are my impressions:

- Scala 3 is objectively a better language, with much stronger compatibility guarantees.
- Tooling can always improve, but it has some great tooling already that other languages can only dream of (Scala CLI, Metals, IntelliJ IDEA, Scalafmt, Scala.js, etc.).
- It has several ecosystems of libraries that are mostly community-driven (Typelevel, com-lihaoyi, ZIO, etc.), distributing the risks; I mean, holy cow, the community may seem small, but it's still super productive, and this isn't a top-down cathedral (e.g., dotNET), it's a bazaar.
- Corporate support can be better, but we should also be thankful for Lightbend's contributions, for VirtusLab stepping up, and other languages with their communities would be lucky to have Scala Center. If this is what an academic language looks like, I think I want more academic languages.
- Scala is a mainstream language and was used in many projects that aren't going away.
- Scala is the most popular FP language, and it has some of the best resources for practicing and learning FP. It's also one of the most Python-like languages I've used. There's no doubt in my mind that it will continue to be in demand.

It's not all roses; tools could be improved, libraries could be more stable, jobs may be harder to find these days, but Scala developers are among the best paid on average, and the projects I see are quite exciting. I tried to jump ship just before the pandemic, to startups doing JavaScript, TypeScript, and Python. It was awful, and maybe I was just unlucky, but Scala jobs still have this je ne sais quoi that keeps me hooked. Perhaps it's because we aren't doing dumb web UIs to a database all the time, which also explains the attraction of some towards Rust 🤷‍♂️

How do I feel about Scala? I feel quite good. You see, I get bored easily, and I have a track record of jumping from tech stack to tech stack, just because. On the job, I've used PHP, Java, C#, C++, Perl, Python, Ruby, JavaScript, TypeScript, and I've also learned and played in my free time with many others, including the darlings du jour. With Scala, I did not have time to be bored, either because of involvement in FOSS, or because of the awesome projects I was hired to work on. It's a language that has grown with me, and the ecosystem always provides something new to learn, or some new library to get excited about, while matching my aspirations. And I'm not alone. If you take a look at the history of old-timers in the Scala community, you'll notice a clear progression in their coding style, as it's a language and ecosystem that grows with you. I always find it amazing how the same guy that worked on [Scalatra](https://scalatra.org/), later worked on [Http4s](https://http4s.org/), and that's the kind of evolution you seldom see elsewhere. I'm confident Scala 3 will give us new opportunities to learn, grow and build.

The "scalable" language, indeed 😍
