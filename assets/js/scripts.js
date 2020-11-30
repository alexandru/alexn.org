---
layout: null
---

(function () {
	function warnAboutDarkReader() {
		var isDarkReaderEnabled =
			"matchMedia" in window && 
			window.matchMedia('(prefers-color-scheme: dark)').matches &&
			"querySelector" in document &&
			!!document.querySelector("meta[name=darkreader]") &&
			!document.cookie.match(/accept_dark_reader/);

		if (isDarkReaderEnabled) {
			document.cookie = "accept_dark_reader=1;path=/;max-age=604800";
			alert(
				"You have the Dark Reader extension enabled.\n\n" + 
				"This website already supports a dark theme 🚀✨\n\n" + 
				"Please disable Dark Reader for this website,\nas it interferes with its design 🙏"
			);
		}
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

	function onDocumentReady() {
		console.log("Initializing page");
		initDropCapParagraphs();
		// Activate responsive navigation
		responsiveNav(".nav-collapse");

		// Round Reading Time
		$(".time").text(function (_index, value) {
			return Math.round(parseFloat(value));
		});

		warnAboutDarkReader();
	}

	if (document.readyState === "complete") {
		onDocumentReady();
	} else {
		window.onload = onDocumentReady;
	}
})();
