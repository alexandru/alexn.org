#!/usr/bin/env node

const { mathjax } = require('mathjax-full/js/mathjax');
const { TeX } = require('mathjax-full/js/input/tex');
const { SVG } = require('mathjax-full/js/output/svg');
const { liteAdaptor } = require('mathjax-full/js/adaptors/liteAdaptor');
const { RegisterHTMLHandler } = require('mathjax-full/js/handlers/html');
const { AllPackages } = require('mathjax-full/js/input/tex/AllPackages');
const { SerializedMmlVisitor } = require('mathjax-full/js/core/MmlTree/SerializedMmlVisitor');
const fs = require("fs").promises;
const crypto = require("crypto");
const path = require("path");
const os = require("os");

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
 * Escape XML special characters
 */
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

/**
 * Convert TeX formula to SVG and MathML
 */
async function tex2svg(formula, inline = false) {
  try {
    // Create a temporary document with the formula
    // Use \(...\) for inline and $$...$$ for display as these are recognized by default
    const wrappedFormula = inline 
      ? `\\(${formula}\\)` 
      : `$$${formula}$$`;
    const tempDoc = mathjax.document(`<div>${wrappedFormula}</div>`, { 
      InputJax: tex, 
      OutputJax: svg 
    });
    
    // Find and compile the math to get the internal MML tree
    tempDoc.findMath();
    tempDoc.compile();
    
    // Get the MathML from the compiled math item
    let mmlString = '';
    for (const mathItem of tempDoc.math) {
      if (mathItem.root) {
        const visitor = new SerializedMmlVisitor(tex.mmlFactory);
        mmlString = visitor.visitTree(mathItem.root);
        break; // We only expect one formula per document
      }
    }
    
    // Now render to get the SVG
    tempDoc.render();
    
    // Extract the SVG element from the rendered HTML
    const body = adaptor.body(tempDoc.document);
    const rendered = adaptor.innerHTML(body);
    
    // Parse the rendered HTML to extract the SVG
    const svgMatch = rendered.match(/<svg[^>]*>[\s\S]*?<\/svg>/);
    if (!svgMatch) {
      throw new Error('Failed to extract SVG from rendered output');
    }
    
    let svgString = svgMatch[0];

    // Add title to the SVG for accessibility
    const svgWithTitle = svgString.replace(
      /<svg([^>]*)>/,
      `<svg$1><title>${escapeXml(formula)}</title>`
    );

    // Return both versions
    return {
      svg: svgWithTitle,
      mathml: mmlString
    };
  } catch (error) {
    throw new Error(`Failed to render formula: ${error.message}`);
  }
}

/**
 * Process a single formula and save to files
 */
async function processFormula(formula, outputDir, inline = false) {
  const hash = hashFormula(formula);
  const svgFilename = `${hash}.svg`;
  const mathmlFilename = `${hash}.html`;
  
  // Create paths
  const svgDir = path.join(outputDir, 'svg');
  const mathmlDir = path.join(outputDir, 'mathml');
  
  const svgFilepath = path.join(svgDir, svgFilename);
  const mathmlFilepath = path.join(mathmlDir, mathmlFilename);

  // Create directories if they don't exist
  await fs.mkdir(svgDir, { recursive: true });
  await fs.mkdir(mathmlDir, { recursive: true });
  
  // Check if both files exist
  try {
    await Promise.all([
      fs.access(svgFilepath),
      fs.access(mathmlFilepath)
    ]);
    // Both files exist, return early
    return { hash, svgFilename, mathmlFilename };
  } catch (err) {
    // One or both files don't exist, generate them
  }
  
  // Generate both versions
  const { svg, mathml } = await tex2svg(formula, inline);
  
  // Write both files in parallel
  await Promise.all([
    fs.writeFile(svgFilepath, svg, 'utf8'),
    fs.writeFile(mathmlFilepath, mathml, 'utf8')
  ]);

  return { hash, svgFilename, mathmlFilename };
}

/**
 * Process multiple formulas in parallel
 */
async function processFormulas(formulas, outputDir) {
  const concurrency = os.cpus().length;
  const results = [];
  
  // Process formulas in batches for parallelism
  for (let i = 0; i < formulas.length; i += concurrency) {
    const batch = formulas.slice(i, i + concurrency);
    const batchResults = await Promise.all(
      batch.map(({ formula, inline }) => 
        processFormula(formula, outputDir, inline)
          .catch(err => ({ error: err.message, formula }))
      )
    );
    results.push(...batchResults);
  }
  
  return results;
}

// Main execution
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    console.log("Usage: tex2svg.js <json_input> <output_dir>");
    console.log("  json_input: JSON string with format [{\"formula\": \"...\", \"inline\": true/false}, ...]");
    console.log("  output_dir: Base directory for output (will create svg/ and mathml/ subdirs)");
    process.exit(1);
  }

  const jsonInput = args[0];
  const outputDir = args[1];

  let formulas;
  try {
    formulas = JSON.parse(jsonInput);
    if (!Array.isArray(formulas)) {
      throw new Error("Input must be an array");
    }
  } catch (err) {
    console.error("Error parsing JSON input:", err.message);
    process.exit(1);
  }

  // Process all formulas
  processFormulas(formulas, outputDir)
    .then((results) => {
      // Output results as JSON
      console.log(JSON.stringify(results, null, 2));
      
      // Check for errors
      const errors = results.filter(r => r.error);
      if (errors.length > 0) {
        console.error("Some formulas failed to process:", errors);
        process.exit(1);
      }
      
      process.exit(0);
    })
    .catch((err) => {
      console.error("Error:", err.message);
      process.exit(1);
    });
}

module.exports = { 
  tex2svg, 
  processFormula,
  processFormulas,
  hashFormula
};
