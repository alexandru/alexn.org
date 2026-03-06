---
title: "Copyright is Dead"
image: /assets/media/articles/2026-thomas-trying-to-fit.jpg
image_caption: >
  Thomas, my tomcat, trying to fit into a box of tissues, visibly distressed that he can't fit. This is a metaphor, not sure if it's working 😛
date: 2026-03-06T09:10:02+02:00
last_modified_at: 2026-03-06T11:39:22+02:00
tags:
  - AI
  - Open Source
  - Opinion
---

<p class="intro" markdown=1>
If copyrighted works can be whitewashed / reimplemented via AI, then copyright is dead. And now we have a case in public view, the [reimplementation of chardet](https://github.com/chardet/chardet/issues/327#issuecomment-4005195078), relicensed from LGPL to MIT, causing upheaval.
</p>

<p class="warn-bubble" markdown="1">
This is a yet another opinion piece on AI, sorry, I'm taking a 40-days break from social media, which prompts me to write more on my blog. At least I get to be less superficial about it.
</p>

The `chardet` reimplementation was created by pointing the AI at the project's test suite that works as the specification. However, if the project's source code was in the LLM's training data, then one can argue that this wasn't a *"clean room"* reimplementation. You don't necessarily need to copy/paste code from the original project in order to create a derivative work — people that get exposed to original source code can't really make the claim that they could execute a clean room reimplementation, which is why the guidelines for contributing to reverse engineering efforts (like the Wine or Mono projects) contained warnings against viewing Microsoft's proprietary code.

And many people are now worried that if this is legal, then [copyleft](https://en.wikipedia.org/wiki/Copyleft) is dead. And they should be worried, but it's not just copyleft fans that should be worried, but rather all creative industries that depend on copyright. Because if this passes, then *copyright is as good as dead*.

Well, I for one don't think this is all that bad. Sure, it can potentially leave us without a job, but copyright has always been ... *fake*. Copyright violations are not really *theft*, because copyright is not like actual private property — because if you're infringing on someone's copyright, you aren't depriving the owner of their possesion. Copyright can only work because it's a government-granted monopoly. And globally, it can only work because the US and Europe could use their economic strength to impose it via treaties.

One can make the case that it deprives the owner of future revenue and recognition, which is the case made by the likes of RIAA and MPAA, which is also why we ended up with [DRM](https://en.wikipedia.org/wiki/Digital_rights_management), i.e., software [defective by design](https://en.wikipedia.org/wiki/Defective_by_Design) and by law. Are we really siding with the RIAA, MPAA and Disney now? That should make us, Open Source fans, question our beliefs, despite the many benefits that copyright also bestowed on us.

And "copyleft" happened as a counter-reaction of hackers that used the law to turn copyright on its head. [The story goes](https://www.fsf.org/blogs/community/201cthe-printer-story201d-redux-a-testimonial-about-the-injustice-of-proprietary-firmware) that Richard Stallman, the guy behind the GPL license and the FSF, wanted to improve his printer's driver and he couldn't do that, because printer drivers started being proprietary, with no available source-code. If the guy had the possibility of reimplementing a printer driver for cheap, we probably wouldn't have a copyleft movement.

Copyleft hasn't been suitable for protecting many of authors' wishes and interests for some time. An early example of this was [tivoization](https://en.wikipedia.org/wiki/Tivoization), with GPL being patched in GPLv3. But then there was Linus Torvalds that came out against it, in [an interview](https://web.archive.org/web/20060813200643/https://www.forbes.com/technology/2006/03/09/torvalds-linux-licensing-cz_dl_0309torvalds1.html/), saying:

> *"To me, the GPL really boils down to "I give out code, I want you to do the same." The thing that makes me not want to use the GPLv3 in its current form is that it really tries to move more toward the "software freedom" goals. For example, the GPLv2 in no way limits your use of the software. If you're a mad scientist, you can use GPLv2'd software for your evil plans to take over the world ("Sharks with lasers on their heads!!"), and the GPLv2 just says that you have to give source code back. And that's OK by me. I like sharks with lasers. I just want the mad scientists of the world to pay me back in kind. I made source code available to them, they have to make their changes to it available to me. After that, they can fry me with their shark-mounted lasers all they want."* — Linus Torvalds, 2006

Another example was the proliferation of "source available" licenses that are not [Open Source](https://opensource.org/definition-annotated) or [Free software](https://en.wikipedia.org/wiki/Free_software). The first instance I remember is Microsoft's [Shared Source Initiative](https://en.wikipedia.org/wiki/Shared_Source_Initiative), back when Microsoft was treating Linux as "cancer". And such initiatives are now back in full force, because the era of interest-free money may be over, companies building Open Source struggling to survive and flipping, e.g., MongoDB, Elasticsearch, Akka. Their reasoning for doing so may be legitimate — copyleft doesn't work given the *"SaaS loophole"*, and if you try selling your Open Source product as SaaS, Amazon may be able to do it better and cheaper.

In fairness, they didn't [get the memo](https://www.joelonsoftware.com/2002/06/12/strategy-letter-v/) — Open Source, in the context of a business, can only work as a complementary to a proprietary product, as a way to bring costs down, or as a strategy to get rid of your competition.

But wait, in a world in which the cost of cloning stuff is going down, even if proprietary, or in a world in which laymen can just solve their own, simpler problems, without buying into a whole SaaS deal, avoiding to get stuck with everything but the kitchen sink ... *SaaS is probably dead, too.*

And yet another example are all the people concerned that their software ends up being used in a way they disagree with (e.g., by the military, or for surveillance). Famously, a license like [the Software shall be used for good, not evil](https://en.wikipedia.org/wiki/Douglas_Crockford#Software_license_for_%22Good,_not_Evil%22) is not compatible with Open Source / Free Software, like all restrictions on usage. Although, to be frank, you may try banning the military from using and abusing your software, but that's a bit naive, because the state, by design, has a monopoly on violence, copyright is only possible due to this social construct, and you can't expect the military to show restraint when it comes to copyright infringements, especially during war or "special operations".

I mentioned that it's not all doom and gloom because ...

If you're an anarchist loving the ideas behind Open Source, you should like some of these developments, because yes, you may now be able to fix your printer driver. And this ability may not be restricted just to software developers, but to laymen as well. *"Democratizing"* this or that should have happened for software development, and instead, the world moved to protected, defective by design, consumption-only devices, in order for industry to protect copyright, the world converging to a handful of monopolies built on copyright and patents.

Well, I may worry about my future, but my anarchist heart is glad to see the days of copyright numbered.