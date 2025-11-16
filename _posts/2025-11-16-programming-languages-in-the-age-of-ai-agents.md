---
title: 'Programming Languages in the Age of AI Agents'
date: 2025-11-16T08:14:15+02:00
last_modified_at: 2025-11-16T12:28:43+02:00
image: /assets/media/articles/2025-math-github-copilot.png
image_hide_in_post: true
tags:
  - AI
  - FP
  - Opinion
  - Programming
  - Languages
---

<p class="intro" markdown=1>
In the age of "AI" Agents generating the code, **is your programming language choice still relevant?** Or will we just converge on using the top 5 programming languages, because that's what the "AI" has been trained on? You can also ask the same question for any other piece of tech from your stack.
</p>

At work, I've built several Python scripts doing various boring chores. GitHub's Copilot, powered by GPT or Claude Sonnet, does a reasonably good job at writing Python scripts. Furthermore, I've seen Python scripts developed by rookies that are worse than what these agents can generate. A programming language's popularity is a feedback loop. These days, because Python is popular, having available a huge training corpus, "AI" agents can be successful at generating Python scripts that work.

For programming language aficionados, for people loving their craft, while there is reason to worry that "AI" Agents can kill the long tail, I also think there are reasons to celebrate the dawn of "AI". Here's why:

**1) Having a compiler with an expressive static type system helps the "AI" Agent converge on a solution with a much shorter feedback loop.**

*"If it compiles, it runs"* was never fully true, but in programming languages like Scala, Haskell, or Rust, our confidence in the code is indeed much higher once the code compiles.

To give an example, Scala 3 has been on the market for a while, but there's not much public code published that deals with Scala 3's new macro system, and yet, "AI" Agents are able to generate code that works. This is very visible when using VS Code with GitHub Copilot, because it's integrated with the LSP server, so you see its mistakes in real-time ([Metals](https://scalameta.org/metals/) being quick to highlight compilation errors); and so the agent goes through several iterations trying to fix whatever compiler error it sees; with the result most often being code that compiles.

This ability to iterate and converge towards a working solution based on external feedback (from a compiler, from unit tests) is what makes "AI" Agents usable. And, having an expressive/powerful static type system provides much faster feedback than other validation types, such as unit tests. When people complain about Scala's or Rust's compilers being slow, they forget that they eliminate the need for unit tests guarding against entire classes of errors. And we need all the help we can get to guard against "AI" hallucinations 😉

**2) We need the ability to review what the "AI" Agent does. Can you reason about the generated code?**

Programmers may describe *"what they want"* instead of *"how"* in natural language, however, they still need to ensure that they're getting what they've asked for. Just executing the program, and looking at the output, is a very superficial way to test it, as we should all know by now. So at the very least you want tests, and tests are boring, we want them automated, so you want to see the tests that the agent has generated. Did the agent generate tests for all corner cases? You can't really say that without looking at the code.

And there's another looming issue that's happening with agent-generated code that people aren't aware of, yet: **[the comprehension debt](https://codemanship.wordpress.com/2025/09/30/comprehension-debt-the-ticking-time-bomb-of-llm-generated-code/)**. You see, the software project isn't just about telling the computer how it needs to behave, in order to produce some desired outcome. It's also about the knowledge you've built along the way. And if you have no people left on the team that understand the inner workings of a project, you're screwed. And "AI" Agents won't help, because they have a limited context window that tends to vanish. You won't keep around the dialogs you have with the agent, and even if you do, that kind of documentation is poor and can be misinterpreted; context poisoning is also a thing.

Peter Naur writes in [Programming as Theory Building](https://pages.cs.wisc.edu/~remzi/Naur.pdf) that:

> "_Although it is essential to upgrade software to prevent aging, changing software can cause a different form of aging. The designer of a piece of software usually had a simple concept in mind when writing the program. If the program is large, understanding that concept allows one to find those sections of the program that must be altered when an update or correction is needed. Understanding that concept also implies understanding the interfaces used within the system and between the system and its environment._"
>
> "_Changes made by people who do not understand the original design concept almost always cause the structure of the program to degrade. Under those circumstances, changes will be inconsistent with the original concept; in fact, they will invalidate the original concept. Sometimes the damage is small, but often it is quite severe. After those changes, one must know both the original design rules, and the newly introduced exceptions to the rules, to understand the product. After many such changes, the original designers no longer understand the product. Those who made the changes, never did. In other words, nobody understands the modified product. Software that has been repeatedly modified (maintained) in this way becomes very expensive to update. Changes take longer and are more likely to introduce new “bugs”. Change induced aging is often exacerbated by the fact that the maintainers feel that they do not have time to update the documentation. The documentation becomes increasingly inaccurate thereby making future changes even more difficult._"
> 
> ...
> 
> "_At least with certain kinds of large programs, the continued adaptation, modification, and correction of errors in them, is essentially dependent on a certain kind of knowledge possessed by a group of programmers who are closely and continuously connected with them._"
>
> "_Programming should be regarded as an activity by which the programmers form or achieve a certain kind of insight, a theory, of the matters at hand. This suggestion is in contrast to what appears to be a more common notion, that programming should be regarded as a production of a program and certain other texts._"

At the same time, it's still true that the _source of truth_ is the source code itself, always has been, always will be. So how do you preserve knowledge, despite the natural churn and evolution that happens in software projects?

Well, one way of doing it is with great source code that makes design and intent clear. And great source code is like math, ageless, describing what you want, not how, with an architecture that allows for evolution, but at the same time makes clear the design's invariants, i.e., its so-called laws. Programming in a higher-level language matters for "AI" Agents as well. It matters if the source code fully describes the specifications (e.g., the original intent or design constraints) or not. "AI" Agents may be good at assembly language, but they can't be that good, given that serializing specs in assembly is a lossy process.

And for reviewing the source code, [deductive reasoning](https://en.wikipedia.org/wiki/Deductive_reasoning) will never go out of fashion, because it's how the human brains work. Therefore, [functional programming](./2017-10-15-functional-programming.md) with its "_equational reasoning_" is still valuable in the age of "AI" Agents, and arguably, even more so, because you're dealing with [an inconsistent idiot that can't learn](./2025-10-27-ai-sucks-the-joy-out-of-programming.md).
