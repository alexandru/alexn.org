(function () {
  function getDomainName(h) {
    var hostname = h ? h : window.location.hostname;
    return hostname.substring(hostname.lastIndexOf(".", hostname.lastIndexOf(".") - 1) + 1);
  }
  
  function delete_cookie(name) {    
    document.cookie = name+'=; Domain=.' + getDomainName() + '; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT;';
  }

  function delete_all_cookies() {
    var search = /(\w+)[=]/g;
    var cookie = document.cookie;
    
    while (match = search.exec(cookie)) {
      try {
        if (console && console.log)
          console.log("[Privacy scanner] deleting cookie: " + match[1]);
      } catch (e) {}
      
      delete_cookie(match[1]);
    }
  }

  function loop() {
    delete_all_cookies();
    // Execute once per second
    setTimeout(loop, 1000);
  }
  
  loop();
})();
