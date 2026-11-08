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

import { formatComponentVersion } from '@/lib/component-versions'

describe('formatComponentVersion', () => {
  test.each([
    ['fe', '1.0.1+fe.53c0e999057f', 'fe-1.0.1'],
    ['be', '1.0.1+be.53c0e999057f', 'be-1.0.1'],
    ['be', 'v1.0.1', 'be-1.0.1'],
    ['fe', ' V2.3.4 ', 'fe-2.3.4'],
    ['be', 'v1.0.0-rc.36+be.abc', 'be-1.0.0-rc.36'],
    ['fe', 'dev', 'fe-dev'],
  ] as const)('%s %s -> %s', (component, version, expected) => {
    expect(formatComponentVersion(component, version)).toBe(expected)
  })

  test.each([undefined, '', '  ', '+be.53c0e999057f'])(
    'treats %j as unknown',
    (version) => {
      expect(formatComponentVersion('be', version)).toBeUndefined()
    }
  )
})
