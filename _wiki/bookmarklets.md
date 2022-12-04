---
date: 2022-12-04 12:01:00 +02:00
last_modified_at: 2022-12-04 12:57:41 +02:00
---

# Bookmarklets

## Sharing

### Twitter

Beautified:

```javascript
(function() {
    n = getSelection().anchorNode;
    t = n ? (n.nodeType === 3 ? n.data : n.innerText) : document.title;
    t = t ? '"' + t + '"' + "\n\n" : "";
    window.open(
        `https://twitter.com/intent/tweet?text=${encodeURIComponent(t)}${document.location.href}`, 
        "Share on Twitter", 
        "scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0"
    )
})()
```

Minified:

```javascript
(function(){n=getSelection().anchorNode;  t=n?(n.nodeType===3?n.data:n.innerText):document.title;t = t ? '"' + t + '"' + "\n\n" : "";window.open(`https://twitter.com/intent/tweet?text=${encodeURIComponent(t)}${document.location.href}`,"Share on Twitter","scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0")})()
```

Encoded:

```
javascript:%28function%28%29%7Bn%3DgetSelection%28%29.anchorNode%3B%20%20t%3Dn%3F%28n.nodeType%3D%3D%3D3%3Fn.data%3An.innerText%29%3Adocument.title%3Bt%20%3D%20t%20%3F%20%27%22%27%20%2B%20t%20%2B%20%27%22%27%20%2B%20%22%5Cn%5Cn%22%20%3A%20%22%22%3Bwindow.open%28%60https%3A%2F%2Ftwitter.com%2Fintent%2Ftweet%3Ftext%3D%24%7BencodeURIComponent%28t%29%7D%24%7Bdocument.location.href%7D%60%2C%22Share%20on%20Twitter%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29%0A
```

Drag and drop bookmarklet:<br>
**[<a href="javascript:%28function%28%29%7Bn%3DgetSelection%28%29.anchorNode%3B%20%20t%3Dn%3F%28n.nodeType%3D%3D%3D3%3Fn.data%3An.innerText%29%3Adocument.title%3Bt%20%3D%20t%20%3F%20%27%22%27%20%2B%20t%20%2B%20%27%22%27%20%2B%20%22%5Cn%5Cn%22%20%3A%20%22%22%3Bwindow.open%28%60https%3A%2F%2Ftwitter.com%2Fintent%2Ftweet%3Ftext%3D%24%7BencodeURIComponent%28t%29%7D%24%7Bdocument.location.href%7D%60%2C%22Share%20on%20Twitter%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29%0A">Share on Twitter</a>]**

### Mastodon.social

Beautified:

```javascript
(function() {
    n = getSelection().anchorNode;
    t = n ? (n.nodeType === 3 ? n.data : n.innerText) : document.title;
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
(function(){n=getSelection().anchorNode;  t=n?(n.nodeType===3?n.data:n.innerText):document.title;t = t ? '"' + t + '"' + "\n\n" : "";window.open(`https://mastodon.social/share?text=${encodeURIComponent(t)}${document.location.href}`,"Share on Mastodon","scrollbars=no,resizable=no,status=no,location=no,toolbar=no,menubar=no,width=800,height=600,left=0,top=0")})()
```

Encoded:

```
javascript:%28function%28%29%7Bn%3DgetSelection%28%29.anchorNode%3B%20%20t%3Dn%3F%28n.nodeType%3D%3D%3D3%3Fn.data%3An.innerText%29%3Adocument.title%3Bt%20%3D%20t%20%3F%20%27%22%27%20%2B%20t%20%2B%20%27%22%27%20%2B%20%22%5Cn%5Cn%22%20%3A%20%22%22%3Bwindow.open%28%60https%3A%2F%2Fmastodon.social%2Fshare%3Ftext%3D%24%7BencodeURIComponent%28t%29%7D%24%7Bdocument.location.href%7D%60%2C%22Share%20on%20Mastodon%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29
```

Drag and drop bookmarklet:<br>
**[<a href="javascript:%28function%28%29%7Bn%3DgetSelection%28%29.anchorNode%3B%20%20t%3Dn%3F%28n.nodeType%3D%3D%3D3%3Fn.data%3An.innerText%29%3Adocument.title%3Bt%20%3D%20t%20%3F%20%27%22%27%20%2B%20t%20%2B%20%27%22%27%20%2B%20%22%5Cn%5Cn%22%20%3A%20%22%22%3Bwindow.open%28%60https%3A%2F%2Fmastodon.social%2Fshare%3Ftext%3D%24%7BencodeURIComponent%28t%29%7D%24%7Bdocument.location.href%7D%60%2C%22Share%20on%20Mastodon%22%2C%22scrollbars%3Dno%2Cresizable%3Dno%2Cstatus%3Dno%2Clocation%3Dno%2Ctoolbar%3Dno%2Cmenubar%3Dno%2Cwidth%3D800%2Cheight%3D600%2Cleft%3D0%2Ctop%3D0%22%29%7D%29%28%29">Share on Mastodon</a>]**

### Facebook

Beautified:

```javascript
var d = document,
    f = 'https://www.facebook.com/share',
    l = d.location,
    e = encodeURIComponent,
    p = '.php?src=bm&v=4&i=1628766166&u=' + e(l.href) + '&t=' + e(d.title);
1;
try {
    if (!/^(.*\.)?facebook\.[^.]*$/.test(l.host)) throw (0);
    share_internal_bookmarklet(p)
} catch (z) {
    a = function() {
        if (!window.open(f + 'r' + p, 'sharer', 'toolbar=0,status=0,resizable=1,width=626,height=436')) l.href = f + p
    };
    if (/Firefox/.test(navigator.userAgent)) setTimeout(a, 0);
    else {
        a()
    }
}
void(0)
```

Minified:

```javascript
var d=document,f="https://www.facebook.com/share",l=d.location,e=encodeURIComponent,p=".php?src=bm&v=4&i=1628766166&u="+e(l.href)+"&t="+e(d.title);try{if(!/^(.*\.)?facebook\.[^.]*$/.test(l.host))throw 0;share_internal_bookmarklet(p)}catch(e){a=function(){window.open(f+"r"+p,"sharer","toolbar=0,status=0,resizable=1,width=626,height=436")||(l.href=f+p)},/Firefox/.test(navigator.userAgent)?setTimeout(a,0):a()}
```

Encoded:

```
javascript:var%20d%3Ddocument%2Cf%3D%22https%3A%2F%2Fwww.facebook.com%2Fshare%22%2Cl%3Dd.location%2Ce%3DencodeURIComponent%2Cp%3D%22.php%3Fsrc%3Dbm%26v%3D4%26i%3D1628766166%26u%3D%22%2Be%28l.href%29%2B%22%26t%3D%22%2Be%28d.title%29%3Btry%7Bif%28%21%2F%5E%28.%2A%5C.%29%3Ffacebook%5C.%5B%5E.%5D%2A%24%2F.test%28l.host%29%29throw%200%3Bshare_internal_bookmarklet%28p%29%7Dcatch%28e%29%7Ba%3Dfunction%28%29%7Bwindow.open%28f%2B%22r%22%2Bp%2C%22sharer%22%2C%22toolbar%3D0%2Cstatus%3D0%2Cresizable%3D1%2Cwidth%3D626%2Cheight%3D436%22%29%7C%7C%28l.href%3Df%2Bp%29%7D%2C%2FFirefox%2F.test%28navigator.userAgent%29%3FsetTimeout%28a%2C0%29%3Aa%28%29%7D%0A
```

Drag and drop bookmarklet:<br>
**[<a href="javascript:var%20d%3Ddocument%2Cf%3D%22https%3A%2F%2Fwww.facebook.com%2Fshare%22%2Cl%3Dd.location%2Ce%3DencodeURIComponent%2Cp%3D%22.php%3Fsrc%3Dbm%26v%3D4%26i%3D1628766166%26u%3D%22%2Be%28l.href%29%2B%22%26t%3D%22%2Be%28d.title%29%3Btry%7Bif%28%21%2F%5E%28.%2A%5C.%29%3Ffacebook%5C.%5B%5E.%5D%2A%24%2F.test%28l.host%29%29throw%200%3Bshare_internal_bookmarklet%28p%29%7Dcatch%28e%29%7Ba%3Dfunction%28%29%7Bwindow.open%28f%2B%22r%22%2Bp%2C%22sharer%22%2C%22toolbar%3D0%2Cstatus%3D0%2Cresizable%3D1%2Cwidth%3D626%2Cheight%3D436%22%29%7C%7C%28l.href%3Df%2Bp%29%7D%2C%2FFirefox%2F.test%28navigator.userAgent%29%3FsetTimeout%28a%2C0%29%3Aa%28%29%7D%0A">Share on Facebook</a>]**

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
