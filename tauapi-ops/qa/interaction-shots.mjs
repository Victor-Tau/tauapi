// Interaction screenshots on the QA site: portals, overlays and menus that a
// static page capture does not show. Usage:
//   node interaction-shots.mjs <playwright-core dir> <origin> <out dir>   (QA_ADMIN_USER/PASS in env)
import fs from 'node:fs'
import path from 'node:path'

const [pwDir, origin, outDir] = process.argv.slice(2)
const { chromium } = await import(path.join(pwDir, 'index.mjs'))
fs.mkdirSync(outDir, { recursive: true })
const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--host-resolver-rules=MAP api.victor-tau.xyz 127.0.0.1'],
})
const results = []

async function session(theme, viewport) {
  const ctx = await browser.newContext({ viewport, colorScheme: theme, locale: 'en-US', reducedMotion: 'reduce' })
  await ctx.addInitScript((t) => {
    try {
      localStorage.setItem('newapi:theme:v1:mode', t)
      localStorage.setItem('i18nextLng', 'en')
    } catch {}
  }, theme)
  const page = await ctx.newPage()
  await page.goto(`${origin}/sign-in`, { waitUntil: 'networkidle' })
  await page.locator('input[name="username"]').fill(process.env.QA_ADMIN_USER)
  await page.locator('input[name="password"]').fill(process.env.QA_ADMIN_PASS)
  await page.keyboard.press('Enter')
  await page.waitForURL((u) => !u.pathname.startsWith('/sign-in'), { timeout: 20000 })
  return { ctx, page }
}

async function shot(page, name, check) {
  await page.waitForTimeout(500)
  const ok = check ? await check().catch(() => false) : true
  const file = path.join(outDir, `${name}.png`)
  await page.screenshot({ path: file, animations: 'disabled' })
  results.push({ name, ok, file: path.basename(file) })
}

for (const theme of ['light', 'dark']) {
  const { ctx, page } = await session(theme, { width: 1440, height: 900 })
  // dialog
  await page.goto(`${origin}/keys`, { waitUntil: 'networkidle' })
  await page.getByRole('button', { name: /Create API Key/i }).first().click()
  await shot(page, `dialog-create-key__${theme}`, () => page.locator('[role="dialog"]').first().isVisible())
  await page.keyboard.press('Escape')
  // command palette
  await page.keyboard.press('Control+k')
  await shot(page, `command-menu__${theme}`, () => page.locator('[role="dialog"]').first().isVisible())
  await page.keyboard.press('Escape')
  // profile dropdown
  await page.locator('header [data-slot="dropdown-menu-trigger"]').last().click()
  await shot(page, `profile-menu__${theme}`, () => page.locator('[role="menu"]').first().isVisible())
  await page.keyboard.press('Escape')
  // theme/config drawer (palette icon)
  const cfg = page.getByRole('button', { name: /Theme settings|Customize|Open theme settings|Settings/i }).first()
  if (await cfg.count()) {
    await cfg.click()
    await shot(page, `config-drawer__${theme}`, () => page.locator('[role="dialog"]').first().isVisible())
    await page.keyboard.press('Escape')
  }
  // channel create drawer
  await page.goto(`${origin}/channels`, { waitUntil: 'networkidle' })
  await page.getByRole('button', { name: /Create Channel/i }).first().click()
  await shot(page, `drawer-create-channel__${theme}`, () => page.locator('[role="dialog"]').first().isVisible())
  await page.keyboard.press('Escape')
  // select / popover inside filters
  await page.goto(`${origin}/usage-logs/common`, { waitUntil: 'networkidle' })
  await page.getByRole('combobox').first().click().catch(() => {})
  await shot(page, `select-popover__${theme}`)
  await page.keyboard.press('Escape')
  // toast (copy action feedback) via playground model selector + charts page
  await page.goto(`${origin}/dashboard/models`, { waitUntil: 'networkidle' })
  await shot(page, `charts-models__${theme}`, () => page.locator('canvas').first().isVisible())
  await ctx.close()
}

// mobile: sidebar sheet + top nav menu
for (const theme of ['light', 'dark']) {
  const { ctx, page } = await session(theme, { width: 390, height: 844 })
  await page.goto(`${origin}/dashboard/overview`, { waitUntil: 'networkidle' })
  await page.locator('[data-sidebar="trigger"], button[aria-label*="idebar" i]').first().click().catch(() => {})
  await shot(page, `mobile-sidebar-sheet__${theme}`, () => page.locator('[data-mobile="true"], [role="dialog"]').first().isVisible())
  await page.keyboard.press('Escape')
  await ctx.close()
}
// public mobile menu
{
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, locale: 'en-US' })
  const page = await ctx.newPage()
  await page.goto(`${origin}/`, { waitUntil: 'networkidle' })
  await page.getByRole('button', { name: /menu/i }).first().click().catch(() => {})
  await shot(page, `mobile-public-menu__light`)
  await ctx.close()
}
fs.writeFileSync(path.join(outDir, 'interactions.json'), JSON.stringify(results, null, 1))
console.log(JSON.stringify(results))
await browser.close()
