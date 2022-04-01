---
title: "Add to NewsBlur Bookmarklet"
tags:
  - Web
description:
  An Add to NewsBlur bookmarklet that you can copy-paste for iPhone/iPad/Android usage
image: /assets/media/articles/newsblur.png
---

<p class="intro withcap" markdown='1'>I'm using [NewsBlur.com](https://www.newsblur.com/) for consuming RSS feeds. It's a pretty cool service, however adding a new RSS feed from iOS proves to be a challenge and the "goodies" section provides no way for easily adding a bookmarklet for adding a feed.</p>

The iPad itself makes it difficult to add bookmarklets, so here's a
tutorial:

1. Go to [NewsBlur.com](https://newsblur.com) and add it as a bookmark
   (click on the box with the arrow in it next to the Safari address bar)   
2. We need to edit the new bookmark: tap the address bar in Safari
   and you should see all bookmarks, press and hold on the new
   "NewsBlur.com" bookmark that you created and then tap "*Edit*"
3. Change the title to something like: "*Add to NewsBlur*"
4. Copy/paste the following text for the URL:

<textarea readonly="readonly" style="width:100%;height:100px;max-width:100%;background-color:#f0f0f0;">javascript:(function%20()%20%7Bvar%20l%3Ddocument.location%2B%27%27%3Bif%20(l.match(%2F%5E(%3F%3Ahttps%3F%3A%5B%2F%5D%7B2%7D(%3F%3Awww.)%3F)%3Fnewsblur.com%2Fi))%20alert(%22Cannot%20add%20NewsBlur.com%20itself!%22)%3B%20else%20window.location%20%3D%20%27https%3A%2F%2Fwww.newsblur.com%2F%3Furl%3D%27%2BencodeURIComponent(l)%3B%7D)()%3Bvoid(0)</textarea>

For the desktop you can also drag this link:

<a style="display:block;width:200px;padding:10px;background-color:#436592;color:#fff;text-decoration:none;font-weight:bold;" href="javascript:(function%20()%20%7Bvar%20l%3Ddocument.location%2B%27%27%3Bif%20(l.match(%2F%5E(%3F%3Ahttps%3F%3A%5B%2F%5D%7B2%7D(%3F%3Awww.)%3F)%3Fnewsblur.com%2Fi))%20alert(%22Cannot%20add%20NewsBlur.com%20itself!%22)%3B%20else%20window.location%20%3D%20%27https%3A%2F%2Fwww.newsblur.com%2F%3Furl%3D%27%2BencodeURIComponent(l)%3B%7D)()%3Bvoid(0)">
  Add to NewsBlur</a>

Here is the unencoded Javascript for your inspection:

```javascript
(function () {
  var l = document.location+'';
  if (l.match(/^(?:https?:[/]{2}(?:www.)?)?newsblur.com/i)) 
    alert("Cannot add NewsBlur.com itself!");
  else
    window.location = 'https://www.newsblur.com/?url=' + encodeURIComponent(l);
})();void(0)
```

Enjoy!
