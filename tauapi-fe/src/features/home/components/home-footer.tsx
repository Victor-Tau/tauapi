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
import { useTranslation } from 'react-i18next'

import {
  Footer,
  LegalLinks,
  ProjectAttribution,
} from '@/components/layout/components/footer'
import { useSystemConfig } from '@/hooks/use-system-config'

/** Dashed copyright footer from the Key Yi mockup; keeps legal links and New API attribution. */
export function HomeFooter() {
  const { t } = useTranslation()
  const { footerHtml } = useSystemConfig()
  const currentYear = new Date().getFullYear()

  if (footerHtml) {
    return <Footer />
  }

  return (
    <footer className='border-outline/40 mx-auto flex w-full max-w-4xl flex-col items-center gap-1 border-t border-dashed px-6 py-4 text-center text-xs'>
      <p className='font-brand text-muted-foreground m-0'>
        &copy; {currentYear} Auntie Key Studio. {t('footer.defaultCopyright')}
      </p>
      <div className='text-muted-foreground flex flex-wrap items-center justify-center gap-x-2 gap-y-1'>
        <ProjectAttribution currentYear={currentYear} inline />
        <LegalLinks leadingSeparator />
      </div>
    </footer>
  )
}
