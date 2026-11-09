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
import {
  createMemoryHistory,
  createRootRoute,
  createRouter,
  RouterProvider,
} from '@tanstack/react-router'
import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, expect, test } from 'vitest'

import { siteConfig } from '@/config/site'

import { HomeFooter } from '../home-footer'

const initialFooterHtml = siteConfig.footerHtml
const initialUserAgreement = siteConfig.userAgreement

afterEach(() => {
  cleanup()
  siteConfig.footerHtml = initialFooterHtml
  siteConfig.userAgreement = initialUserAgreement
})

function renderFooter() {
  const root = createRootRoute({ component: () => <HomeFooter /> })
  const router = createRouter({
    routeTree: root,
    history: createMemoryHistory({ initialEntries: ['/'] }),
  })
  return render(<RouterProvider router={router} />)
}

test('mockup footer keeps the New API attribution and legal links', async () => {
  siteConfig.footerHtml = ''
  siteConfig.userAgreement = 'terms'
  renderFooter()

  expect(
    await screen.findByText(/Auntie Key Studio\. footer\.defaultCopyright/)
  ).toBeInTheDocument()
  expect(screen.getByRole('link', { name: 'New API' })).toHaveAttribute(
    'href',
    'https://github.com/QuantumNous/new-api'
  )
  expect(screen.getByRole('link', { name: 'User Agreement' })).toHaveAttribute(
    'href',
    '/user-agreement'
  )
})

test('configured footer HTML falls back to the shared footer', async () => {
  siteConfig.footerHtml = '<span>Custom footer</span>'
  renderFooter()

  expect(await screen.findByText('Custom footer')).toBeInTheDocument()
  expect(screen.queryByText(/Auntie Key Studio/)).not.toBeInTheDocument()
})
