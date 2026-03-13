#!/usr/bin/env node

import { readFileSync } from "fs";
import TurndownService from "turndown";
import { JSDOM } from "jsdom";

const html = readFileSync(0, "utf-8");

const SELECTOR = "#sec-regexp-regular-expression-objects"
const section = new JSDOM(html).window.document.querySelector(SELECTOR);
section.querySelectorAll("emu_table").forEach(e => e.remove());
section.querySelectorAll("a").forEach(a => a.outerHTML = a.innerHTML);
section.querySelectorAll("sup").forEach(e => e.innerHTML = "^" + e.innerHTML);
section.querySelectorAll("emu-opt").forEach(e => e.innerHTML = "_" + e.innerHTML);

const md = new TurndownService().turndown(section.innerHTML);
process.stdout.write(md.replace(" ", ""));
