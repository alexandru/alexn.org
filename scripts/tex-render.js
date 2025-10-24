#!/usr/bin/env node

const katex = require('katex');
const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

/**
 * Generate hash from formula
 */
function hashFormula(formula) {
  return crypto.createHash('md5').update(formula.trim()).digest('hex');
}

/**
 * Display usage information
 */
function usage() {
  console.log('Usage: tex-render.js <formula> <output_dir> [--inline]');
}

/**
 * Main processing function
 */
async function main() {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    usage();
    process.exit(1);
  }

  const formula = args[0];
  const outputDir = args[1];
  const inline = args.includes('--inline');

  const hash = hashFormula(formula);
  const filename = `${hash}.mml`;
  const filepath = path.join(outputDir, filename);

  try {
    // Create output directory if it doesn't exist
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // If file already exists, print path and exit
    if (fs.existsSync(filepath)) {
      console.log(filepath);
      process.exit(0);
    }

    // Render using KaTeX to MathML
    const options = {
      displayMode: !inline,
      throwOnError: false,
      strict: false,
      output: 'htmlAndMathml'
    };

    const rendered = katex.renderToString(formula, options);

    // Extract the MathML part
    const mathmlMatch = rendered.match(/<math[\s\S]*?<\/math>/);
    let mathmlContent = mathmlMatch ? mathmlMatch[0] : rendered;

    // Write to file
    fs.writeFileSync(filepath, mathmlContent, 'utf8');

    // Print the created path
    console.log(filepath);
    process.exit(0);
  } catch (err) {
    console.error('Failed to generate MathML:', err && err.message ? err.message : err);
    process.exit(1);
  }
}

// Execute main function
main();

module.exports = { 
  // Exported for testing or external use if needed
  hashFormula,
};
