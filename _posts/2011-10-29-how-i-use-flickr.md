---
title: "How I Use Flickr: For Backup"
last_modified_at: 2019-12-15
tags:
  - Cloud
  - API
  - Ruby
image: /assets/media/articles/flickr.jpg
image_caption: "<a href='https://flic.kr/p/qYPVGA' target='_blank'>Source</a>"
description: >-
  I’ve got a growing number of personal pictures and the collection is growing since 2003 ... Pro accounts on Flickr have unlimited storage and can upload and access full-resolution pictures.
---

<p class="intro withcap">
  I've got a growing number of personal pictures and the collection is growing since 2003, when I got my first digital camera, a shitty Sanyo that still works and that I still use whenever I forget about my Nikon.
</p>

But here's the thing with digital pictures - _**they are cheap to make, but also easy to lose**_. Digital storage is not as reliable as glossy paper. Pictures printed on paper can easily last for a 100 years. That's not the case with any digital storage medium and we will suffer for it.

## Storing My Pictures In The Cloud

Pro accounts on Flickr have unlimited storage and can upload and access full-resolution pictures. This is great, although be careful about believing in "unlimited plans", as nothing is really unlimited and by abusing Flickr you may find yourself locked out of your account.

<p class='info-bubble' markdown='1'>
  **UPDATE (2019-12-15):** since Flickr has been acquired by SmugMug, the free accounts no longer have unlimited, or the 1 TB of space we had in the Yahoo days. Pro accounts continue to have unlimited storage, but you have to keep paying for Pro, otherwise they'll eventually delete your archive.
</p>

Unfortunately the tools for uploading really suck and I haven't encountered yet a graphical interface that did what I needed. So for synchronizing, I've built my own script in Ruby using the excelent [Flickraw gem](https://hanklords.github.com/flickraw/) and [exifr](https://github.com/remvee/exifr), another Ruby gem that reads Exif headers from Jpeg files.

One common problem is that you ALWAYS have duplicates. And you don't want to upload duplicates. What you really want is an "_rsync_" command for Flickr. But how do you know if a picture was already uploaded?

The approach I'm using is to add a [machine tag](http://www.flickr.com/groups/api/discuss/72157594497877875/) to my pictures, which is set like a tag, but has the format "namespace:key=value". This machine tag represents the MD5 hash of the picture and if you want to see if a certain photo was already uploaded to flickr, you can always [search for it](https://www.flickr.com/services/api/flickr.photos.search.html). Here's how it looks on one of my pictures:

```bash
checksum:md5=5b2fa91c38a7f878088e1420b924e6d9
```

Besides this, I have this problem with some of the older photos taken by my Sanyo, where the taken-date is totally fucked and for personal photos the taken date is maybe more important than the actual photo quality. I use the excelent [ExifTool](http://www.sno.phy.queensu.ca/~phil/exiftool/) to correct those photos. It's nice building on the hard work of other people ;)

So, currently I have 3545 pictures uploaded on Flickr in full resolution and the number will more than triple as soon as I make an inventory of my pictures stored on old hardware I've got lying around.

It is fun being a developer. I can make shit happen.

## Flickr is Not A Reliable Backup

Flickr is an online service that isn't meant for being a backup. I share only a fraction of what I upload, everything else is _family only_. They may terminate your account at any time for whatever reason. They may also go out of business. Yahoo may sell it, etc, etc... I do think Flickr is awesome btw and one reason that I store my photos on Flickr is to be able to always have the whole archive with me. But for backup alone, that's not enough.

What you really need to do is:

* your main repository should be stored locally and properly maintained - I do that on my main computer currently, but multi-TB external hard-drives are cheap
* in case of cloud backup, you always need a secondary service for redundancy

Google's Picasa is a good option because you can explicitly buy storage. This means that if you pay for 80 GB of storage nobody is going to get upset that you uploaded 80 GB of private photos ... also, if your photo collection matters to you, I wouldn't put my trust in their Google+ offering (photos of up to 2048x2048 pixels do not count towards your free quota). That's because that offer is not meant for you. Just pay up.

So on Google's Picasa, I'm currently working on integrating with their API too. The desktop app is nice, but too limited for me.
