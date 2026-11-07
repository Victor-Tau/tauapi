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
import type { QueryClient } from '@tanstack/react-query'

import { readCachedStatus, statusQueryOptions } from '@/lib/status-query'

export type ModuleAccess = { enabled: boolean; requireAuth: boolean }

export type PublicResource = 'rankings' | 'pricing'

const DEFAULTS: Record<PublicResource, ModuleAccess> = {
  pricing: { enabled: true, requireAuth: false },
  rankings: { enabled: true, requireAuth: false },
}

export function parseAccessBoolean(raw: unknown, fallback: boolean): boolean {
  if (typeof raw === 'boolean') return raw
  if (typeof raw === 'number') {
    if (raw === 1) return true
    if (raw === 0) return false
    return fallback
  }
  if (typeof raw === 'string') {
    const normalized = raw.trim().toLowerCase()
    if (normalized === 'true' || normalized === '1') return true
    if (normalized === 'false' || normalized === '0') return false
  }
  return fallback
}

function parseAccess(raw: unknown, fallback: ModuleAccess): ModuleAccess {
  if (
    typeof raw === 'boolean' ||
    typeof raw === 'number' ||
    typeof raw === 'string'
  ) {
    return {
      enabled: parseAccessBoolean(raw, fallback.enabled),
      requireAuth: fallback.requireAuth,
    }
  }
  if (raw && typeof raw === 'object') {
    const r = raw as Record<string, unknown>
    return {
      enabled: parseAccessBoolean(r.enabled, fallback.enabled),
      requireAuth: parseAccessBoolean(r.requireAuth, fallback.requireAuth),
    }
  }
  return { ...fallback }
}

function parseAccessRecord(raw: unknown): Record<string, unknown> | null {
  if (!raw || String(raw).trim() === '') return null
  if (raw && typeof raw === 'object') return raw as Record<string, unknown>

  try {
    return JSON.parse(String(raw)) as Record<string, unknown>
  } catch {
    return null
  }
}

export function getModuleAccessFromStatus(
  status: Record<string, unknown> | null,
  module: PublicResource
): ModuleAccess {
  const policies = parseAccessRecord(status?.public_resource_access)
  return parseAccess(policies?.[module], DEFAULTS[module])
}

/**
 * Read module access synchronously from the persisted status snapshot.
 *
 * For render paths that cannot await, such as deciding whether to show a nav
 * item. Never issues a request; use {@link getModuleAccessForGuard} when the
 * caller can await.
 */
export function getModuleAccess(module: PublicResource): ModuleAccess {
  return getModuleAccessFromStatus(readCachedStatus(), module)
}

/**
 * Resolve module access for a router `beforeLoad` guard.
 *
 * Reads through the shared `['status']` cache, so a guard on a fresh page load
 * reuses the request already started during boot instead of issuing its own.
 *
 * Fresh entries resolve immediately. Stale or invalidated entries await a
 * shared refresh before deciding navigation; a background refresh cannot undo
 * a redirect already made by a guard. The backend still authorizes requests.
 *
 * On failure this fails closed, reporting the module as disabled and
 * auth-required.
 */
export async function getModuleAccessForGuard(
  queryClient: QueryClient,
  module: PublicResource
): Promise<ModuleAccess> {
  try {
    const status = await queryClient.fetchQuery(statusQueryOptions)
    return getModuleAccessFromStatus(status, module)
  } catch {
    return { enabled: false, requireAuth: true }
  }
}
