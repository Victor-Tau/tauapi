/*
Copyright (C) 2023-2026 QuantumNous

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

For commercial licensing, please contact support@quantumnous.com
*/
import { describe, expect, test } from 'vitest'

import en from '@/i18n/locales/en.json'
import fr from '@/i18n/locales/fr.json'
import ja from '@/i18n/locales/ja.json'
import ru from '@/i18n/locales/ru.json'
import vi from '@/i18n/locales/vi.json'
import zhTW from '@/i18n/locales/zh-TW.json'
import zh from '@/i18n/locales/zh.json'

const HERO_KEYS = [
  'Auntie Key is open for business today!',
  "Drop by Auntie Key's stall,",
  'and grab a steaming bowl of',
  'API Relay for Everyone',
  'Buy a key from Auntie Key',
  'Pure relay · Usage-based billing',
  'Auntie Key street stall illustration',
] as const

const LOCALES: Record<string, { translation: Record<string, string> }> = {
  en,
  fr,
  ja,
  ru,
  vi,
  zhCN: zh,
  zhTW,
}

describe('Key Yi hero copy', () => {
  test.each(Object.entries(LOCALES))(
    '%s locale defines every hero string',
    (_language, locale) => {
      for (const key of HERO_KEYS) {
        expect(locale.translation[key], key).toBeTruthy()
      }
    }
  )

  test('Chinese locales use the Key姨 brand name in the call to action', () => {
    expect(zh.translation['Buy a key from Auntie Key']).toBe('找Key姨买Key')
    expect(zhTW.translation['Buy a key from Auntie Key']).toBe('找Key姨買Key')
  })
})
