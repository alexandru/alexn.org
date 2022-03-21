---
title: "FreeSWITCH - Tips for Creating a Dialer"
date:   2009-02-20
last_modified_at: 2019-12-14
tags:
  - Best Of
  - VoIP
  - FreeSWITCH
  - JavaScript
  - Perl
image: /assets/media/articles/freeswitch1.png
generate_toc: true
description: >-
  FreeSWITCH is a free and open source application server for real-time communication, WebRTC, telecommunications, video and Voice over Internet Protocol. Let's build a VoIP dialer with it.
---

## Introduction

<p class="intro withcap">FreeSWITCH is a free and open source application server for real-time communication, WebRTC, telecommunications, video and Voice over Internet Protocol. Let's build a VoIP dialer with it.</p>

<p class='info-bubble' markdown='1'>
  This article also refers to FreeSWITCH Revision `10694`. Things could have changed since then, there might be better ways for doing what's described in this article; ask on their mailing list.
</p>

We are trying to migrate one of our existing Asterisk setups to FreeSWITCH. These are some tips to walk you thorough the hard part of learning the inners of FreeSWITCH for creating a simple dialer.

As you will learn, FreeSWITCH is a little overwhelming, while being flexible and easy to use.

Being a software developer, I prefer the flexibility of a programming language, rather than working with XML configuration files. Fortunately the standard FreeSWITCH distribution comes with both a SpiderMonkey engine (javascript) and Lua embeded. And it works great for our needs.

## Prerequisites

Our setup is based on Debian Linux. You should have no problem following it for other Linux-distros or operating systems though.

For external scripts, we prefer Perl, and I'll give a code sample using it, but I don't think it would be a problem porting it to the language of your choice.

You'll also need a [SIP](http://en.wikipedia.org/wiki/Session_Initiation_Protocol) provider for initiating external VoIP calls.

## Step 1: Instalation

