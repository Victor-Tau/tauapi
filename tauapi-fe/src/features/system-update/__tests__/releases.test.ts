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

import {
  compareSystemVersions,
  DEFAULT_SYSTEM_RELEASE_REPOSITORY,
  getSystemReleaseUrl,
  normalizeSystemReleaseRepository,
  resolveSystemReleaseRepository,
  selectLatestRelease,
} from '../releases'

describe('system release ordering', () => {
  test.each([
    ['v0.13.2', 'v1.0.0-alpha.1', -1],
    ['v1.0.0-alpha.2', 'v1.0.0-beta.1', -1],
    ['v1.0.0-beta.1', 'v1.0.0-rc.1', -1],
    ['v1.0.0-rc.9', 'v1.0.0-rc.10', -1],
    ['v1.0.0-rc.19', 'v1.0.0-rc.19-i18nfix.1', -1],
    ['v1.0.0-rc.19-i18nfix.2', 'v1.0.0-rc.20', -1],
    ['v1.0.0-rc.36', 'v1.0.0', -1],
    ['v0.13.1', 'v0.13.1-patch.1', -1],
    ['v0.13.1-patch.9', 'v0.13.1-patch.10', -1],
    ['v0.13.1-patch.10', 'v0.13.2', -1],
    ['v0.8.8.3.2', 'v0.8.8.3.3', -1],
    ['v0.9.3.0', 'v0.9.3', 0],
    ['v1.0.0+build.1', '1.0.0+build.2', 0],
    ['v1.0.0-rc.37', 'v1.0.0-rc.36', 1],
    ['v1.0.0', 'v1.0.0', 0],
    ['v0.0.0', 'v1.0.0', null],
    ['dev', 'v1.0.0', null],
    ['', 'v1.0.0', null],
    ['v1.0.0-custom.1', 'v1.0.0', null],
    ['v1.0.0-rc.36-2-gabcdef', 'v1.0.0', null],
  ])('compares %s against %s as %s', (current, latest, expected) => {
    expect(compareSystemVersions(current, latest)).toBe(expected)
  })

  test('selects the highest published version including pre-releases, regardless of order', () => {
    const releases = [
      { tag_name: 'v1.0.0-rc.19-i18nfix.2', draft: false, prerelease: true },
      { tag_name: 'v0.13.2', draft: false, prerelease: false },
      { tag_name: 'v2.0.0', draft: true, prerelease: false },
      { tag_name: 'v1.0.0-rc.36', draft: false, prerelease: true },
      { tag_name: 'nightly', draft: false, prerelease: true },
    ]
    expect(selectLatestRelease(releases)?.tag_name).toBe('v1.0.0-rc.36')
  })

  test('returns no release for an empty list or a list containing only drafts', () => {
    expect(selectLatestRelease([])).toBeNull()
    expect(
      selectLatestRelease([
        { tag_name: 'v2.0.0', draft: true, prerelease: false },
      ])
    ).toBeNull()
  })

  test('rejects malformed payloads instead of reporting that the system is current', () => {
    expect(() => selectLatestRelease({ message: 'bad response' })).toThrow()
    expect(() => selectLatestRelease([{ tag_name: 42 }])).toThrow()
  })
})

describe('system release repository', () => {
  test.each([
    ['', ''],
    ['  Victor-Tau/tauapi ', 'Victor-Tau/tauapi'],
    ['https://github.com/acme/fork.git', 'acme/fork'],
    ['https://github.com/acme/fork/releases/tag/v1.0.0', 'acme/fork'],
    ['git@github.com:acme/fork.git', 'acme/fork'],
  ])('normalizes %j', (input, expected) => {
    expect(normalizeSystemReleaseRepository(input)).toBe(expected)
  })

  test.each([
    'acme',
    'a/b/c',
    'https://gitlab.com/a/b',
    '-a/b',
    'a/..',
    'https://github.com/a',
  ])('rejects %j', (input) => {
    expect(normalizeSystemReleaseRepository(input)).toBeNull()
  })

  test('falls back to the TauAPI repository and builds URLs from the source', () => {
    expect(resolveSystemReleaseRepository(undefined)).toBe(
      DEFAULT_SYSTEM_RELEASE_REPOSITORY
    )
    expect(resolveSystemReleaseRepository('not a repo')).toBe(
      DEFAULT_SYSTEM_RELEASE_REPOSITORY
    )
    expect(
      getSystemReleaseUrl(
        { tag_name: 'v1.0.0', prerelease: false },
        'acme/fork'
      )
    ).toBe('https://github.com/acme/fork/releases/tag/v1.0.0')
  })
})
