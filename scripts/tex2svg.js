#!/usr/bin/env node

const { mathjax } = require('mathjax-full/js/mathjax');
const { TeX } = require('mathjax-full/js/input/tex');
const { SerializedMmlVisitor } = require('mathjax-full/js/core/MmlTree/SerializedMmlVisitor');
const { liteAdaptor } = require('mathjax-full/js/adaptors/liteAdaptor');
const { RegisterHTMLHandler } = require('mathjax-full/js/handlers/html');
const { AllPackages } = require('mathjax-full/js/input/tex/AllPackages');
const fs = require("fs");
const crypto = require("crypto");
const path = require("path");

// Setup MathJax
const adaptor = liteAdaptor();
RegisterHTMLHandler(adaptor);

// Filter out packages that require an output jax
const packages = AllPackages.filter(pkg => pkg !== 'bussproofs');
const tex = new TeX({ packages });
const html = mathjax.document('', { InputJax: tex });

/**
 * Generate hash from formula
 */
function hashFormula(formula) {
  return crypto.createHash("md5").update(formula).digest("hex");
}

/**
 * Convert TeX formula to MathML
 */
async function tex2mathml(formula, inline = false) {
  try {
    // Convert formula to internal MathML tree
    const mathmlNode = html.convert(formula, { display: !inline });

    // Create a visitor to serialize the MathML tree
    const visitor = new SerializedMmlVisitor(tex.mmlFactory);
    const mathmlString = visitor.visitTree(mathmlNode);

    return mathmlString;
  } catch (error) {
    throw new Error(`Failed to render formula: ${error.message}`);
  }
}

/**
 * Process a formula and save to file
 */
async function processFormula(formula, outputDir, inline = false) {
  const hash = hashFormula(formula);
  const filename = `${hash}.mathml`;
  
  const filepath = path.join(outputDir, filename);

  // Create directory if it doesn't exist
  try {
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }
  } catch (err) {
    throw new Error(`Failed to create directory ${outputDir}: ${err.message}`);
  }
  
  // Skip generation if file exists
  if (fs.existsSync(filepath)) {
    return filename;
  }
  
  // Generate MathML
  try {
    const mathmlContent = await tex2mathml(formula, inline);
    fs.writeFileSync(filepath, mathmlContent);
  } catch (err) {
    throw new Error(`Failed to generate MathML file: ${err.message}`);
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

  // Process formula to generate MathML
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

module.exports = { 
  tex2mathml, 
  processFormula, 
  hashFormula
};