You can find detailed installation instructions here: [http://wiki.freeswitch.org/wiki/Installation_Guide](http://wiki.freeswitch.org/wiki/Installation_Guide).

Our setups are based on Debian, and there are also instructions for [building Debian packages](http://wiki.freeswitch.org/wiki/Installation_Guide#Debian_Linux).

If you build Debian packages, the default instalation path is `/opt/freeswitch` (revision 10694). You can change that by modifying debian/rules in the sources directory (search for "`/opt/freeswitch`", you'll find a "`./configure`" section), once you download it. But this tutorial is based on the default settings.

## Step 2: Configuration

I won't dwell on details since the configuration can be a painful process, and you would be better served contacting the [FreeSWITCH community](http://wiki.freeswitch.org/wiki/Main_Page#Community_and_Support).

But you'll probably need to configure authentication settings for your SIP provider. To do that, look at the lead on the wiki: [external SIP profiles](http://wiki.freeswitch.org/wiki/Getting_Started_Guide#External). For us it was easy since our provider doesn't require user/password authentication, and no extra configuration was necessary.

## Step 3: Initiating External Calls

In case the FreeSWITCH daemon has started, you need to stop it for now ...

```bash
/etc/init.d/freeswitch stop
```

If you also have Asterisk up and runnings, you should stop it also, to avoid any conflicts.

Then open the FreeSWITCH console:

```bash
/opt/freeswitch/bin/freeswitch -c
```

Calls can be initiated by using the [originate command](http://wiki.freeswitch.org/wiki/Mod_commands#originate). You'll need a "call url" with the syntax described on the wiki: [Sofia#Syntax](http://wiki.freeswitch.org/wiki/Sofia#Syntax).

To make a simple call, let's setup a simple dialplan. Also, let's also play a simple audio file, according [to the wiki example](http://wiki.freeswitch.org/wiki/Playing_recording_external_media#Play_wav).To do that, create a dialplan extension by creating a file named `/opt/freeswitch/conf/dialplan/default/2009_play.xml` with the following text:

```xml
<include>
  <extension name="wavs">

    <condition field="destination_number" expression="^2009$">
      <action application="sleep" data="2000"/>
      <action application="playback" data="/path/to/your.wav"/>
    </condition>

  </extension>
</include>
```

The file is self-descriptive. When the phone is answered, it waits 2 seconds before playing your audio file of choice.

Now, in the Free console execute the following command (while providing a real number and your own SIP provider, of course):

```bash
originate sofia/external/$number@$myprovider.com 2009
```

If everything goes well (the phone rings, and you can hear the audion file), then **congratulations**, you're well on your way :)

## Step 4: Scripting

Freeswitch comes with Spidermonkey, and Lua embedded, and also offers integration with other languages, like Python and Perl. I'm going to exemplify Javascript, because it's a decent mainstream language that I like, but if you're worried about performance or you just want to have some fun, you should give Lua a try.

I also really, really hate XML configuration files. So I wanted to do everything from a script file, with these reasons on top of my head:

1.  general-purpose scripting languages make me happy
2.  you gain flexibility ... and stuff like retrying the call based on certain conditions, or a finite state automata depending on the client/campaign ... easy as pie
3.  have I mentioned that I hate XML?

In your favorite text editor, create a file "voice.js", with the following code:

```javascript
session = new Session('sofia/external/$number@provider');
// The following line is a deprecated method
// session.originate(undefined, 'sofia/external/$number@provider');

session.waitForAnswer(10000);

if (session.ready()) {
    session.sleep(1000);
    session.streamFile('/path/to/your.wav');
}
```

See:

* [waitForAnswer](http://wiki.freeswitch.org/wiki/Session_waitForAnswer)
* [streamFile](http://wiki.freeswitch.org/wiki/Session_streamFile)

For our purposes, this snippet is almost equivalent to our initial dialplan extension. To execute it, in the FreeSWITCH console run the following command:

```bash
jsrun /path/to/voice.js
```

## Step 5: More Scripting

Now that we've got working code, lets expand it a little to make it more useful.

### How to send a caller-id when initiating calls?

We want the call to have an associated caller-ID. The caller-ID is passed by setting the channel variables _origination_caller_id_number_ and _origination_caller_id_name_. Try it in a FreeSWITCH console right now by executing this command:

```bash
originate {origination_caller_id_number=123456, \
           ignore_early_media=true}sofia/external/$number@provider &
```

Or in your script:

```js
var session = new Session(
  "{origination_caller_id_number=1234567}"
  + "sofia/external/$number@provider"
);
```

For the B-leg of a bridged connection, you either set "`origination_caller_id_(name/number)`" on the new connection, or, as a shortcut, on the A-leg you can specify the channel variables _effective_caller_id_number_ and _effective_caller_id_name_ which are passed to any B-leg call initiated. Try it in a console:

```bash
originate {origination_caller_id_number=1111111111, \
           effective_caller_id_number=222222222, \
           ignore_early_media=true}sofia/external/$number@provider \
           &bridge(sofia/external/$second_number@provider)
```

### How to retry if phone is busy?

We want to retry the call immediately after, maybe the client pressed the wrong button and rejected the call. As in this [wiki page](http://wiki.freeswitch.org/wiki/Busy_Call_Retry), but with a twist: we wouldn't want to retry more than once, because annoyed customers are not happy customers.

```js
function makeCall(nr_or_tries) {
    session = new Session('sofia/external/$number@provider');
    // The following line is a deprecated method
    //session.originate(undefined, 'sofia/external/$number@provider');

    session.waitForAnswer(10000);

    if (session.cause == "USER_BUSY") {
        // not sure if this is necessary
	// session.hangup();

	if (nr_or_tries <= 1) {
	    console_log("Action: Trying again!");
	    return true;
	}

	console_log("Action: Cannot try again, skipping!");
    }


    if (session.ready()) {
        session.sleep(1000);
	session.streamFile('/path/to/your.wav');
	session.hangup();
    }
}

var nr_or_tries = 0;

while (nr_or_tries < 2) {
    if (!makeCall(nr_or_tries++)) break;
}
```

See: [hangup](http://wiki.freeswitch.org/wiki/Session_hangup).

Of course, this script retries the call immediately. This may not be what you want (you may want to wait 10 minutes for a retry), so our favorite way for retries is through an external script that handles the calls queue.

### How to detect phone keys pressed?

Now we're getting somewhere :)

The first thing you have to do, after the originate command, is activating [DTFM detection](http://wiki.freeswitch.org/wiki/Misc._Dialplan_Tools_start_dtmf). This can be done in an extension configuration file, but I prefer doing it from our script, for reasons stated above. So after you execute the _originate_ command, you have to execute the following:

```js
session.execute("start_dtmf");
```

Now, when you play an audio file, the `streamFile` function accepts as parameter an event handler, which can be used to detect keys pressed. So, lets say than when you press "1", you want to repeat your message, and when you press "2", you want to play another audio file:

```js
var session = new Session(/*... params ... */);
// The following line is a deprecated method
//session.originate(/*... params ... */);
session.execute("start_dtmf");

var on_event = function ( session, type, data, arg ) {

    // we are only concerned with "dtmf" event types
    if (type != "dtmf") return;

    if (data.digit == "1") {
        return "seek:0";
    }
    else if (data.digit == "2") {

        session.sleep(1000);
	session.streamFile("/path/to/another.wav");

	/* current audio file is stopped
	* on returning false
	*/
	return false;
    }


    /* for any other key pressed
    * returning true keeps the current audio playing
    */
    return true;
};

if (session.ready()) {
    session.sleep(2000);
    session.streamFile("/path/to/your.wav", on_event);
}
```

**Note:** minutes cost money, so you should add a counter to limit the maximum times a message can be replayed. There are many weirdos out there 😉

### How to create a connection between your session and another phone?

Maybe you want your client to be connected to a real operator (when he's pressing "0" on his phone keyboard maybe?). It's easy, here's how:

```js
// the original session
session = new Session('sofia/external/$number@provider');
// The following line is a deprecated method
// session.originate(undefined, 'sofia/external/$number@provider');

session.answer();

if (session.ready()) {
    var new_session = new Session('sofia/external/$another_number>@provider');
    // The following line is a deprecated method
    //new_session.originate(session, 'sofia/external/$another_number@provider');
    new_session.answer();

    if (new_session.ready()) {
        bridge(session, new_session);
    }
}
```

See: [bridge](http://wiki.freeswitch.org/wiki/Mod_commands#bridge). If you want to add the actual key-press event, see the example above.

### How to execute external commands from your script?

If you want to execute an external script (like for sending a notification when a certain event happens), you can use the [system](http://wiki.freeswitch.org/wiki/Javascript_Misc_system) command.

If you want to execute an external command, and process its output, you can open a pipe using the [File](http://wiki.freeswitch.org/wiki/File) object. In FreeSWITCH you do have the possibility of accessing a database using ODBC, but I haven't tried it, and in case it doesn't work, you can always write an external script that does the processing you need, and then returns a JSON, or an XML file.

## Step 6: Communicating with FreeSWITCH using mod_event_socket

Playing in the FreeSWITCH console is fun, but what you need is a server who receives notifications from an external script.

First, shut down the FreeSWITCH console, and start FS in daemon mode.

```bash
/etc/init.d/freeswitch start
```

Next, copy your work thus far (which I assume it's located in `dialer.js`) to `/opt/freeswitch/scripts`. That's where scripts are usually deployed in FreeSWITCH.

FreeSWITCH can communicate through [mod_event_socket](http://wiki.freeswitch.org/wiki/Mod_event_socket). You can communicate using a simple telnet connection, but I'm lazy, and [Net::Telnet](http://search.cpan.org/~jrogers/Net-Telnet-3.03/lib/Net/Telnet.pm) is complaining about a missing login prompt. Luckily, in the FreeSWITCH sources directory, you'll find a sample [perl command client](http://wiki.freeswitch.org/wiki/Mod_event_socket#perl_command_client). The source code is located in `freeswitch_src/scripts/socket` and in there you'll find the perl package _FreeSWITCH::Client_. Copy it to your project's location, and create a script called `dialer.pl` with the following code:

```perl
#!/usr/bin/perl
use strict;
use warnings;

# make sure it's located in your @USE paths
use FreeSWITCH::Client;

my $fs = init FreeSWITCH::Client {-password => 'ClueCon'} or die "Error: $@";

# shows number of active channels ...
# useful when you want to control the maximum number of
# calls made simultaneously

$reply = $fs->command("show channels");
print "Channels\n------------\n$reply\n";

# calls our script, that initiates a call
# the command is non-blocking, so you can make multiple
# calls in parallel

$fs->command("jsrun dialer.js");

$fs->disconnect();
```

Btw, if you're not feeling comfortable about communicating through plain-old sockets with FreeSWITCH, try [mod_http](http://wiki.freeswitch.org/wiki/Mod_http).

## Wrapping up

Congratulations, you've made it to the end. You just need to add you're specific business logic, and you already have a kick-ass dialer.

There are lots of scenarios not addressed by this tutorial. One need you might have would be to get the logs of your calls, and see what customers haven't answered, what customers pressed what key, the average duration of a call, and other such niceties. Since this is a big topic to talk about, and since I still have some research to do, this deserves a whole new article.
