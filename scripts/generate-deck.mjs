#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const cwd = process.cwd();
const decksRoot = path.join(cwd, "decks");
const templatePath = path.join(decksRoot, "templates", "deck-template.html");
const modulesDir = path.join(decksRoot, "modules");

const args = process.argv.slice(2);
const slug = args[0];
const title = args[1] || "New Presentation";
const moduleArg = args[2] || "project-idea,sre-workflow,database-review";

if (!slug) {
  console.error("Usage: node scripts/generate-deck.mjs <slug> [title] [module1,module2,...]");
  process.exit(1);
}

if (!fs.existsSync(templatePath)) {
  console.error(`Template not found: ${templatePath}`);
  process.exit(1);
}

const moduleNames = moduleArg
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

const missing = moduleNames.filter((name) => !fs.existsSync(path.join(modulesDir, `${name}.md`)));
if (missing.length > 0) {
  console.error(`Missing module files: ${missing.join(", ")}`);
  process.exit(1);
}

const deckDir = path.join(decksRoot, slug);
if (fs.existsSync(deckDir)) {
  console.error(`Deck directory already exists: ${deckDir}`);
  process.exit(1);
}

fs.mkdirSync(deckDir, { recursive: true });

const sections = moduleNames
  .map((name) => `        <section data-markdown="../modules/${name}.md"></section>`)
  .join("\n");

const template = fs.readFileSync(templatePath, "utf8");
const html = template.replaceAll("__TITLE__", title).replace("__SECTIONS__", sections);
const outPath = path.join(deckDir, "index.html");

fs.writeFileSync(outPath, html, "utf8");

console.log(`Created deck: ${outPath}`);
console.log(`Modules: ${moduleNames.join(", ")}`);
