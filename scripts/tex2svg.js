#!/usr/bin/env node

const { mathjax } = require('mathjax-full/js/mathjax');
const { TeX } = require('mathjax-full/js/input/tex');
const { SVG } = require('mathjax-full/js/output/svg');
const { liteAdaptor } = require('mathjax-full/js/adaptors/liteAdaptor');
const { RegisterHTMLHandler } = require('mathjax-full/js/handlers/html');
const { AllPackages } = require('mathjax-full/js/input/tex/AllPackages');
const fs = require("fs");
const crypto = require("crypto");
const path = require("path");

// Setup MathJax
const adaptor = liteAdaptor();
RegisterHTMLHandler(adaptor);

const tex = new TeX({ packages: AllPackages });
const svg = new SVG({ fontCache: 'none' });
const html = mathjax.document('', { InputJax: tex, OutputJax: svg });

/**
 * Generate hash from formula
 */
function hashFormula(formula) {
  return crypto.createHash("md5").update(formula).digest("hex");
}

/**
 * Convert TeX formula to SVG and return both transparent and white background versions
 */
async function tex2svg(formula, inline = false) {
  try {
    // Convert formula to MathJax node
    const node = html.convert(formula, { display: !inline });

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
    
    // Add title to the SVG
    const svgWithTitle = svgString.replace(
      /<svg([^>]*)>/,
      `<svg$1><title>${escapeXml(formula)}</title>`
    );
    
    // Create transparent version (base version with title)
    const transparentSvg = svgWithTitle;
    
    // Create white background version
    let whiteBgSvg = svgWithTitle;
    whiteBgSvg = whiteBgSvg.replace(
      /<svg([^>]*)>(<title>.*?<\/title>)/,
      (match, attrs, title) => {
        // Extract viewBox to determine size
        const viewBoxMatch = attrs.match(/viewBox="([^"]+)"/);
        if (!viewBoxMatch) return match;
        
        const viewBox = viewBoxMatch[1].split(' ');
        if (viewBox.length !== 4) return match;
        
        const [x, y, width, height] = viewBox;
        return `<svg${attrs}>${title}<rect x="${x}" y="${y}" width="${width}" height="${height}" fill="rgba(255, 255, 255, 0.6)"/>`
      }
    );

    // Return both versions
    return {
      transparent: transparentSvg,
      white: whiteBgSvg
    };
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
  
  // Create paths for both versions
  const baseDir = outputDir;
  const whiteDir = path.join(baseDir, 'white');
  const transparentDir = path.join(baseDir, 'transparent');
  
  const whiteFilepath = path.join(whiteDir, filename);
  const transparentFilepath = path.join(transparentDir, filename);

  // Create both directories if they don't exist
  for (const dir of [whiteDir, transparentDir]) {
    try {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    } catch (err) {
      throw new Error(`Failed to create directory ${dir}: ${err.message}`);
    }
  }
  
  // Skip generation if both files exist
  if (fs.existsSync(transparentFilepath) && fs.existsSync(whiteFilepath)) {
    return filename;
  }
  
  // Generate both versions in a single call
  try {
    const svgVersions = await tex2svg(formula, inline);
    
    // Write transparent version
    if (!fs.existsSync(transparentFilepath)) {
      fs.writeFileSync(transparentFilepath, svgVersions.transparent);
    }
    
    // Write white background version
    if (!fs.existsSync(whiteFilepath)) {
      fs.writeFileSync(whiteFilepath, svgVersions.white);
    }
  } catch (err) {
    throw new Error(`Failed to generate SVG files: ${err.message}`);
  }

  // Return the transparent version filename for backward compatibility
  return filename;
}

/**
 * Process multiple formulas in batch
 */
async function processBatch(formulas, outputDir) {
  const results = [];
  const batchSize = 100;

  for (let i = 0; i < formulas.length; i += batchSize) {
    const batch = formulas.slice(i, i + batchSize);
    const batchResults = await Promise.all(
      batch.map(async ({ formula, inline }) => {
        try {
          const filename = await processFormula(formula, outputDir, inline);
          const hash = hashFormula(formula);
          return {
            formula,
            inline,
            hash,
            filename,
            success: true
          };
        } catch (error) {
          return {
            formula,
            inline,
            error: error.message,
            success: false
          };
        }
      })
    );
    results.push(...batchResults);
  }
  
  return results;
}

// Main execution
if (require.main === module) {
  const args = process.argv.slice(2);

  // Check for batch mode
  if (args[0] === '--batch') {
    if (args.length < 2) {
      console.error("Usage: tex2svg.js --batch <output_dir>");
      console.error("Expects JSON array of {formula: string, inline: boolean} on stdin");
      process.exit(1);
    }

    const outputDir = args[1];
    let inputData = '';

    process.stdin.on('data', (chunk) => {
      inputData += chunk;
    });

    process.stdin.on('end', async () => {
      try {
        const formulas = JSON.parse(inputData);
        const results = await processBatch(formulas, outputDir);
        console.log(JSON.stringify(results));
        process.exit(0);
      } catch (err) {
        console.error("Error:", err.message);
        process.exit(1);
      }
    });
  } else {
    // Original single-formula mode for backward compatibility
    if (args.length < 2) {
      console.log("Usage: tex2svg.js <formula> <output_dir> [--inline] [--transparent|--white]");
      console.log("   or: tex2svg.js --batch <output_dir>");
      process.exit(1);
    }

    const formula = args[0];
    const outputDir = args[1];
    const inline = args.includes("--inline");
    const forceTransparent = args.includes("--transparent");
    const forceWhite = args.includes("--white");

    // Process formula to generate both versions
    processFormula(formula, outputDir, inline)
      .then((filename) => {
        // Determine which path to output based on options
        let outputPath;
        if (forceTransparent) {
          outputPath = path.join('transparent', filename);
        } else if (forceWhite) {
          outputPath = path.join('white', filename);
        } else {
          // Default to transparent for backward compatibility
          outputPath = path.join('transparent', filename);
        }
        console.log(outputPath);
        process.exit(0);
      })
      .catch((err) => {
        console.error("Error:", err.message);
        process.exit(1);
      });
  }
}

module.exports = { 
  tex2svg, 
  processFormula,
  processBatch,
  hashFormula,
  // Helper function to get specific SVG paths
  getSvgPaths: (hash, baseDir) => {
    const filename = `${hash}.svg`;
    return {
      white: path.join(baseDir, 'white', filename),
      transparent: path.join(baseDir, 'transparent', filename)
    };
  }
};
