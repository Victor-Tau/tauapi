// Old-tab lazy-chunk drill (GOAL §14 / §17.5).
// 1. open the site (release A) in a browser tab, record which release the page loaded
// 2. wait for a signal file (operator deploys release B meanwhile)
// 3. in the SAME tab, navigate client-side to a not-yet-loaded route, which forces
//    a dynamic import of a chunk from release A's /_ui/<A>/ prefix
// 4. report every /_ui/ request status; success = old chunks still 200 and the
//    new route rendered without a full reload.
// Usage: node old-tab-drill.mjs <playwright-core dir> <origin> <signal-file> <out.json>
import fs from 'node:fs'
import path from 'node:path'

const [pwDir, origin, signal, out] = process.argv.slice(2)
const { chromium } = await import(path.join(pwDir, 'index.mjs'))
const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--host-resolver-rules=MAP api.victor-tau.xyz 127.0.0.1'],
})
const page = await browser.newPage({ viewport: { width: 1280, height: 800 } })
const requests = []
page.on('response', (r) => {
  const u = new URL(r.url())
  if (u.pathname.startsWith('/_ui/')) requests.push({ t: Date.now(), path: u.pathname, status: r.status() })
})
let fullReloads = 0
page.on('framenavigated', (f) => {
  if (f === page.mainFrame()) fullReloads++
})
await page.goto(`${origin}/`, { waitUntil: 'networkidle' })
const releaseBefore = await page.evaluate(() =>
  [...document.querySelectorAll('script[src]')].map((s) => s.src).find((s) => s.includes('/_ui/'))
)
const reloadsAtStart = fullReloads
const loadedBefore = new Set(requests.map((r) => r.path))
fs.writeFileSync(`${signal}.ready`, 'ready')
const deadline = Date.now() + 15 * 60 * 1000
while (!fs.existsSync(signal) && Date.now() < deadline) await new Promise((r) => setTimeout(r, 1000))
// Ask from inside the browser so the loopback host mapping applies.
const currentRelease = await page
  .evaluate(() => fetch('/_meta/ui-version.json', { cache: 'no-store' }).then((r) => r.json()))
  .catch(() => null)
const markIdx = requests.length
// client-side navigation (no reload) to routes whose chunks were not loaded yet
for (const href of ['/pricing', '/rankings', '/about']) {
  await page.evaluate((h) => {
    window.history.pushState({}, '', h)
    window.dispatchEvent(new PopStateEvent('popstate'))
  }, href)
  await page.waitForLoadState('networkidle')
  await page.waitForTimeout(800)
}
const after = requests.slice(markIdx)
const newChunks = after.filter((r) => !loadedBefore.has(r.path))
const result = {
  release_in_tab: releaseBefore?.match(/\/_ui\/([^/]+)\//)?.[1] ?? null,
  current_release_on_server: currentRelease?.release_id ?? null,
  lazy_requests_after_deploy: newChunks.length,
  lazy_failures: newChunks.filter((r) => r.status !== 200).length,
  lazy_from_old_release: newChunks.filter((r) => r.path.startsWith(`/_ui/${releaseBefore?.match(/\/_ui\/([^/]+)\//)?.[1]}/`)).length,
  full_reloads_during_drill: fullReloads - reloadsAtStart,
  final_path: new URL(page.url()).pathname,
  sample: newChunks.slice(0, 5),
}
fs.writeFileSync(out, JSON.stringify(result, null, 2))
console.log(JSON.stringify(result))
await browser.close()
