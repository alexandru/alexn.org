---
layout: null
---

(function () {
	function onDocumentReady() {
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
