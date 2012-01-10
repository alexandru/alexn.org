---
title: "Getting Started with Android Development"
categories: [android, beginner, resources]
layout: post
---

The hardest part of getting started is installing the needed
development tools, making a Hello World, compiling it, deploying it
in the emulator and then trying it out on a real phone. Any journey
starts with a first step. I'm describing this here, with a follow-up
on learning resources later.

<!-- more -->

## Installing the Tools Needed

{% img right /assets/photos/start.jpg 200 %}

A prerequisite needed is a recent Java JDK. You need the official one
from Oracle, or at least OpenJDK. But don't try your luck with JDK 7,
as it is barely released. You can
[download Java from Oracle's website](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
if you're on Windows and there's even a preview for OS X, otherwise
try going to
[Apple's Developer Website](http://developer.apple.com/search/index.php?q=java).

On older Ubuntu (like the LTS):

{% highlight bash %}
sudo apt-get install sun-java6-jdk
{% endhighlight %}

On newer Ubuntu versions:

{% highlight bash %}
sudo apt-get install openjdk-6-jdk
{% endhighlight %}

Then
[Download the Android SDK](http://developer.android.com/sdk/index.html)
and decompress it. I prefer */opt/android* as the path.


What you downloaded is not the SDK, but a starter that downloads the
actual SDK. So you need to execute the file
*/opt/android/tools/android* or start *SDK Manager.exe*
(on windows). From then on you can select what SDK versions and
extra APIs you want installed. Don't skip the examples or the
documentation provided. More details can be found at
[developer.android.com](http://developer.android.com/sdk/installing.html)

## What IDE?

{% img right /assets/photos/idea-icon.png %}

The IDE preferred is Eclipse, because Google has been working on an
official plugin. However my experience with it has been awful and
I'm not the only one complaining. So really, don't bother with it.

Unfortunately Java is a bureaucratic language and it's very
uncomfortable working from a simple text editor. I'm using Emacs
most of the time, however in the case of working with Android I prefer an
IDE, even though you can work from the command line (I'll talk about
it in a next article).

What you really want is
[IntelliJ IDEA](http://www.jetbrains.com/idea/). The Community Edition
is open-source, free of charge and comes with functionality for
[building Android projects](http://www.jetbrains.com/idea/features/google_android.html).


They just released version 11 and it's very cool. They even added
one missing feature - the possibility of previewing Android XML
layouts. This doesn't seem like much, but it is useful, works as
expected and the interface builder from Eclipse is broken beyond
repair.

## Quick-start


See the
[Hello World Tutorial](http://developer.android.com/resources/tutorials/hello-world.html)
on Android Developers.


After creating the project and running it in the emulator, to deploy
this app on your own device you need to read this article on Android
Developers (great resources btw):
[Using Hardware Devices](http://developer.android.com/guide/developing/device.html).

I'll follow up soon with an article on the books, other technical
documentation and resources for learning about developing
apps. Follow my RSS feed.

