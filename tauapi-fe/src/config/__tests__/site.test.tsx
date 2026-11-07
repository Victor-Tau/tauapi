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
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { cleanup, render, renderHook, screen } from '@testing-library/react'
import type { ReactNode } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'

import { siteConfig } from '@/config/site'
import { LegalConsent } from '@/features/auth/components/legal-consent'
import { useChatPresets } from '@/features/chat/hooks/use-chat-presets'
import {
  useApiInfo,
  useDashboardContentVisibility,
} from '@/features/dashboard/hooks/use-status-data'
import { useHomePageContent } from '@/features/home/hooks/use-home-page-content'
import { buildSetupPayload } from '@/features/setup/api'
import { useNotifications } from '@/hooks/use-notifications'
import { useSystemConfig } from '@/hooks/use-system-config'
import { useTopNavLinks } from '@/hooks/use-top-nav-links'
import { api } from '@/lib/api'
import { mapStatusDataToConfig } from '@/lib/status-query'
import { useSystemConfigStore } from '@/stores/system-config-store'

const initialSite = structuredClone(siteConfig)
afterEach(() => {
  cleanup()
  Object.assign(siteConfig, structuredClone(initialSite))
  useSystemConfigStore.setState(useSystemConfigStore.getInitialState(), true)
  vi.restoreAllMocks()
})

describe('frontend-owned presentation', () => {
  it('renders local branding and content without any backend request', () => {
    const get = vi.spyOn(api, 'get').mockRejectedValue(new Error('offline'))
    siteConfig.name = 'New API Console'
    siteConfig.notice = 'Local maintenance notice'
    siteConfig.homeContent = '# Local welcome'
    const { result } = renderHook(() => ({
      brand: useSystemConfig(),
      home: useHomePageContent(),
      notifications: useNotifications(),
      apiInfo: useApiInfo(),
      panels: useDashboardContentVisibility(),
      chats: useChatPresets(),
    }))
    expect(result.current.brand.systemName).toBe('New API Console')
    expect(result.current.brand.loading).toBe(false)
    expect(result.current.home).toMatchObject({
      content: '# Local welcome',
      isLoaded: true,
    })
    expect(result.current.notifications.notice).toBe('Local maintenance notice')
    expect(result.current.panels.uptimeKuma).toBe(false)
    expect(result.current.chats.chatPresets.length).toBeGreaterThan(0)
    expect(get).not.toHaveBeenCalled()
  })
  it('ignores legacy backend branding and navigation even when status is cached', () => {
    const client = new QueryClient({
      defaultOptions: { queries: { retry: false } },
    })
    client.setQueryData(['status'], {
      system_name: 'Remote name',
      logo: 'https://backend.example/logo.png',
      docs_link: 'https://backend.example',
      HeaderNavModules: { home: false, docs: false },
      public_resource_access: { pricing: { requireAuth: true } },
    })
    const { result } = renderHook(
      () => ({ brand: useSystemConfig(), links: useTopNavLinks() }),
      {
        wrapper: (props: { children: ReactNode }) => (
          <QueryClientProvider client={client}>
            {props.children}
          </QueryClientProvider>
        ),
      }
    )
    expect(result.current.brand.systemName).toBe(siteConfig.name)
    expect(result.current.brand.logo).toBe(siteConfig.logo)
    expect(result.current.links.some((link) => link.href === '/')).toBe(true)
    expect(
      result.current.links.find((link) => link.title === 'Docs')?.href
    ).toBe(siteConfig.docsUrl)
    expect(
      result.current.links.find((link) => link.href === '/pricing')
        ?.requiresAuth
    ).toBe(true)
    client.clear()
  })
  it('updates business conversion data without accepting remote presentation', () => {
    const mapped = mapStatusDataToConfig({
      system_name: 'Remote name',
      logo: '/remote.png',
      footer_html: '<p>Remote</p>',
      demo_site_enabled: true,
      quota_per_unit: 1000,
      usd_exchange_rate: 7,
    })
    expect(mapped).not.toHaveProperty('systemName')
    expect(mapped).not.toHaveProperty('logo')
    useSystemConfigStore.getState().setConfig(mapped)
    const { result } = renderHook(() => useSystemConfig())
    expect(result.current.currency.quotaPerUnit).toBe(1000)
    expect(result.current.currency.usdExchangeRate).toBe(7)
    expect(result.current.demoSiteEnabled).toBe(siteConfig.demoSiteEnabled)
  })
  it('initializes backend business mode without submitting presentation options', () => {
    const payload = buildSetupPayload(
      {
        username: 'root',
        password: 'Example-Password-123!',
        confirmPassword: 'Example-Password-123!',
        usageMode: 'self',
      },
      false
    )
    expect(payload).toMatchObject({
      username: 'root',
      SelfUseModeEnabled: true,
    })
    expect(payload).not.toHaveProperty('DemoSiteEnabled')
    expect(
      buildSetupPayload(
        {
          username: '',
          password: '',
          confirmPassword: '',
          usageMode: 'external',
        },
        true
      )
    ).toEqual({ SelfUseModeEnabled: false })
  })
  it('uses local legal content to show consent controls', () => {
    const { rerender } = render(
      <LegalConsent checked={false} onCheckedChange={vi.fn()} />
    )
    expect(screen.queryByRole('checkbox')).not.toBeInTheDocument()
    siteConfig.userAgreement = '# Local agreement'
    rerender(<LegalConsent checked={false} onCheckedChange={vi.fn()} />)
    expect(screen.getByRole('checkbox')).toBeInTheDocument()
    expect(
      screen.getByRole('link', { name: 'User Agreement' })
    ).toHaveAttribute('href', '/user-agreement')
  })
})
