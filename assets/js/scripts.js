(function () {
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
		initDropCapParagraphs();
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
