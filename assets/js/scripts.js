---
layout: null
---

(function () {
	/**
	 * Source: {@link https://www.w3schools.com/js/js_cookies.asp}
	 */
	function getCookie(cname) {
		var name = cname + "=";
		var decodedCookie = decodeURIComponent(document.cookie);
		var ca = decodedCookie.split(';');
		for(var i = 0; i <ca.length; i++) {
			var c = ca[i];
			while (c.charAt(0) == ' ') {
				c = c.substring(1);
			}
			if (c.indexOf(name) == 0) {
				return c.substring(name.length, c.length);
			}
		}
		return undefined;
	}

	function resetAllCookies() {
		var decodedCookie = decodeURIComponent(document.cookie);
		var ca = decodedCookie.split(/\s*;\s*/);
		for(var i = 0; i <ca.length; i++) {
			var name = ca[i].trim().split(/=/)[0];
			if (name && name !== "cookieconsent_status") {
				console.log("Deleting cookie: " + name);
				document.cookie = name + "=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
			}
		}
	}
	
	/** 
	 * Utility for loading scripts dynamically.
	 */
	function loadScript(src, onLoad) {
		var script = document.createElement('script');
		script.async = true;
		script.onload = onLoad;
		script.src = src;
		document.body.appendChild(script);
	}

	/**
	 * Cookie consent banner.
	 * 
	 * Resources:
	 * - {@link https://www.osano.com/cookieconsent}
	 * - {@link https://github.com/osano/cookieconsent}
	 */
	function loadCookieConsent() {
		var loaded = [false];

		function loadCookieDroppingScripts() {
			if (!loaded[0]) {
				console.log("Loading cookie-dropping scripts")
				loaded[0] = true;
				initGA();
				initMailChimp();	
			}
		}

		var currentStatus = getCookie("cookieconsent_status");
		if (currentStatus === "allow") {
			loadCookieDroppingScripts();
		} else if (currentStatus === "deny") {
			console.log("Cookies are disabled! (1)")
			resetAllCookies();
		}

		loadScript("{% link /assets/js-managed/cookieconsent/build/cookieconsent.min.js %}", function () {
			window.cookieconsent.initialise({
				"palette": {
					"popup": {
						"background": "#00639d"
					},
					"button": {
						"background": "#fff",
						"text": "#00639d"
					}
				},
				"type": "opt-in",
				"content": {
					"message": "This website uses cookies to ensure you get the best experience.",
					"href": "{% link docs/privacy-policy.md %}#cookies",
				},
				onStatusChange: function (status) {
					try {
						if (!this.hasConsented()) {
							console.log("Cookies are disabled! (2)");
							resetAllCookies();

							if (currentStatus === "allow") {
								console.log("Reloading page ...");
								location.reload();
							}
							return
						}

						console.log("Cookies enabled!");
						loadCookieDroppingScripts();	
					} finally {
						currentStatus = status;
					}
				}
			});		
		});
	}

	/**
	 * Adds the "dropcap" class automatically.
	 */
	function initDropCapParagraphs() {
		var elem = $("p.intro.withcap:first").contents().filter(function () { return this.nodeType == 3 }).first();
		var text = elem.text().replace(/^[\s\r\n]+/, "");
		var first = text.slice(0, 1);

		if (!elem.length) return;

		elem[0].nodeValue = text.slice(first.length);
		elem.before('<span class="dropcap">' + first + '</span>');

		// DropCap.js
		var dropcaps = document.querySelectorAll(".dropcap");
		window.Dropcap.layout(dropcaps, 2);		
	}

	function initMailChimp() {
		console.log("Initializing MailChimp")
		// Code copied verbatim
		!function(c,h,i,m,p){m=c.createElement(h),p=c.getElementsByTagName(h)[0],m.async=1,m.src=i,p.parentNode.insertBefore(m,p)}(document,"script","https://chimpstatic.com/mcjs-connected/js/users/5bffa2af025192a58345bd5dc/de267627a98b58f0427968f31.js");
	}

	function initGA() {
		{% if site.google_analytics %}
		function _gaLoad() {
			(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
				(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
				m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
				})(window,document,'script','//www.google-analytics.com/analytics.js','ga');
		
			ga('create', '{{ site.google_analytics }}', {
				'cookieName': '_gaAlexNOrg',
				'cookieExpires': 60 * 60 * 24 * 30 * 3  // 3 months, in seconds
			});
			ga('set', 'anonymizeIp', true);
			ga('send', 'pageview');
		
			// Click handler
			$(function () {
				$('a[href]').each(function (idx, elem) {
					var it = $(elem);
					var href = it.attr('href');
		
					if (href.match(/^https?[:]\/\//) && !href.match(/alexn\.org/)) {
						it.click(_gaEvent('general', 'click', 'external-link', href));
					} else if (href.match(/^#/)) {
						it.click(_gaEvent('general', 'click', 'page-anchor', href));
					} else {
						it.click(_gaEvent('general', 'click', 'internal-link', href));
					}
				})
			});
		}
		
		function _gaEvent(category, action, label, value) {
			return function () {
				if (_doNotTrack || typeof ga !== 'function') {
					return;
				}
				ga(function () {
					ga('send', 'event', category, action, label, value);
				});
			}
		}
		
		_gaLoad();
		/*
		window._doNotTrack = false;
		if (window.doNotTrack || navigator.doNotTrack || navigator.msDoNotTrack || 'msTrackingProtectionEnabled' in window.external) {
			window._doNotTrack = window.doNotTrack == "1" || navigator.doNotTrack == "yes" ||
				navigator.doNotTrack == "1" || navigator.msDoNotTrack == "1" ||
				('msTrackingProtectionEnabled' in window.external && window.external.msTrackingProtectionEnabled());
		}
		if (!_doNotTrack) {
			console.log("Analytics are loading.")
			_gaLoad();
		} else if (typeof(console) !== "undefined") {
			console.log("Analytics are off due to Do Not Track setting!");
		}*/
		{% endif %}
	}

	function onDocumentReady() {
		console.log("Initializing page");
		initDropCapParagraphs();
		loadCookieConsent();

		// Activate responsive navigation
		responsiveNav(".nav-collapse");

		// Round Reading Time
		$(".time").text(function (_index, value) {
			return Math.round(parseFloat(value));
		});
	}

	if (document.readyState === "complete") {
		onDocumentReady();
	} else {
		window.onload = onDocumentReady;
	}
})();
