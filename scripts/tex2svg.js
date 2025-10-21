#!/usr/bin/env node

const {mathjax} = require('mathjax-full/js/mathjax');
const {TeX} = require('mathjax-full/js/input/tex');
const {SVG} = require('mathjax-full/js/output/svg');
const {liteAdaptor} = require('mathjax-full/js/adaptors/liteAdaptor');
const {RegisterHTMLHandler} = require('mathjax-full/js/handlers/html');
const {AllPackages} = require('mathjax-full/js/input/tex/AllPackages');
const fs = require("fs");
const crypto = require("crypto");
const path = require("path");

// Setup MathJax
const adaptor = liteAdaptor();
RegisterHTMLHandler(adaptor);

const tex = new TeX({packages: AllPackages});
const svg = new SVG({fontCache: 'none'});
const html = mathjax.document('', {InputJax: tex, OutputJax: svg});

/**
 * Generate hash from formula
 */
function hashFormula(formula) {
  return crypto.createHash("md5").update(formula).digest("hex");
}

/**
 * Convert TeX formula to SVG
 */
async function tex2svg(formula, inline = false) {
  try {
    // Convert formula to MathJax node
    const node = html.convert(formula, {display: !inline});
    
    // Extract the SVG element from the container
    const svgElement = adaptor.firstChild(node);
    let svgString = adaptor.outerHTML(svgElement);
    
    // Add title element for accessibility, escaping all XML special characters
    function escapeXml(str) {
      // Remove newlines, carriage returns, and tabs
      str = str.replace(/[\n\r\t]+/g, ' ');
      // Escape XML special characters
      return str.replace(/[&<>'"]/g, function (c) {
        switch (c) {
          case '&': return '&amp;';
          case '<': return '&lt;';
          case '>': return '&gt;';
          case '"': return '&quot;';
          case "'": return '&apos;';
        }
      });
    }
    svgString = svgString.replace(
      /<svg([^>]*)>/,
      `<svg$1><title>${escapeXml(formula)}</title>`
    );
    
    return svgString;
  } catch (error) {
    throw new Error(`Failed to render formula: ${error.message}`);
  }
}

/**
 * Process a formula and save to file
 */
async function processFormula(formula, outputDir, inline = false) {
  const hash = hashFormula(formula);
  const filename = `${hash}.svg`;
  const filepath = path.join(outputDir, filename);
  
  // Check if file already exists
  if (fs.existsSync(filepath)) {
    return filename;
  }
  
  // Generate SVG
  let svg;
  try {
    svg = await tex2svg(formula, inline);
  } catch (err) {
    throw new Error(`SVG generation failed: ${err.message}`);
  }

  // Ensure output directory exists
  try {
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }
  } catch (err) {
    throw new Error(`Failed to create output directory: ${err.message}`);
  }

  // Save to file
  try {
    fs.writeFileSync(filepath, svg);
  } catch (err) {
    throw new Error(`Failed to write SVG file: ${err.message}`);
  }

  return filename;
}

// Main execution
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.length < 2) {
    console.log("Usage: tex2svg.js <formula> <output_dir> [--inline]");
    process.exit(1);
  }
  
  const formula = args[0];
  const outputDir = args[1];
  const inline = args.includes("--inline");
  
  processFormula(formula, outputDir, inline)
    .then((filename) => {
      console.log(filename);
      process.exit(0);
    })
    .catch((err) => {
      console.error("Error:", err.message);
      process.exit(1);
    });
}

module.exports = { tex2svg, processFormula, hashFormula };
