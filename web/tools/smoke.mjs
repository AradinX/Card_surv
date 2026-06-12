// Browser smoke: serves public/, drives the game in headless Chrome,
// captures FPS/draw-ops from the dev overlay and screenshots for layout QA.
import http from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "public");
const MIME = { ".html": "text/html", ".js": "text/javascript", ".webp": "image/webp", ".png": "image/png", ".json": "application/json" };
const server = http.createServer(async (req, res) => {
	try {
		const path = req.url.split("?")[0];
		const file = join(ROOT, path === "/" ? "index.html" : path);
		const body = await readFile(file);
		res.writeHead(200, { "content-type": MIME[extname(file)] || "application/octet-stream" });
		res.end(body);
	} catch {
		res.writeHead(404); res.end("nope");
	}
});
await new Promise((r) => server.listen(8765, r));

const browser = await puppeteer.launch({ headless: true });
const consoleErrors = [];
const failedReqs = [];

async function scenario(name, width, height) {
	const page = await browser.newPage();
	page.on("console", (m) => { if (m.type() === "error") consoleErrors.push(name + ": " + m.text()); });
	page.on("pageerror", (e) => consoleErrors.push(name + " pageerror: " + e.message));
	page.on("requestfailed", (r) => failedReqs.push(name + ": " + r.url()));
	page.on("response", (r) => { if (r.status() >= 400) failedReqs.push(name + " " + r.status() + ": " + r.url()); });
	await page.setViewport({ width, height });
	await page.goto("http://localhost:8765/?dev=1", { waitUntil: "networkidle0" });
	await new Promise((r) => setTimeout(r, 1200));
	await page.screenshot({ path: `smoke_${name}_menu.png` });
	// Click the start button (virtual coords -> screen coords).
	const VW = height > width ? 720 : 1280, VH = height > width ? 1280 : 720;
	const s = Math.min(width / VW, height / VH), ox = (width - VW * s) / 2, oy = (height - VH * s) / 2;
	const v2s = (x, y) => [ox + x * s, oy + y * s];
	let [bx, by] = v2s(VW / 2, VH * 0.66 + 35);
	await page.mouse.click(bx, by);
	await new Promise((r) => setTimeout(r, 800));
	await page.screenshot({ path: `smoke_${name}_play.png` });
	// Play a few full days via keyboard: cards 1..7 then end day, 12 times.
	for (let d = 0; d < 12; d++) {
		for (let k = 1; k <= 7; k++) await page.keyboard.press("Digit" + Math.min(k, 7));
		await page.keyboard.press("Space");
		await new Promise((r) => setTimeout(r, 60));
		// If a reward overlay opened, click the first reward option.
		const [rx, ry] = v2s(VW / 2 - (Math.min(640, VW - 40) / 2) + 16 + (Math.min(640, VW - 40) - 64) / 6, VH / 2 - 140 + 80 + 75);
		await page.mouse.click(rx, ry);
		await new Promise((r) => setTimeout(r, 60));
	}
	await new Promise((r) => setTimeout(r, 600));
	await page.screenshot({ path: `smoke_${name}_late.png` });
	const dev = await page.$eval("#dev", (el) => el.textContent);
	await page.close();
	return dev;
}

const desktop = await scenario("desktop", 1280, 720);
const mobile = await scenario("mobile", 390, 844);
console.log("desktop dev overlay:", desktop);
console.log("mobile dev overlay:", mobile);
console.log("console errors:", consoleErrors.length ? consoleErrors : "none");
console.log("failed requests:", failedReqs.length ? failedReqs : "none");
await browser.close();
server.close();
process.exit(consoleErrors.length || failedReqs.length ? 1 : 0);
