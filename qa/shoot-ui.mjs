// Visual review screenshots for the TauAPI QA stack (isolated data only).
// Usage: node shoot-ui.mjs <playwright-core dir> <inventory.json> <out dir> <origin> [filter]
// Reads QA credentials from env (QA_ADMIN_USER/QA_ADMIN_PASS, QA_USER/QA_USER_PASS),
// never writes them to disk. For every inventory row it loads the URL in each
// requested viewport/theme, waits for network idle, records the FINAL URL and
// whether the row's marker text is visible, and saves a PNG.
import fs from 'node:fs'
import path from 'node:path'

const [pwDir, invPath, outDir, origin, filter] = process.argv.slice(2)
const { chromium } = await import(path.join(pwDir, 'index.mjs'))
const filters = (filter || '').split(',').filter(Boolean)
const inventory = JSON.parse(fs.readFileSync(invPath, 'utf8')).filter(
  (r) => filters.length === 0 || filters.some((f) => r.id.startsWith(f))
)
fs.mkdirSync(outDir, { recursive: true })

const VIEWPORTS = {
  desktop: { width: 1440, height: 900 },
  tablet: { width: 768, height: 1024 },
  mobile: { width: 390, height: 844 },
}
const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--host-resolver-rules=MAP api.victor-tau.xyz 127.0.0.1'],
})

async function login(context, user, pass) {
  const page = await context.newPage()
  await page.goto(`${origin}/sign-in`, { waitUntil: 'networkidle' })
  await page.locator('input[name="username"]').fill(user)
  await page.locator('input[name="password"]').fill(pass)
  await page.locator('button[type="submit"]').first().click()
  await page.waitForURL((u) => !u.pathname.startsWith('/sign-in'), { timeout: 20000 })
  await page.close()
}

const contexts = {}
async function ctxFor(role, theme, vp) {
  const key = `${role}-${theme}-${vp}`
  if (contexts[key]) return contexts[key]
  const context = await browser.newContext({
    viewport: VIEWPORTS[vp],
    colorScheme: theme,
    locale: 'en-US',
    reducedMotion: 'reduce',
  })
  await context.addInitScript((t) => {
    try {
      localStorage.setItem('newapi:theme:v1:mode', t)
      localStorage.setItem('i18nextLng', 'en')
    } catch {}
  }, theme)
  try {
    if (role === 'admin' || role === 'root') await login(context, process.env.QA_ADMIN_USER, process.env.QA_ADMIN_PASS)
    if (role === 'user') await login(context, process.env.QA_USER, process.env.QA_USER_PASS)
  } catch (e) {
    console.error(`login failed for ${role}: ${String(e.message).slice(0, 120)}`)
  }
  contexts[key] = context
  return context
}

const results = []
for (const row of inventory) {
  for (const shot of row.shots) {
    const [theme, vp] = shot.split('-')
    const context = await ctxFor(row.role, theme, vp)
    const page = await context.newPage()
    const errors = []
    page.on('pageerror', (e) => errors.push(String(e.message).slice(0, 160)))
    let status = 'ok'
    try {
      await page.goto(`${origin}${row.url}`, { waitUntil: 'networkidle', timeout: 30000 })
      await page.waitForTimeout(700)
    } catch (e) {
      status = `nav-error: ${String(e.message).slice(0, 80)}`
    }
    const finalUrl = new URL(page.url())
    const markerVisible = row.marker
      ? await page
          .getByText(row.marker, { exact: false })
          .first()
          .isVisible()
          .catch(() => false)
      : null
    const overflowX = await page
      .evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)
      .catch(() => -1)
    const file = path.join(outDir, `${row.id}__${shot}.png`)
    await page.screenshot({ path: file, fullPage: false, animations: 'disabled' })
    const expectedPath = row.expect_path ?? row.url.split('?')[0]
    results.push({
      id: row.id,
      shot,
      url: row.url,
      final_path: finalUrl.pathname,
      path_ok: finalUrl.pathname === expectedPath,
      marker: row.marker,
      marker_visible: markerVisible,
      overflow_x: overflowX,
      page_errors: errors.length,
      status,
      file: path.relative(outDir, file),
    })
    await page.close()
  }
}
fs.writeFileSync(path.join(outDir, 'results.json'), JSON.stringify(results, null, 2))
await browser.close()
const bad = results.filter((r) => !r.path_ok || r.marker_visible === false || r.status !== 'ok')
console.log(JSON.stringify({ shots: results.length, problems: bad.length }))
for (const b of bad) console.log(JSON.stringify(b))
