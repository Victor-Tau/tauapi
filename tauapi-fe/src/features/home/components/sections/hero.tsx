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
import { Link } from '@tanstack/react-router'
import { useTranslation } from 'react-i18next'

import { Button } from '@/components/ui/button'

import {
  KeyYiKeyIcon,
  KeyYiStallIllustration,
} from '../keyyi-stall-illustration'

interface HeroProps {
  isAuthenticated?: boolean
}

/** Landing hero reproduced from the Key Yi brand mockup (index_v1.0.html). */
export function Hero(props: HeroProps) {
  const { t } = useTranslation()

  return (
    <section className='flex flex-1 flex-col items-center justify-center px-6 pt-24 pb-10 text-center select-none md:pt-28'>
      <div className='border-outline shadow-sticker-sm mb-6 inline-flex items-center gap-2.5 rounded-full border-2 bg-(--brand-mint-soft) px-5 py-2 text-sm font-semibold tracking-wider text-(--brand-mint-ink) md:px-6 md:py-2.5 md:text-base'>
        <span
          aria-hidden='true'
          className='keyyi-pulse border-outline inline-block size-3 rounded-full border-2 bg-(--brand-mint)'
        />
        <span>{t('Auntie Key is open for business today!')}</span>
      </div>

      <KeyYiStallIllustration className='mb-6 size-72 md:size-80' />

      <h1 className='font-brand mb-4 text-3xl leading-tight tracking-wider md:text-5xl'>
        {t("Drop by Auntie Key's stall,")}
        <br className='md:hidden' /> {t('and grab a steaming bowl of')}{' '}
        <span className='decoration-primary underline decoration-wavy decoration-3 underline-offset-6'>
          API
        </span>
      </h1>

      <p className='font-brand text-muted-foreground mb-10 text-sm tracking-widest uppercase md:text-base'>
        — {t('API Relay for Everyone')} —
      </p>

      <Button
        size='lg'
        className='shadow-sticker-lg hover:shadow-sticker-lg h-16 gap-3 border-4 px-12 text-xl font-black tracking-wider md:text-2xl'
        render={<Link to={props.isAuthenticated ? '/wallet' : '/sign-up'} />}
      >
        <KeyYiKeyIcon className='size-6 transition-transform group-hover/button:-rotate-12 motion-reduce:transition-none' />
        {t('Buy a key from Auntie Key')}
      </Button>

      <span className='text-muted-foreground mt-6 text-sm font-medium tracking-wide'>
        <span aria-hidden='true'>✨ </span>
        {t('Pure relay · Usage-based billing')}
      </span>
    </section>
  )
}
