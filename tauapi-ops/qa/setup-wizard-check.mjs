// Setup wizard review against a REAL uninitialised backend (GOAL §10.2 "初始化").
// A throwaway backend container (SQLite on tmpfs, 127.0.0.1:3199, no secrets
// shared with prod/QA) answers every /api/* request of the browser; the
// frontend itself is the deployed QA release served by Nginx (:8443).
// Usage: node setup-wizard-check.mjs <playwright-core dir> <out dir> [light-desktop|dark-desktop|light-mobile]
import fs from 'node:fs'
import path from 'node:path'

const [pwDir, outDir, only] = process.argv.slice(2)
const ORIGIN = 'https://api.victor-tau.xyz:8443'
const BACKEND = 'http://127.0.0.1:3199'
const { chromium } = await import(path.join(pwDir, 'index.mjs'))
fs.mkdirSync(outDir, { recursive: true })
const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--host-resolver-rules=MAP api.victor-tau.xyz 127.0.0.1'],
})
const results = []

for (const [theme, viewport] of [
  ['light', { width: 1440, height: 900 }],
  ['dark', { width: 1440, height: 900 }],
  ['light', { width: 390, height: 844 }],
]) {
  const tag = `${theme}-${viewport.width < 600 ? 'mobile' : 'desktop'}`
  if (only && only !== tag) continue
  const ctx = await browser.newContext({ viewport, colorScheme: theme, locale: 'en-US', reducedMotion: 'reduce' })
  await ctx.addInitScript((t) => {
    try {
      localStorage.setItem('newapi:theme:v1:mode', t)
      localStorage.setItem('i18nextLng', 'en')
    } catch {}
  }, theme)
  // Forward API traffic to the isolated uninitialised backend.
  await ctx.route(/\/api\//, async (route) => {
    const req = route.request()
    const u = new URL(req.url())
    const headers = { ...req.headers() }
    delete headers.host
    const resp = await fetch(BACKEND + u.pathname + u.search, {
      method: req.method(),
      headers,
      body: ['GET', 'HEAD'].includes(req.method()) ? undefined : req.postDataBuffer(),
    })
    const body = Buffer.from(await resp.arrayBuffer())
    const outHeaders = {}
    resp.headers.forEach((v, k) => {
      if (!['content-encoding', 'content-length', 'transfer-encoding'].includes(k)) outHeaders[k] = v
    })
    await route.fulfill({ status: resp.status, headers: outHeaders, body })
  })
  const page = await ctx.newPage()
  await page.goto(`${ORIGIN}/`, { waitUntil: 'networkidle' })
  await page.waitForTimeout(800)
  const landed = new URL(page.url()).pathname
  const shots = []
  for (let step = 1; step <= 5; step++) {
    const file = `setup-step${step}__${tag}.png`
    await page.screenshot({ path: path.join(outDir, file), animations: 'disabled' })
    const heading = await page.locator('h1, h2, h3').first().innerText().catch(() => '')
    shots.push({ step, file, heading: heading.slice(0, 60) })
    // Fill the admin step when present (throwaway DB only).
    const user = page.locator('input[name="username"]')
    if (await user.count()) {
      await user.fill('setupcheck')
      await page.locator('input[name="password"]').fill('SetupCheck-Only-123')
      await page.locator('input[name="confirmPassword"]').fill('SetupCheck-Only-123').catch(() => {})
    }
    const next = page.getByRole('button', { name: /^(Next|Continue|Initialize|Complete|Finish)/i }).last()
    if (!(await next.count()) || !(await next.isEnabled().catch(() => false))) break
    await next.click()
    await page.waitForTimeout(900)
  }
  results.push({ tag, landed_on: landed, shots })
  await ctx.close()
}
fs.writeFileSync(path.join(outDir, `setup-wizard-${only || 'all'}.json`), JSON.stringify(results, null, 1))
console.log(JSON.stringify(results))
await browser.close()
