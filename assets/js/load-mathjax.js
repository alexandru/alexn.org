---
layout: null
---

(function () {
  function triggerOnce(document, f) {
    var wasLoaded = false;
    return function () {
      var shouldLoad = !wasLoaded && (
        typeof document.readyState === "undefined" ||
        document.readyState === "complete"
      );
      if (shouldLoad) {
        wasLoaded = true;
        f();
      }
    };
  }

  function loadScript() {
    console.log("Loading MathJax")

    function scriptCData(x) {
      if (x.startsWith('% <![CDATA[') && x.endsWith('%]]>')) {
        return x.substring(11,x.length-4);
      }
      return x;
    }

    document.querySelectorAll("script[type='math/tex']").forEach(function (el) {
      el.outerHTML = "<div class='formula-code'><script type='math/text'>" + scriptCData(el.textContent) + "</script></div>";
    });

    document.querySelectorAll("script[type='math/tex; mode=display']").forEach(function(el){
      el.outerHTML = "<div class='formula-code'><script type='math/tex; mode=display'>" + scriptCData(el.textContent) + "</script></div>";
    });

    var script = document.createElement('script');
    script.src = "{% link /assets/js-managed/mathjax/MathJax.js %}?config=TeX-AMS-MML_HTMLorMML";
    script.async = true;
    document.head.appendChild(script);
  }

  if (document.readyState === "complete") {
    loadScript();
  } else {
    var loader = triggerOnce(document, loadScript);
    document.addEventListener('DOMContentLoaded', loader, false);
    document.onreadystatechange = loader;
  }
})();
