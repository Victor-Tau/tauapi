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
  formatComponentVersion,
  getFrontendVersion,
} from '@/lib/component-versions'

type ComponentVersionsProps = {
  backendVersion?: string
}

export function ComponentVersions(props: ComponentVersionsProps) {
  const { t } = useTranslation()
  const frontendVersion =
    formatComponentVersion('fe', getFrontendVersion()) || t('Unknown version')
  const backendVersion =
    formatComponentVersion('be', props.backendVersion) || t('Unknown version')
  return (
    <span className='grid min-w-0 gap-0.5 text-start text-xs leading-tight'>
      <span className='flex min-w-0 gap-1'>
        <span className='shrink-0'>{t('Frontend version')}:</span>
        <span className='max-w-32 truncate font-mono' title={frontendVersion}>
          {frontendVersion}
        </span>
      </span>
      <span className='flex min-w-0 gap-1'>
        <span className='shrink-0'>{t('Backend version')}:</span>
        <span className='max-w-32 truncate font-mono' title={backendVersion}>
          {backendVersion}
        </span>
      </span>
    </span>
  )
}
