(function () {
  function delete_cookie(name) {   
    document.cookie = name+'=; Max-Age=-99999999;';  
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
