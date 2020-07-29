---
title: "Cross-Domain, Cross-Browser AJAX Requests"
date:   2011-03-24
last_modified_at: 2019-12-14
tags:
  - JavaScript
  - Browser
  - Web
image: /assets/media/articles/cors-ajax.png
description: >-
  This article describes how to make cross-browser requests, in all browsers (including IExplorer 6), using web standards along with fallbacks and without using a proxy or JSONP (which is limited and awkward) -- as long as you control the destination server, or if the destination server allows.
---

- [Updates](#updates)
  - [Oct 27, 2011](#oct-27-2011)
- [In Modern Browsers - Meet Cross-Origin Resource Sharing](#in-modern-browsers---meet-cross-origin-resource-sharing)
- [Response of _destination.org_](#response-of-destinationorg)
- [Client-side Implementation of Ajax Request for CORS](#client-side-implementation-of-ajax-request-for-cors)
- [Fallback for Older Browsers](#fallback-for-older-browsers)
  - [Why bother with CORS?](#why-bother-with-cors)
  - [flXHR Usage](#flxhr-usage)
- [Not Loading the Junk when Not Needed](#not-loading-the-junk-when-not-needed)
- [Almost there](#almost-there)

<p class="intro withcap">
  This article describes how to make cross-browser requests, in all browsers (including <u>IExplorer 6</u>), using web standards along with fallbacks and without using a proxy or JSONP (which is limited and awkward) -- as long as you control the destination server, or if the destination server allows.
</p>

I'm explaining this file: [crossdomain-ajax.js](https://github.com/alexandru/crossdomain-requests-js/blob/gh-pages/public/crossdomain-ajax.js)

## Updates

### Oct 27, 2011

Added restrictions of usage and removed functionality that doesn't work on IExplorer. So in case this doesn't work for you, please see this page: [Troubleshooting](https://github.com/alexandru/crossdomain-requests-js/wiki/Troubleshooting)

## In Modern Browsers - Meet Cross-Origin Resource Sharing

Or [CORS](http://www.w3.org/TR/cors/) for short, or [HTTP Access Control](https://developer.mozilla.org/en/http_access_control), available in recent browsers, allows you to make cross-domain HTTP requests; the only requirement being that you must have control over the server-side implementation of the domain targeted in your XMLHttpRequest calls.

This little piece of technology is available since Firefox 3.5 / IExplorer 8 and yet when searching for answers on websites like StackOverflow, it rarely comes up.

For the purposes of this tutorial, we'll assume we want to make a request from website `http://source.com` to `http://destination.org`, and that you control the implementation to both.

```js
var xhr = new XMLHttpRequest();
// NOPE, it doesn't work, yet
xhr.open("POST", "http://destination.org", true);
```

## Response of _destination.org_

It's pretty simple really, all you need to do is to return these headers in your response:

```yaml
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: http://source.com
Access-Control-Allow-Headers: Content-Type, *
```

You can find a description of them on [Mozilla Doc Center](https://developer.mozilla.org/en/http_access_control#The_HTTP_request_headers), but the most important one is _Access-Control-Allow-Origin_, which indicates the Origin(s) allowed to make such a request.

**Note:** these options allow for wildcards (like you can say that you allow for any Origin by putting a "*" in that header), but it is better to be explicit about what's allowed, otherwise your request won't work very well cross-browser.

**(New) Note:** In regards to Access-Control-Allow-Origin, IExplorer DOES NOT support wildcards. See [Troubleshooting](https://github.com/alexandru/crossdomain-requests-js/wiki/Troubleshooting) for details.

## Client-side Implementation of Ajax Request for CORS

On browsers where <u>XMLHttpRequest</u> is valid, support for CORS can be validated by checking for the availability of the <u>withCredentials</u> property.

So we've got a tiny issue: <u>IExplorer's</u> implementation is different than that of Firefox's or the rest of the browsers (naturally). Instead of using the same <u>XMLHttpRequest</u> object, IExplorer 8 adds an [XDomainRequest](http://msdn.microsoft.com/en-us/library/cc288060(v=vs.85).aspx) object.

So to initialize an async request, that will work on IExplorer 8, Firefox, Chrome and the other browsers supporting it:

```js
try {
    var xhr = new XMLHttpRequest();
} catch(e) {}

if (xhr && "withCredentials" in xhr){
  xhr.open(type, url, true);
} else if (typeof XDomainRequest != "undefined"){
  xhr = new XDomainRequest();
  xhr.open(type, url);
} else {
  xhr = null;
}
```

But we aren't done yet, the callbacks used by these request objects have different behavior on IExplorer. So let's say we've got 2 callbacks that we want to register, one for success, one for errors, having the following signatures (same as jQuery):

```js
function success(responseText, XHRobj) { ... }
function error(XHRobj) { ... }
```

To have correct behavior cross-browser:

```js
//
// combines the success/error handlers into one
// higher-order function (getting a little fancy for code-reuse)
//
var handle_load = function (event_type) {
  return function (XHRobj) {
    //
    // stupid IExplorer won't receive any param on callbacks!!!
    // thus the object used is the initial `xhr` object
    // (bound to this function because it's a closure)
    //
    var XHRobj = is_iexplorer() ? xhr : XHRobj;

    //
    // IExplorer also skips on readyState
    // Also, it's success/error based on the `event_type` used at the call-site
    //
    if (event_type == 'load' && (is_iexplorer() || XHRobj.readyState == 4) && success)
      success(XHRobj.responseText, XHRobj);
    else if (error)
      error(XHRobj);
  }
};

try {
  // IExplorer throws an exception on this one
  //
  // Setting this to `true` is specifying to make the request with Cookies attached.
  // BUT -- it's pretty useless, as IExplorer doesn't support sending Cookies.
  //
  // Also, trying to set cookies from the response is not really possible directly
  // (workarounds are available though -- you can return anything in the response's
  //  body and use local javascript for persistence/propagation on next request)
  //
  xhr.withCredentials = false;
} catch(e) {};

//
// `onload` + `onerror` are actually new additions to these browsers.
//
// IExplorer doesn't actually push params on calling these callbacks.
// For every other browser, the XHRobj we want is in `e.target`,
// where `e` is an event object.
//
xhr.onload  = function (e) {
  handle_load('load')(is_iexplorer() ? e : e.target)
};
xhr.onerror = function (e) {
  handle_load('error')(is_iexplorer() ? e : e.target)
};
xhr.send(data);
```

Also of notice, here's how to check if the browser is IExplorer:

```js
function is_iexplorer() {
  return navigator.userAgent.indexOf('MSIE') !=-1
}
```

Well, that's it, unless you want to support the rest of desktop browsers in use.

## Fallback for Older Browsers

<u>Opera 10</u> doesn't have this feature, neither do IExplorer < 8, Firefox < 3.5 -- and I don't really know when Chrome/Safari added it. Fortunately there's a workaround -- Flash can do whatever you want and runs the same on ~90% of desktop browsers out there, AND it can interact with Javascript.

Not to reinvent the wheel, here's a cool plugin: [flensed.flXHR](http://flxhr.flensed.com/).

### Why bother with CORS?

*   Flash is not available on the iPhone
*   Flash loads slower than Javascript
*   Flash SWF files come with a lot of junk that your browser has to download
*   The whole experience using flXHR will be visibly slower than with CORS

### flXHR Usage

```js
//
// Does a request using flXHR (the JS-Flash alternative
// implementation for XMLHttpRequest)
//
function _ajax_with_flxhr(options) {
  var url = options['url'];
  var type = options['type'] || 'GET';
  var success = options['success'];
  var error = options['error'];
  var data = options['data'];

  //
  // handles callbacks, just as above
  //
  function handle_load(XHRobj) {
    if (XHRobj.readyState == 4) {
      if (XHRobj.status == 200 && success)
        success(XHRobj.responseText, XHRobj);
      else
        error(XHRobj);
    }
  }

  var flproxy = new flensed.flXHR({
    autoUpdatePlayer: false,
    instanceId: "myproxy1",
    xmlResponseText: false,
    onreadystatechange: handle_load
  });

  flproxy.open(type, url, true);
  flproxy.send(data);
}
```

We are NOT done. The destination server also needs a file called <u>crossdomain.xml</u>, which represents a [Crossdomain Policy File Spec](http://www.adobe.com/devnet/articles/crossdomain_policy_file_spec.html). As a requirement, this file has to be placed in the domain's root, i.e. <u>http://destination.org/crossdomain.xml</u> ...

```xml
<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
  <!-- wildcard means 'allow all' -->
  <allow-access-from domain="*" />
  <allow-http-request-headers-from domain="*" headers="*" />
</cross-domain-policy>
```

## Not Loading the Junk when Not Needed

Javascript is <u>asynchronous</u> and we should take advantage of that by not loading <u>flensed.flXHR</u>, unless needed and at the last moment too (no need to load it until we want to make a request).

We need a method for asynchronously loading a Javascript file and executing a callback onload. And since we may be executing this function multiple times at once, we need to take care of race-conditions. First things first:

```js
// keeps count of files already included
var FILES_INCLUDED = {};

// keeps count of files in the processes of getting loaded
// for avoiding race conditions
var FILES_LOADING = {};

// stacks of registered callbacks, that will get executed once
// a file loads -- this to deal with multiple file inclusions at once,
// and not ignoring anything
var REGISTERED_CALLBACKS = {};

function register_callback(file, callback) {
  if (!REGISTERED_CALLBACKS[file])
    REGISTERED_CALLBACKS[file] = new Array();
  REGISTERED_CALLBACKS[file].push(callback);
}

function execute_callbacks(file) {
  while (REGISTERED_CALLBACKS[file].length > 0) {
    var callback = REGISTERED_CALLBACKS[file].pop();
    if (callback) callback();
  }
}
```

To asynchronously load a Javascript file, with onload callback, behold:

```js
//
// Loads a Javascript file asynchronously, executing a `callback`
// if/when file gets loaded.
//
// Returns `true` if callback got executed immediately, `false` otherwise.
//
function async_load_javascript(file, callback) {
  // stores callback in the stack
  register_callback(file, callback);

  // dealing with race conditions

  if (FILES_INCLUDED[file]) {
    execute_callbacks(file);
    return true;
  }
  if (FILES_LOADING[file])
    return false;

  FILES_LOADING[file] = true;

  // dynamically adds a <script> tag to the document
  var html_doc = document.getElementsByTagName('head')[0];
  js = document.createElement('script');
  js.setAttribute('type', 'text/javascript');
  js.setAttribute('src', file);
  html_doc.appendChild(js);

  // onload, then go through the stack of callbacks,
  // and execute all of them
  js.onreadystatechange = function () {
    if (js.readyState == 'complete' || js.readyState == 'loaded') {
      if (!FILES_INCLUDED[file]) {
        FILES_INCLUDED[file] = true;
        execute_callbacks(file);
      }
    }
  };

  // same as above, same shit for dealing with incompatibilities
  js.onload = function () {
    if (!FILES_INCLUDED[file]) {
      FILES_INCLUDED[file] = true;
      execute_callbacks(file);
    }
  };

  return false;
}
```

## Almost there

To bind it all together we need to plug this into our main logic. So if browser does not support CORS, it fallbacks to this implementation.

```js
// to recapitulate
if (xhr && "withCredentials" in xhr) {
  xhr.open(type, url, true);
} else if (typeof XDomainRequest != "undefined") {
  xhr = new XDomainRequest();
  xhr.open(type, url);
} else {
  xhr = null;
}

// NOT SUPPORTED, then fallback
if (!xhr) {
  async_load_javascript(CROSSDOMAINJS_PATH + "flXHR/flXHR.js", function () {
    _ajax_with_flxhr(options);
  });
}
```

To see the final code, go here: [crossdomain-ajax.js](https://github.com/alexandru/crossdomain-requests-js/blob/gh-pages/public/crossdomain-ajax.js).
