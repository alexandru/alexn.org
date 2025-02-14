---
date: 2022-12-04 12:01:00 +02:00
last_modified_at: 2025-02-14T09:46:52+02:00
---

# Bookmarklets

## Sharing

### Twitter

Beautified:

```javascript
(function() {
    t = document.title;
    t = t ? '"' + t + '"' + "\n\n" : "";
    window.open(
        `https://x.com/intent/tweet?text=${encodeURIComponent(t)}${document.location.href}`,
        "Share on Twitter",
        "scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0"
    )
})()
```

Minified:

```javascript
(function(){t=document.title,t=t?'"'+t+'"\n\n':"",window.open(`https://x.com/intent/tweet?text=${encodeURIComponent(t)}${document.location.href}`,"Share on Twitter","scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0")})()
```

Encoded:

```
javascript:%28function%28%29%7Bt%3Ddocument.title%2Ct%3Dt%3F%27%22%27%2Bt%2B%27%22%5Cn%5Cn%27%3A%22%22%2Cwindow.open%28%60https%3A%2F%2Ftwitter.com%2Fintent%2Ftweet%3Ftext%3D%24%7BencodeURIComponent%28t%29%7D%24%7Bdocument.location.href%7D%60%2C%22Share%20on%20Twitter%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29
```

Drag and drop bookmarklet:<br>
**[<a href="javascript:%28function%28%29%7Bt%3Ddocument.title%2Ct%3Dt%3F%27%22%27%2Bt%2B%27%22%5Cn%5Cn%27%3A%22%22%2Cwindow.open%28%60https%3A%2F%2Ftwitter.com%2Fintent%2Ftweet%3Ftext%3D%24%7BencodeURIComponent%28t%29%7D%24%7Bdocument.location.href%7D%60%2C%22Share%20on%20Twitter%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29">Share on Twitter</a>]**

### Mastodon.social

Beautified:

```javascript
(function() {
    t = document.title;
    t = t ? '"' + t + '"' + "\n\n" : "";
    window.open(
        `https://mastodon.social/share?text=${encodeURIComponent(t)}${document.location.href}`,
        "Share on Mastodon",
        "scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0"
    )
})()
```

Minified:

```javascript
(function(){t=document.title,t=t?'"'+t+'"\n\n':"",window.open(`https://mastodon.social/share?text=${encodeURIComponent(t)}${document.location.href}`,"Share on Mastodon","scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0")})()
```

Encoded:

```
javascript:%28function%28%29%7Bt%3Ddocument.title%2Ct%3Dt%3F%27%22%27%2Bt%2B%27%22%5Cn%5Cn%27%3A%22%22%2Cwindow.open%28%60https%3A%2F%2Fmastodon.social%2Fshare%3Ftext%3D%24%7BencodeURIComponent%28t%29%7D%24%7Bdocument.location.href%7D%60%2C%22Share%20on%20Mastodon%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29
```

Drag and drop bookmarklet:<br>
**[<a href="javascript:%28function%28%29%7Bt%3Ddocument.title%2Ct%3Dt%3F%27%22%27%2Bt%2B%27%22%5Cn%5Cn%27%3A%22%22%2Cwindow.open%28%60https%3A%2F%2Fmastodon.social%2Fshare%3Ftext%3D%24%7BencodeURIComponent%28t%29%7D%24%7Bdocument.location.href%7D%60%2C%22Share%20on%20Mastodon%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29">Share on Mastodon</a>]**

### Facebook

Beautified:

```javascript
(function () {
    t = document.title;
    t = t ? '"' + t + '"' + "\n\n" : "";
    window.open(
        `https://www.facebook.com/sharer.php?src=bm&v=4&i=1628766166&u=${document.location.href}&t=${encodeURIComponent(t)}`,
        "Share on Facebook",
        "scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0"
    )
})()
```

Minified:

```javascript
(function(){t=document.title,t=t?'"'+t+'"\n\n':"",window.open(`https://www.facebook.com/sharer.php?src=bm&v=4&i=1628766166&u=${document.location.href}&t=${encodeURIComponent(t)}`,"Share on Facebook","scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0")})()
```

Encoded:

```
javascript:%28function%28%29%7Bt%3Ddocument.title%2Ct%3Dt%3F%27%22%27%2Bt%2B%27%22%5Cn%5Cn%27%3A%22%22%2Cwindow.open%28%60https%3A%2F%2Fwww.facebook.com%2Fsharer.php%3Fsrc%3Dbm%26v%3D4%26i%3D1628766166%26u%3D%24%7Bdocument.location.href%7D%26t%3D%24%7BencodeURIComponent%28t%29%7D%60%2C%22Share%20on%20Facebook%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29
```

Drag and drop bookmarklet:<br>
**[<a href="javascript:%28function%28%29%7Bt%3Ddocument.title%2Ct%3Dt%3F%27%22%27%2Bt%2B%27%22%5Cn%5Cn%27%3A%22%22%2Cwindow.open%28%60https%3A%2F%2Fwww.facebook.com%2Fsharer.php%3Fsrc%3Dbm%26v%3D4%26i%3D1628766166%26u%3D%24%7Bdocument.location.href%7D%26t%3D%24%7BencodeURIComponent%28t%29%7D%60%2C%22Share%20on%20Facebook%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29">Share on Facebook</a>]**

### Reddit

Beautified:

```javascript
(function() {
    window.open(
        `https://old.reddit.com/submit?url=${encodeURIComponent(document.location.href)}`,
        "Share on Reddit",
        "scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no, width=800,height=600,left=0,top=0"
    )
})();
```

Minified:

```javascript
(function(){window.open(`https://old.reddit.com/submit?url=${encodeURIComponent(document.location.href)}`,"Share on Reddit","scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no, width=800,height=600,left=0,top=0")})();
```

Encoded:

```javascript
javascript:%28function%28%29%7Bwindow.open%28%60https%3A%2F%2Fold.reddit.com%2Fsubmit%3Furl%3D%24%7BencodeURIComponent%28document.location.href%29%7D%60%2C%22Share%20on%20Reddit%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2C%20width%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29%3B
```

Drag and drop bookmarklet:<br>
**[<a href="javascript:%28function%28%29%7Bwindow.open%28%60https%3A%2F%2Fold.reddit.com%2Fsubmit%3Furl%3D%24%7BencodeURIComponent%28document.location.href%29%7D%60%2C%22Share%20on%20Reddit%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2C%20width%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29%3B">Share on Reddit</a>]**

### LinkedIn

Beautified:

```javascript
(function() {
    window.open(
        `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(document.location.href)}`,
        "Share on LinkedIn",
        "scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no, width=800,height=600,left=0,top=0"
    )
})();
```

Minified:

```javascript
(function(){window.open(`https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(document.location.href)}`,"Share on LinkedIn","scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no, width=800,height=600,left=0,top=0")})();
```

Encoded:

```
javascript:%28function%28%29%7Bwindow.open%28%60https%3A%2F%2Fwww.linkedin.com%2Fsharing%2Fshare-offsite%2F%3Furl%3D%24%7BencodeURIComponent%28document.location.href%29%7D%60%2C%22Share%20on%20LinkedIn%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2C%20width%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29%3B
```

Drag and drop bookmarklet:<br>
**[<a href="javascript:%28function%28%29%7Bwindow.open%28%60https%3A%2F%2Fwww.linkedin.com%2Fsharing%2Fshare-offsite%2F%3Furl%3D%24%7BencodeURIComponent%28document.location.href%29%7D%60%2C%22Share%20on%20LinkedIn%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2C%20width%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29%3B">Share on LinkedIn</a>]**

### Bluesky

Beautified:

```javascript
(function() {
    t = document.title;
    t = t ? '"' + t + '"' + "\n\n" : "";
    window.open(
        `https://bsky.app/intent/compose?text=${encodeURIComponent(t)}${document.location.href}`,
        "Share on Bluesky",
        "scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0"
    )
})()
```

Minified:

```javascript
(function () {t=document.title,t=t?'"'+t+'"\n\n':"",window.open(`https://bsky.app/intent/compose?text=${encodeURIComponent(t)}${document.location.href}`,"Share on Bluesky","scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0")})()
```

Encoded:

```javascript
javascript:%28function%20%28%29%20%7Bt%3Ddocument.title%2Ct%3Dt%3F%27%22%27%2Bt%2B%27%22%5Cn%5Cn%27%3A%22%22%2Cwindow.open%28%60https%3A%2F%2Fbsky.app%2Fintent%2Fcompose%3Ftext%3D%24%7BencodeURIComponent%28t%29%7D%24%7Bdocument.location.href%7D%60%2C%22Share%20on%20Bluesky%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29
```

Drag and drop bookmarklet:<br>
**[<a href="javascript:%28function%20%28%29%20%7Bt%3Ddocument.title%2Ct%3Dt%3F%27%22%27%2Bt%2B%27%22%5Cn%5Cn%27%3A%22%22%2Cwindow.open%28%60https%3A%2F%2Fbsky.app%2Fintent%2Fcompose%3Ftext%3D%24%7BencodeURIComponent%28t%29%7D%24%7Bdocument.location.href%7D%60%2C%22Share%20on%20Bluesky%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29">Share on Bluesky</a>]**

## Subscribing

### NewsBlur

Beautified:

```javascript
(function() {
    window.open(
        `https://www.newsblur.com/?url=${encodeURIComponent(document.location.href)}`,
        "Subscribe (NewsBlur)",
        "scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no, width=800,height=600,left=0,top=0"
    )
})();
```

Minified:

```javascript
(function(){window.open(`https://www.newsblur.com/?url=${encodeURIComponent(document.location.href)}`,"Subscribe (NewsBlur)","scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no, width=800,height=600,left=0,top=0")})();
```

Encoded:

```
javascript:%28function%28%29%7Bwindow.open%28%60https%3A%2F%2Fwww.newsblur.com%2F%3Furl%3D%24%7BencodeURIComponent%28document.location.href%29%7D%60%2C%22Subscribe%20%28NewsBlur%29%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2C%20width%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29%3B
```

Drag and drop bookmarklet:<br>
**[<a href="javascript:%28function%28%29%7Bwindow.open%28%60https%3A%2F%2Fwww.newsblur.com%2F%3Furl%3D%24%7BencodeURIComponent%28document.location.href%29%7D%60%2C%22Subscribe%20%28NewsBlur%29%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2C%20width%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29%3B">Subscribe (NewsBlur)</a>]**

### FreshRSS

I am complicating this sample a little, because I'm using an [RSS-Bridge](https://github.com/rss-bridge/rss-bridge) for following interesting accounts on Twitter.

In the sample below, replace:

- `my.freshrss.host`
- `my.rssbridge.host`

Beautified:

```javascript
(function() {
    var u = document.location.href,
    p = u.match(/twitter.com\/(\w+)/),
    u2 = p && p[1] ? `https://my.rssbridge.host/?action=display&bridge=TwitterV2Bridge&context=By+username&u=${p[1]}&filter=&norep=on&maxresults=&idastitle=on&format=Atom` : u;

    window.open(
        `https://my.freshrss.host/i/?c=feed&a=add&url_rss=${encodeURIComponent(u2)}`,
        "Subscribe (FreshRSS)",
        "scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no, width=800,height=600,left=0,top=0"
    )
})()
```

Minified:

```javascript
(function () {var u=document.location.href,p=u.match(/twitter.com\/(\w+)/),u2=p&&p[1]?`https://my.rssbridge.host/?action=display&bridge=TwitterV2Bridge&context=By+username&u=${p[1]}&filter=&norep=on&maxresults=&idastitle=on&format=Atom`:u;window.open(`https://my.freshrss.host/i/?c=feed&a=add&url_rss=${encodeURIComponent(u2)}`,"Subscribe (FreshRSS)","scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no, width=800,height=600,left=0,top=0")})()
```

Encoding and assembly of the final bookmarklet is left as an exercise for the reader.
