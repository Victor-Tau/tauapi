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
import { render, screen } from '@testing-library/react'
import { expect, test } from 'vitest'

import { Hero } from '../sections/hero'

// Button renders router links as anchors with role="button" (Base UI
// non-native button), so calls to action are queried by that role.
function renderHero(isAuthenticated: boolean) {
  const root = createRootRoute({
    component: () => <Hero isAuthenticated={isAuthenticated} />,
  })
  const router = createRouter({
    routeTree: root,
    history: createMemoryHistory({ initialEntries: ['/'] }),
  })
  return render(<RouterProvider router={router} />)
}

test('anonymous visitor is sent to sign-up by the single call to action', async () => {
  renderHero(false)

  const cta = await screen.findByRole('button', {
    name: 'Buy a key from Auntie Key',
  })
  expect(cta).toHaveAttribute('href', '/sign-up')
  expect(screen.getAllByRole('button')).toHaveLength(1)
})

test('signed-in user buys a key from the wallet page', async () => {
  renderHero(true)

  const cta = await screen.findByRole('button', {
    name: 'Buy a key from Auntie Key',
  })
  expect(cta).toHaveAttribute('href', '/wallet')
  expect(screen.getAllByRole('button')).toHaveLength(1)
})

test('stall illustration and open status are exposed to assistive technology', async () => {
  renderHero(false)

  expect(
    await screen.findByRole('img', {
      name: 'Auntie Key street stall illustration',
    })
  ).toBeInTheDocument()
  expect(
    screen.getByText('Auntie Key is open for business today!')
  ).toBeVisible()
  expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent(
    "Drop by Auntie Key's stall, and grab a steaming bowl of API"
  )
})
