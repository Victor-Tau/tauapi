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
import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import { toast } from 'sonner'

const CHECK_INTERVAL_MS = 5 * 60 * 1000
const VERSION_ENDPOINT = '/_meta/ui-version.json'
const NOTICE_ID = 'frontend-release-update'

/** Release id baked into this bundle by the release build (empty in dev). */
const BUNDLE_RELEASE_ID: string = import.meta.env.TAUAPI_RELEASE_ID ?? ''

/**
 * Tells the user when a newer frontend release is live. It never reloads on
 * its own: the page keeps running on its own versioned /_ui/<release>/ assets
 * (kept by the release retention policy), so forms in progress, payments and
 * streaming responses are not interrupted. The user refreshes when convenient.
 */
export function useReleaseUpdateNotice(): void {
  const { t } = useTranslation()

  useEffect(() => {
    if (!BUNDLE_RELEASE_ID) return
    let notified = false
    let stopped = false

    const check = async () => {
      if (notified || stopped || document.visibilityState !== 'visible') return
      try {
        const response = await fetch(VERSION_ENDPOINT, { cache: 'no-store' })
        if (!response.ok) return
        const body = (await response.json()) as { release_id?: unknown }
        const liveRelease = typeof body.release_id === 'string' ? body.release_id : ''
        if (!liveRelease || liveRelease === BUNDLE_RELEASE_ID || stopped) return
        notified = true
        toast.info(t('A new version is available. Refresh when convenient.'), {
          id: NOTICE_ID,
          duration: Number.POSITIVE_INFINITY,
          action: {
            label: t('Refresh'),
            onClick: () => window.location.reload(),
          },
        })
      } catch {
        // Version polling is best effort; network errors are ignored.
      }
    }

    const timer = window.setInterval(check, CHECK_INTERVAL_MS)
    document.addEventListener('visibilitychange', check)
    return () => {
      stopped = true
      window.clearInterval(timer)
      document.removeEventListener('visibilitychange', check)
    }
  }, [t])
}
