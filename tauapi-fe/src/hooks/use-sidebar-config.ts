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
import { useMemo } from 'react'

import type { NavGroup, NavItem } from '@/components/layout/types'
import { siteConfig } from '@/config/site'
import { useAuthStore } from '@/stores/auth-store'
import { useSidebarPreferencesStore } from '@/stores/sidebar-preferences-store'

type SidebarSectionConfig = {
  enabled: boolean
  [key: string]: boolean
}

type SiteSidebarConfig = Record<string, SidebarSectionConfig>

// User-layer config is shape-identical to admin, but may be null
// to signal "no narrowing" (empty/invalid/legacy users).
type BrowserSidebarConfig = SiteSidebarConfig | null

/**
 * Mapping from URL to configuration keys
 */
const URL_TO_CONFIG_MAP: Record<string, { section: string; module: string }> = {
  '/playground': { section: 'chat', module: 'playground' },
  '/dashboard': { section: 'console', module: 'detail' },
  '/dashboard/overview': { section: 'console', module: 'detail' },
  '/dashboard/models': { section: 'console', module: 'detail' },
  '/dashboard/users': { section: 'console', module: 'detail' },
  '/keys': { section: 'console', module: 'token' },
  '/usage-logs': { section: 'console', module: 'log' },
  '/usage-logs/common': { section: 'console', module: 'log' },
  '/usage-logs/audit': { section: 'console', module: 'audit' },
  '/usage-logs/drawing': { section: 'console', module: 'midjourney' },
  '/usage-logs/task': { section: 'console', module: 'task' },
  '/wallet': { section: 'personal', module: 'topup' },
  '/profile': { section: 'personal', module: 'personal' },
  '/security': { section: 'personal', module: 'security' },
  '/channels': { section: 'admin', module: 'channel' },
  '/models': { section: 'admin', module: 'models' },
  '/models/metadata': { section: 'admin', module: 'models' },
  '/models/deployments': { section: 'admin', module: 'models' },
  '/users': { section: 'admin', module: 'user' },
  '/redemption-codes': { section: 'admin', module: 'redemption' },
  '/subscriptions': { section: 'admin', module: 'subscription' },
  '/system-settings': { section: 'admin', module: 'setting' },
  '/system-settings/site': { section: 'admin', module: 'setting' },
}

/**
 * Check if a module is enabled. Frontend config is the first
 * layer: if admin disables a section/module it is always hidden. User config
 * is a second narrower layer: it can only further hide what admin allowed.
 * A null user config means "do not narrow" (legacy/empty users).
 */
function isModuleEnabled(
  url: string,
  siteSidebar: SiteSidebarConfig,
  userConfig: BrowserSidebarConfig
): boolean {
  const mapping = URL_TO_CONFIG_MAP[url]
  if (!mapping) {
    // No mapping config, default to visible (e.g. system settings and new features)
    return true
  }

  const { section, module } = mapping
  const adminSection = siteSidebar[section]
  const adminAllowed = Boolean(
    adminSection && adminSection.enabled && adminSection[module] === true
  )
  if (!adminAllowed) return false

  if (!userConfig) return true

  const userSection = userConfig[section]
  if (!userSection) return true
  if (userSection.enabled === false) return false
  return userSection[module] !== false
}

/**
 * Check if a navigation item should be visible
 */
function isNavItemVisible(
  item: NavItem,
  siteSidebar: SiteSidebarConfig,
  userConfig: BrowserSidebarConfig
): boolean {
  // Handle dynamic chat presets type — also runs the frontend × browser AND gate
  if ('type' in item && item.type === 'chat-presets') {
    const adminChat = siteSidebar.chat
    const adminAllowed = Boolean(adminChat?.enabled && adminChat.chat === true)
    if (!adminAllowed) return false
    if (!userConfig) return true
    const userChat = userConfig.chat
    if (!userChat) return true
    if (userChat.enabled === false) return false
    return userChat.chat !== false
  }

  // Handle direct link type
  if ('url' in item && item.url) {
    const configUrls = item.configUrls ?? [item.url]
    return configUrls.some((url) =>
      isModuleEnabled(url as string, siteSidebar, userConfig)
    )
  }

  // Handle collapsible type (with sub-items)
  if ('items' in item && item.items) {
    // If has sub-items, show this collapsible item if at least one sub-item is visible
    return item.items.some((subItem) =>
      isModuleEnabled(subItem.url as string, siteSidebar, userConfig)
    )
  }

  return true
}

/**
 * Filter navigation items
 */
function filterNavItems(
  items: NavItem[],
  siteSidebar: SiteSidebarConfig,
  userConfig: BrowserSidebarConfig
): NavItem[] {
  return items
    .map((item) => {
      // If collapsible item, also filter its sub-items
      if ('items' in item && item.items) {
        const filteredSubItems = item.items.filter((subItem) =>
          isModuleEnabled(subItem.url as string, siteSidebar, userConfig)
        )

        return {
          ...item,
          items: filteredSubItems,
        }
      }
      return item
    })
    .filter((item) => isNavItemVisible(item, siteSidebar, userConfig))
}

/** Apply frontend navigation defaults and this browser's account preferences. */
export function useSidebarConfig(navGroups: NavGroup[]): NavGroup[] {
  const account = String(
    useAuthStore((state) => state.auth.user?.id) ?? 'anonymous'
  )
  const userConfig =
    useSidebarPreferencesStore((state) => state.accounts[account]) ?? null
  const siteSidebar = siteConfig.sidebar
  const filteredNavGroups = useMemo(
    () =>
      navGroups
        .map((group) => ({
          ...group,
          items: filterNavItems(group.items, siteSidebar, userConfig),
        }))
        .filter((group) => group.items.length > 0), // Only show navigation groups with visible items
    [navGroups, siteSidebar, userConfig]
  )

  return filteredNavGroups
}

/**
 * Check whether a single route is visible under the current browser-local sidebar
 * preferences. Used by entries living outside the sidebar (e.g. the profile
 * dropdown's wallet link) so they honour the same "wallet display" toggle.
 */
export function useIsSidebarModuleVisible(url: string): boolean {
  const account = String(
    useAuthStore((state) => state.auth.user?.id) ?? 'anonymous'
  )
  const userConfig =
    useSidebarPreferencesStore((state) => state.accounts[account]) ?? null
  return isModuleEnabled(url, siteConfig.sidebar, userConfig)
}
