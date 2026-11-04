// Extra regression checks on the QA site:
//  A) zh locale at an effective 200% zoom (720x450 CSS px): no page-level
//     horizontal overflow on representative pages
//  B) common user cannot reach admin pages/APIs
//  C) Playground: send to the mock model (streamed), stop mid-stream, error model
// Usage: node extra-checks.mjs <playwright-core dir> <origin> <out dir>
//   env: QA_ADMIN_USER/PASS, QA_USER/QA_USER_PASS
import fs from 'node:fs'
import path from 'node:path'

const [pwDir, origin, outDir] = process.argv.slice(2)
const { chromium } = await import(path.join(pwDir, 'index.mjs'))
fs.mkdirSync(outDir, { recursive: true })
const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--host-resolver-rules=MAP api.victor-tau.xyz 127.0.0.1'],
})
const out = { zoom_zh: [], permissions: {}, playground: {} }

async function ctxLogin(user, pass, opts = {}) {
  const ctx = await browser.newContext({ locale: opts.locale || 'en-US', viewport: opts.viewport || { width: 1440, height: 900 }, deviceScaleFactor: opts.dpr || 1 })
  await ctx.addInitScript((lng) => {
    try {
      localStorage.setItem('i18nextLng', lng)
    } catch {}
  }, opts.lng || 'en')
  const page = await ctx.newPage()
  await page.goto(`${origin}/sign-in`, { waitUntil: 'networkidle' })
  await page.locator('input[name="username"]').fill(user)
  await page.locator('input[name="password"]').fill(pass)
  await page.keyboard.press('Enter')
  await page.waitForURL((u) => !u.pathname.startsWith('/sign-in'), { timeout: 20000 })
  return { ctx, page }
}

// A) 200% zoom equivalent, Chinese
{
  const { ctx, page } = await ctxLogin(process.env.QA_ADMIN_USER, process.env.QA_ADMIN_PASS, {
    viewport: { width: 720, height: 450 }, dpr: 2, lng: 'zh', locale: 'zh-CN',
  })
  for (const p of ['/dashboard/overview', '/keys', '/channels', '/usage-logs/common', '/system-settings/billing/payment', '/pricing', '/']) {
    await page.goto(`${origin}${p}`, { waitUntil: 'networkidle' })
    await page.waitForTimeout(600)
    const ox = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)
    const file = `zoom200-zh${p.replace(/\//g, '_') || '_home'}.png`
    await page.screenshot({ path: path.join(outDir, file) })
    out.zoom_zh.push({ path: p, final: new URL(page.url()).pathname, overflow_x: ox, file })
  }
  await ctx.close()
}

// B) permissions as common user
{
  const { ctx, page } = await ctxLogin(process.env.QA_USER, process.env.QA_USER_PASS)
  for (const p of ['/channels', '/users', '/system-settings/site/system-info', '/task-plugins']) {
    await page.goto(`${origin}${p}`, { waitUntil: 'networkidle' })
    await page.waitForTimeout(500)
    out.permissions[p] = new URL(page.url()).pathname
  }
  out.permissions.api_channel = await page.evaluate(async () => {
    const tok = sessionStorage.length // not used; rely on app's own client below
    const r = await fetch('/api/channel/?p=1', { headers: { Accept: 'application/json' } })
    return r.status
  })
  out.permissions.admin_menu_items_visible = await page.locator('nav a[href="/channels"], [data-slot="sidebar"] a[href="/channels"]').count()
  await page.screenshot({ path: path.join(outDir, 'user-forbidden.png') })
  await ctx.close()
}

// C) playground
{
  const { ctx, page } = await ctxLogin(process.env.QA_ADMIN_USER, process.env.QA_ADMIN_PASS)
  await page.goto(`${origin}/playground`, { waitUntil: 'networkidle' })
  const pick = async (model) => {
    await page.locator('button[role="combobox"], [data-slot="select-trigger"], button:has-text("mock-")').last().click()
    await page.getByRole('option', { name: model }).first().click()
  }
  try {
    await pick('mock-slow-20')
    const box = page.locator('textarea').first()
    await box.fill('playground drill')
    await box.press('Enter')
    await page.getByText('tick 2', { exact: false }).first().waitFor({ timeout: 15000 })
    out.playground.streamed_partial = true
    const stop = page.getByRole('button', { name: /stop/i }).first()
    out.playground.stop_button_visible = await stop.isVisible().catch(() => false)
    if (out.playground.stop_button_visible) await stop.click()
    await page.waitForTimeout(3000)
    const text = await page.locator('body').innerText()
    const ticks = (text.match(/tick \d+/g) || []).length
    out.playground.ticks_after_stop = ticks
    out.playground.stopped_early = ticks < 20
    await page.screenshot({ path: path.join(outDir, 'playground-stopped.png') })
    await pick('mock-error')
    await box.fill('error drill')
    await box.press('Enter')
    await page.waitForTimeout(4000)
    out.playground.error_visible = await page.getByText(/error|failed|mock upstream failure/i).first().isVisible().catch(() => false)
    await page.screenshot({ path: path.join(outDir, 'playground-error.png') })
  } catch (e) {
    out.playground.error = String(e.message).slice(0, 160)
    await page.screenshot({ path: path.join(outDir, 'playground-debug.png') })
  }
  await ctx.close()
}
fs.writeFileSync(path.join(outDir, 'extra-checks.json'), JSON.stringify(out, null, 1))
console.log(JSON.stringify(out))
await browser.close()
