// Keyboard and focus review on the QA site (GOAL §10.4):
// - Tab order through the sign-in form, visible focus indicator on each stop
// - Enter submits; Escape closes a dialog and focus returns to its trigger
// - Shift+Tab moves backwards
// Usage: node keyboard-check.mjs <playwright-core dir> <origin>  (QA_ADMIN_USER/PASS in env)
import path from 'node:path'

const [pwDir, origin] = process.argv.slice(2)
const { chromium } = await import(path.join(pwDir, 'index.mjs'))
const browser = await chromium.launch({
  headless: true,
  args: ['--no-sandbox', '--host-resolver-rules=MAP api.victor-tau.xyz 127.0.0.1'],
})
const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: 'en-US' })
const page = await ctx.newPage()
const out = {}

async function focusInfo() {
  return page.evaluate(() => {
    const el = document.activeElement
    if (!el || el === document.body) return null
    const cs = getComputedStyle(el)
    const visible =
      (cs.outlineStyle !== 'none' && parseFloat(cs.outlineWidth) > 0) ||
      (cs.boxShadow && cs.boxShadow !== 'none')
    return {
      tag: el.tagName.toLowerCase(),
      name: el.getAttribute('name') || el.getAttribute('aria-label') || (el.textContent || '').trim().slice(0, 30),
      label: el.id ? document.querySelector(`label[for="${el.id}"]`)?.textContent?.trim() ?? null : null,
      focus_visible: visible,
    }
  })
}

// 1) sign-in tab order + labels + focus ring
await page.goto(`${origin}/sign-in`, { waitUntil: 'networkidle' })
await page.locator('input[name="username"]').focus()
const stops = []
for (let i = 0; i < 6; i++) {
  stops.push(await focusInfo())
  await page.keyboard.press('Tab')
}
out.signin_tab_stops = stops
await page.keyboard.press('Shift+Tab')
out.shift_tab_back = await focusInfo()

// 2) Enter submits the form (empty password -> stays, shows field error)
await page.locator('input[name="username"]').fill('x')
await page.locator('input[name="password"]').focus()
await page.keyboard.press('Enter')
await page.waitForTimeout(800)
out.enter_submit_validation = await page
  .locator('[aria-invalid="true"], [data-slot="form-message"], [role="alert"]')
  .count()

// 3) log in with keyboard only
await page.locator('input[name="username"]').fill(process.env.QA_ADMIN_USER)
await page.locator('input[name="password"]').fill(process.env.QA_ADMIN_PASS)
await page.keyboard.press('Enter')
await page.waitForURL((u) => !u.pathname.startsWith('/sign-in'), { timeout: 20000 })
out.keyboard_login_final = new URL(page.url()).pathname

// 4) dialog: open "Create API Key" via keyboard, Escape closes, focus returns
await page.goto(`${origin}/keys`, { waitUntil: 'networkidle' })
const trigger = page.getByRole('button', { name: /Create API Key/i }).first()
await trigger.focus()
await page.keyboard.press('Enter')
await page.waitForTimeout(700)
out.dialog_open = await page.locator('[role="dialog"]').count()
out.focus_inside_dialog = await page.evaluate(() => !!document.activeElement?.closest('[role="dialog"]'))
await page.keyboard.press('Escape')
await page.waitForTimeout(600)
out.dialog_closed = (await page.locator('[role="dialog"]').count()) === 0
out.focus_returned_to_trigger = await trigger.evaluate((el) => el === document.activeElement)

// 5) command menu via keyboard shortcut and Escape
await page.keyboard.press('Control+k')
await page.waitForTimeout(500)
out.command_menu_open = await page.locator('[role="dialog"], [cmdk-root]').count()
await page.keyboard.press('Escape')

// 6) icon-only buttons have accessible names (header)
out.unnamed_icon_buttons = await page.evaluate(
  () =>
    [...document.querySelectorAll('header button, [data-slot="sidebar"] button')].filter(
      (b) => !(b.getAttribute('aria-label') || b.textContent.trim() || b.getAttribute('title'))
    ).length
)
console.log(JSON.stringify(out, null, 1))
await browser.close()
