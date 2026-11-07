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

import { siteConfig } from '@/config/site'

import { PanelWrapper } from '../ui/panel-wrapper'

export function UptimePanel() {
  const { t } = useTranslation()
  return (
    <PanelWrapper
      title={t('Uptime')}
      empty={!siteConfig.dashboard.uptimeUrl}
      emptyMessage={t('No uptime monitoring configured')}
      height='h-80'
    >
      {siteConfig.dashboard.uptimeUrl && (
        <iframe
          src={siteConfig.dashboard.uptimeUrl}
          title={t('Uptime')}
          className='h-80 w-full border-0'
          sandbox='allow-scripts allow-popups'
        />
      )}
    </PanelWrapper>
  )
}
