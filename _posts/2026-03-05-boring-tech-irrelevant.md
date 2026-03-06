---
title: "Boring Tech May Become Irrelevant Tech"
image: /assets/media/articles/2026-thomas-worried.jpg
image_caption: >
  Thomas, self-employed tomcat, worried about the evolution of the software industry.
date: 2026-03-05T18:12:06+02:00
last_modified_at: 2026-03-06T06:49:04+02:00
tags:
  - AI
  - FP
  - Opinion
  - Programming
  - Languages
---

<p class="intro" markdown=1>
You may have read the ["Boring" Tech Stack](https://mcfunley.com/choose-boring-technology) in 2015, a view with which I've wholeheartedly agreed. And if you didn't agree with this view, the corporation you're working for surely agreed. It's why companies like Google have had a list of "approved" languages, for example. But is this view relevant in 2026? I think not.
</p>

<p class="info-bubble" markdown="1">
This is a continuation of [Programming Languages in the Age of AI Agents](./2025-11-16-programming-languages-in-the-age-of-ai-agents.md).
</p>

Companies pick "boring" tech because boring is reliable, it does the job, and most importantly, it minimizes risk. Companies don't want to be locked into tech stacks that are obsolete, because:

- Hiring developers becomes more challenging, and historically, it's been good to pick tooling that optimizes for "horizontal scalability" of development — i.e., optimize for head count — which makes sense in a growing industry, given there are more beginners than seniors, beginner-friendly tech wins, and popular tech is beginner-friendly, due to it being old, popular and targeting simple apps.
- Projects get stuck on obsolete tech, companies being forced to support that tech stack on their own. Project rewrites are super risky, the industry being filled with stories of failed rewrites. As such, we now have it ingrained that a project rewrite is something [we should never do](https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/). So, companies want tech stacks that get supported for decades.
- A special mention here goes for maintenance — older tech tends to be more stable, whereas newer tech tends to break compatibility more often, and the upgrade treadmill sucks.
- The [YAGNI](https://en.wikipedia.org/wiki/You_aren't_gonna_need_it) mentality is most often good, our industry's history being filled with stories of projects preparing for "big data" with data that could easily fit in RAM.

But in 2026 we are facing the reality of AI/LLMs. I'll use the example of less popular programming languages, such as Rust, Scala, OCaml, F#, Haskell, and others. Here's why:

- The cost of refactoring for switching tech stacks, programming languages included, is going to zero.
- The cost of training new people on your tech stack also converges to zero — if your project has the right skills promoted and the guardrails, does it matter if novices aren't "functional programming" wizards from day 1?
- The cost of dependency upgrades goes to zero, becoming an automated process, even when it involves API breakage.
- Frontier models are good, but they still do dumb shit all the time, so having better tech, like a potent compiler to watch your back, matters.
- The feedback loop matters, and static, expressive type systems provide the most bang for the buck (optimal token usage).
- Top programming languages have the advantage of a large corpus available for training, however, that's also a liability, as the common denominator of all code seen in the wild is not very good (which is why by simply telling the LLM to use FP, it will generate better code for the simple fact that FP code seen in the wild tends to be higher quality)

People are already talking about programming languages designed for LLMs, not humans. I think that's nonsense; we'll use languages designed for LLMs *and* humans, because even if you are an AI maximalist, you still need to communicate with the AI system efficiently, and to have the ability to review what it did. And what will such a language look like?

Well, IMO (YMMV), such a language will be high-level, but it will also be very precise, very static, very expressive, in order to optimize the feedback loop, to optimize tokens, to minimize mistakes, to force LLMs and humans alike to apply mathematical reasoning. It's hard to picture us settling on natural languages (English); that boat sailed in the ~16th century when symbolic notation was adopted for math. And it's hard for me to see very popular languages like Java, Python or C++ surviving either, due to all their inherent unsafety.

Anyway, more to the point — given the costs of software maintenance, refactoring or adoption are significantly going down, converging to zero, then old lessons no longer make sense, and companies are already on outdated best practices regarding the adoption of tech stacks.

The next time you're in a meeting with stakeholders, they probably have LLMs/AI in their KPIs 😉, so now you have the words to fight back against Java, Spring, Hibernate and Oracle DB 😈