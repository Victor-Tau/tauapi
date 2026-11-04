// New-version notice check (GOAL §8.3): a tab running release A must show a
// notice when the live release changes, and must NOT reload by itself.
// Usage: node notice-check.mjs <playwright-core dir> <origin> <signal-file>
//   writes <signal-file>.ready once the tab is open; operator switches the live
//   release, then creates <signal-file>; the script then triggers the check.
import fs from 'node:fs'
import path from 'node:path'

const [pwDir, origin, signal] = process.argv.slice(2)
const { chromium } = await import(path.join(pwDir, 'index.mjs'))
const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--host-resolver-rules=MAP api.victor-tau.xyz 127.0.0.1'],
})
const page = await browser.newPage({ viewport: { width: 1280, height: 800 }, locale: 'en-US' })
await page.addInitScript(() => {
  try {
    localStorage.setItem('i18nextLng', 'en')
  } catch {}
})
let reloads = 0
page.on('framenavigated', (f) => {
  if (f === page.mainFrame()) reloads++
})
await page.goto(`${origin}/pricing`, { waitUntil: 'networkidle' })
const bundleRelease = await page.evaluate(
  () => [...document.querySelectorAll('script[src]')].map((s) => s.src).find((s) => s.includes('/_ui/'))?.match(/\/_ui\/([^/]+)\//)?.[1] ?? null
)
const reloadsBefore = reloads
// Type into the search box to simulate in-progress work that must survive.
const search = page.locator('input[type="search"], input[placeholder*="Search"]').first()
await search.fill('work-in-progress').catch(() => {})
fs.writeFileSync(`${signal}.ready`, 'ready')
const deadline = Date.now() + 10 * 60 * 1000
while (!fs.existsSync(signal) && Date.now() < deadline) await new Promise((r) => setTimeout(r, 1000))
// Trigger the hook's check as a tab-focus would.
await page.evaluate(() => document.dispatchEvent(new Event('visibilitychange')))
const toast = page.getByText('A new version is available', { exact: false })
const toastShown = await toast.waitFor({ timeout: 15000 }).then(() => true).catch(() => false)
const refreshButton = toastShown ? await page.getByRole('button', { name: 'Refresh' }).count() : 0
const live = await page.evaluate(() => fetch('/_meta/ui-version.json', { cache: 'no-store' }).then((r) => r.json()).then((j) => j.release_id))
const inputKept = await search.inputValue().catch(() => null)
console.log(
  JSON.stringify({
    bundle_release: bundleRelease,
    live_release_after_switch: live,
    notice_shown: toastShown,
    refresh_action_present: refreshButton > 0,
    automatic_reloads: reloads - reloadsBefore,
    in_progress_input_kept: inputKept === 'work-in-progress',
  })
)
await page.screenshot({ path: `${signal}.png` })
await browser.close()
