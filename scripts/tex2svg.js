#!/usr/bin/env node

const mjAPI = require("mathjax-node");
const fs = require("fs");
const crypto = require("crypto");
const path = require("path");

mjAPI.config({
  MathJax: {
    tex: {
      packages: ['base', 'ams', 'noerrors', 'noundefined', 'newcommand']
    }
  }
});

mjAPI.start();

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
  return new Promise((resolve, reject) => {
    mjAPI.typeset({
      math: formula,
      format: inline ? "inline-TeX" : "TeX",
      svg: true,
    }, (data) => {
      if (data.errors) {
        reject(new Error(data.errors.join(", ")));
      } else {
        resolve(data.svg);
      }
    });
  });
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
  const svg = await tex2svg(formula, inline);
  
  // Ensure output directory exists
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  
  // Save to file
  fs.writeFileSync(filepath, svg);
  
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
