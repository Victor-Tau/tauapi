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
import type { SystemStatus } from '@/features/auth/types'

/** The version of this bundle, independent of the server currently serving APIs. */
export function getFrontendVersion(): string | undefined {
  return import.meta.env.VITE_REACT_APP_VERSION?.trim() || undefined
}

/** Older backends expose only version; placeholder versions remain unknown. */
export function getBackendVersion(
  status: SystemStatus | null | undefined
): string | undefined {
  const version = status?.backend_version?.trim() || status?.version?.trim()
  if (version === 'v0.0.0' || version === '0.0.0') return undefined
  return version || undefined
}

export type ReleaseComponent = 'fe' | 'be'

/**
 * Display label such as `fe-1.0.1`: drops the `v` prefix and `+build` metadata
 * (commit suffixes such as `+be.53c0e999057f`) while keeping pre-release tags.
 */
export function formatComponentVersion(
  component: ReleaseComponent,
  version: string | undefined
): string | undefined {
  const core = version
    ?.trim()
    .replace(/\+.*$/, '')
    .replace(/^v(?=\d)/i, '')
  return core ? `${component}-${core}` : undefined
}
