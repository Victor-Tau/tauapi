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
import { CherryStudio } from '@lobehub/icons'
import { Link } from '@tanstack/react-router'
import { BookOpen } from 'lucide-react'
import { useTranslation } from 'react-i18next'

import { Button } from '@/components/ui/button'
import { siteConfig } from '@/config/site'

import { HeroTerminalDemo } from '../hero-terminal-demo'
import {
  KeyYiKeyIcon,
  KeyYiStallIllustration,
} from '../keyyi-stall-illustration'

interface HeroProps {
  className?: string
  isAuthenticated?: boolean
}

// Stylized three-dots indicator representing "More"
const MoreIcon = () => (
  <svg
    className='text-muted-foreground size-6 shrink-0'
    viewBox='0 0 24 24'
    fill='none'
    xmlns='http://www.w3.org/2000/svg'
  >
    <circle cx='6' cy='12' r='2' fill='currentColor' />
    <circle cx='12' cy='12' r='2' fill='currentColor' />
    <circle cx='18' cy='12' r='2' fill='currentColor' />
  </svg>
)

export function Hero(props: HeroProps) {
  const { t } = useTranslation()
  const docsUrl = siteConfig.docsUrl

  const renderDocsButton = () => {
    const isExternal = docsUrl.startsWith('http')
    if (isExternal) {
      return (
        <Button
          variant='outline'
          className='group inline-flex h-10 items-center gap-1.5 px-5 text-sm'
          render={
            <a href={docsUrl} target='_blank' rel='noopener noreferrer' />
          }
        >
          <BookOpen className='text-muted-foreground group-hover:text-foreground size-4 transition-colors duration-150' />
          <span>{t('Docs')}</span>
        </Button>
      )
    }
    return (
      <Button
        variant='outline'
        className='group inline-flex h-10 items-center gap-1.5 px-5 text-sm'
        render={<Link to={docsUrl} />}
      >
        <BookOpen className='text-muted-foreground group-hover:text-foreground size-4 transition-colors duration-150' />
        <span>{t('Docs')}</span>
      </Button>
    )
  }

  return (
    <section className='relative z-10 overflow-hidden px-6 pt-28 pb-16 md:pt-32 md:pb-24'>
      <div className='mx-auto flex max-w-3xl flex-col items-center text-center'>
        <div
          className='landing-animate-fade-up border-outline shadow-sticker-sm mb-4 inline-flex items-center gap-2.5 rounded-full border-2 bg-(--brand-mint-soft) px-5 py-2 text-sm font-semibold tracking-wider text-(--brand-mint-ink) opacity-0'
          style={{ animationDelay: '0ms' }}
        >
          <span
            aria-hidden='true'
            className='keyyi-pulse border-outline inline-block size-3 rounded-full border-2 bg-(--brand-mint)'
          />
          <span>{t('Auntie Key is open for business today!')}</span>
        </div>

        <KeyYiStallIllustration className='landing-animate-fade-up mb-6 size-64 opacity-0 select-none md:size-80' />

        <h1
          className='landing-animate-fade-up font-brand text-3xl leading-tight tracking-wider opacity-0 md:text-5xl'
          style={{ animationDelay: '60ms' }}
        >
          {t("Drop by Auntie Key's stall,")}
          <br className='md:hidden' /> {t('and grab a steaming bowl of')}{' '}
          <span className='decoration-primary underline decoration-wavy decoration-3 underline-offset-6'>
            API
          </span>
        </h1>
        <p
          className='landing-animate-fade-up font-brand text-muted-foreground mt-4 text-sm tracking-widest uppercase opacity-0 md:text-base'
          style={{ animationDelay: '120ms' }}
        >
          — {t('API Relay for Everyone')} —
        </p>
        <p
          className='landing-animate-fade-up text-muted-foreground mt-5 max-w-xl text-base leading-relaxed opacity-0'
          style={{ animationDelay: '150ms' }}
        >
          {t(
            'Access a vast selection of models via a standard, unified API protocol. Power AI applications, manage digital assets, and connect the Future.'
          )}
        </p>

        <div
          className='landing-animate-fade-up mt-9 flex flex-wrap items-center justify-center gap-4 opacity-0'
          style={{ animationDelay: '180ms' }}
        >
          {props.isAuthenticated ? (
            <Button
              size='lg'
              className='h-14 gap-3 border-[3px] px-9 text-lg tracking-wider md:text-xl'
              render={<Link to='/dashboard' />}
            >
              <KeyYiKeyIcon className='size-6' />
              {t('Go to Dashboard')}
            </Button>
          ) : (
            <Button
              size='lg'
              className='h-14 gap-3 border-[3px] px-9 text-lg tracking-wider md:text-xl'
              render={<Link to='/sign-up' />}
            >
              <KeyYiKeyIcon className='size-6' />
              {t('Buy a key from Auntie Key')}
            </Button>
          )}
          {!props.isAuthenticated && (
            <Button
              variant='outline'
              className='h-10 px-5 text-sm'
              render={<Link to='/pricing' />}
            >
              {t('View Pricing')}
            </Button>
          )}
          {renderDocsButton()}
        </div>

        <span
          className='landing-animate-fade-up text-muted-foreground mt-6 text-sm font-medium tracking-wide opacity-0'
          style={{ animationDelay: '240ms' }}
        >
          <span aria-hidden='true'>✨ </span>
          {t('Pure relay · Usage-based billing')}
        </span>
      </div>

      <div className='mx-auto mt-20 grid max-w-6xl grid-cols-1 items-center gap-12 lg:grid-cols-12 lg:gap-8'>
        {/* Supported applications */}
        <div
          className='landing-animate-fade-up w-full opacity-0 lg:col-span-5'
          style={{ animationDelay: '300ms' }}
        >
          <div className='mb-4 flex flex-col gap-1'>
            <span className='font-brand text-foreground text-base tracking-wide'>
              {t('Supported Applications')}
            </span>
            <p className='text-muted-foreground text-xs leading-relaxed'>
              {t(
                'Supports one-click configuration and perfectly adapts to NewAPI multi-protocol configuration.'
              )}
            </p>
          </div>
          <div className='flex flex-wrap items-center gap-3'>
            {/* Cherry Studio */}
            <a
              href='https://cherry-ai.com'
              target='_blank'
              rel='noopener noreferrer'
              className='bg-card text-foreground hover:bg-accent border-outline shadow-sticker-sm flex items-center gap-3 rounded-full border-2 px-4 py-2 text-sm font-medium transition-colors duration-150'
            >
              <CherryStudio.Color size={24} className='shrink-0' />
              <span>Cherry Studio</span>
            </a>

            {/* CC Switch */}
            <a
              href='https://ccswitch.io'
              target='_blank'
              rel='noopener noreferrer'
              className='bg-card text-foreground hover:bg-accent border-outline shadow-sticker-sm flex items-center gap-3 rounded-full border-2 px-4 py-2 text-sm font-medium transition-colors duration-150'
            >
              <img
                src='https://ccswitch.io/favicon.png'
                alt='CC Switch'
                className='size-6 shrink-0 rounded-full object-contain'
                onError={(e) => {
                  // Fallback to a styled text avatar if the remote favicon fails to load in sandbox or local environments
                  e.currentTarget.style.display = 'none'
                  const fallback = e.currentTarget.nextSibling as HTMLElement
                  if (fallback) fallback.style.display = 'flex'
                }}
              />
              <span
                style={{ display: 'none' }}
                className='bg-muted text-muted-foreground size-6 shrink-0 items-center justify-center rounded-full text-[10px] font-semibold'
              >
                CC
              </span>
              <span>CC Switch</span>
            </a>

            {/* "更多" */}
            <div className='group bg-card text-muted-foreground border-outline/40 flex cursor-default items-center gap-2.5 rounded-full border-2 border-dashed px-4 py-2 text-sm font-medium'>
              <MoreIcon />
              <span>{t('More Apps')}</span>
            </div>
          </div>
        </div>

        {/* Live API demo */}
        <div
          className='landing-animate-fade-up flex w-full justify-center opacity-0 lg:col-span-7'
          style={{ animationDelay: '360ms' }}
        >
          <HeroTerminalDemo />
        </div>
      </div>
    </section>
  )
}
