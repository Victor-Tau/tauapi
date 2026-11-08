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

import { cn } from '@/lib/utils'

const INK = '#433534'
const ORANGE = '#FF9E4A'
const CREAM = '#FAF6F0'
const MINT = '#76BA99'
const HAIR = '#5C4B43'
const SKIN = '#FCE3D2'
const WOOD = '#E8C396'
const WOOD_DARK = '#D3A56D'

interface KeyYiStallIllustrationProps {
  className?: string
}

/** Key Yi street-stall illustration from the brand mockup (index_v1.0.html). */
export function KeyYiStallIllustration(props: KeyYiStallIllustrationProps) {
  const { t } = useTranslation()

  return (
    <div
      className={cn(
        'relative flex items-center justify-center',
        props.className
      )}
    >
      <div
        aria-hidden='true'
        className='keyyi-float font-brand absolute top-1/3 -right-4 rotate-10 text-3xl text-[#433534] opacity-80 dark:text-[#FAF6F0]'
      >
        {'{ '}
        <span className='keyyi-pulse text-primary inline-block px-0.5 text-xl'>
          :
        </span>
        {' }'}
      </div>
      <svg
        xmlns='http://www.w3.org/2000/svg'
        viewBox='0 0 200 200'
        role='img'
        aria-label={t('Auntie Key street stall illustration')}
        className='size-full drop-shadow-[0_10px_0_rgba(67,53,52,0.08)]'
      >
        <g>
          <rect
            x='154'
            y='125'
            width='14'
            height='18'
            fill={ORANGE}
            stroke={INK}
            strokeWidth='4'
            rx='2'
          />
          <path
            d='M160,102 Q150,113 155,125 Q165,125 160,102 Z'
            fill={MINT}
            stroke={INK}
            strokeWidth='3'
          />
          <path
            d='M160,102 Q169,113 164,125 C157,125 160,102 160,102 Z'
            fill={MINT}
            stroke={INK}
            strokeWidth='3'
          />
        </g>

        <rect x='44' y='33' width='6' height='67' fill={INK} />
        <rect x='150' y='33' width='6' height='67' fill={INK} />

        <g>
          <path
            d='M40,95 C32,110 30,140 35,155 L85,155 C90,140 88,110 80,95 Z'
            fill={ORANGE}
            stroke={INK}
            strokeWidth='5'
          />
          <path
            d='M44,110 L76,110 L74,155 L46,155 Z'
            fill={CREAM}
            stroke={INK}
            strokeWidth='4'
          />
          <path
            d='M46,98 L44,110 M74,98 L76,110'
            stroke={INK}
            strokeWidth='3'
          />
          <circle
            cx='50'
            cy='72'
            r='13'
            fill={HAIR}
            stroke={INK}
            strokeWidth='5'
          />
          <circle
            cx='65'
            cy='58'
            r='14'
            fill={HAIR}
            stroke={INK}
            strokeWidth='5'
          />
          <circle
            cx='80'
            cy='72'
            r='13'
            fill={HAIR}
            stroke={INK}
            strokeWidth='5'
          />
          <circle
            cx='65'
            cy='75'
            r='18'
            fill={SKIN}
            stroke={INK}
            strokeWidth='5'
          />
          <circle cx='57' cy='73' r='2.5' fill={INK} />
          <circle cx='71' cy='73' r='2.5' fill={INK} />
          <circle cx='52' cy='79' r='3' fill='#EE9B96' opacity='0.7' />
          <circle cx='76' cy='79' r='3' fill='#EE9B96' opacity='0.7' />
          <path
            d='M 61,79 Q 65,82 69,79'
            stroke={INK}
            strokeWidth='3'
            fill='none'
            strokeLinecap='round'
          />
          <circle
            cx='55'
            cy='62'
            r='7'
            fill={HAIR}
            stroke={INK}
            strokeWidth='4'
          />
          <circle
            cx='65'
            cy='60'
            r='7'
            fill={HAIR}
            stroke={INK}
            strokeWidth='4'
          />
          <circle
            cx='75'
            cy='62'
            r='7'
            fill={HAIR}
            stroke={INK}
            strokeWidth='4'
          />
          <path
            d='M36,102 Q30,115 42,118'
            stroke={INK}
            strokeWidth='5'
            fill='none'
            strokeLinecap='round'
          />
          <path
            d='M78,102 Q94,96 102,80'
            stroke={INK}
            strokeWidth='5'
            fill='none'
            strokeLinecap='round'
          />
          <circle
            cx='102'
            cy='78'
            r='5'
            fill={SKIN}
            stroke={INK}
            strokeWidth='4'
          />
        </g>

        <g transform='translate(13, 1)'>
          <g className='keyyi-key-swing'>
            <path
              d='M 94,62 C 86,62 82,72 89,78 L 94,83 L 99,78 C 106,72 102,62 94,62 Z'
              fill={ORANGE}
              stroke={INK}
              strokeWidth='4'
              strokeLinejoin='round'
            />
            <path
              d='M 94,66 C 90,66 88,71 91,74 L 94,77 L 97,74 C 100,71 98,66 94,66 Z'
              fill={CREAM}
              stroke={INK}
              strokeWidth='2'
            />
            <line
              x1='94'
              y1='83'
              x2='94'
              y2='98'
              stroke={INK}
              strokeWidth='4'
              strokeLinecap='round'
            />
            <line
              x1='94'
              y1='90'
              x2='100'
              y2='90'
              stroke={INK}
              strokeWidth='4'
              strokeLinecap='round'
            />
            <line
              x1='94'
              y1='95'
              x2='98'
              y2='95'
              stroke={INK}
              strokeWidth='4'
              strokeLinecap='round'
            />
            <circle
              className='keyyi-sparkle'
              cx='82'
              cy='60'
              r='3'
              fill={ORANGE}
              opacity='0.8'
            />
            <circle
              className='keyyi-sparkle'
              cx='108'
              cy='72'
              r='2'
              fill={ORANGE}
              opacity='0.6'
              style={{ animationDelay: '0.8s' }}
            />
            <circle
              className='keyyi-sparkle'
              cx='102'
              cy='55'
              r='4'
              fill={ORANGE}
              opacity='0.5'
              style={{ animationDelay: '1.5s' }}
            />
          </g>
        </g>

        <g>
          <rect
            x='35'
            y='105'
            width='130'
            height='65'
            fill={WOOD}
            stroke={INK}
            strokeWidth='6'
            rx='4'
          />
          <line
            x1='65'
            y1='105'
            x2='65'
            y2='170'
            stroke={INK}
            strokeWidth='3'
            opacity='0.4'
          />
          <line
            x1='100'
            y1='105'
            x2='100'
            y2='170'
            stroke={INK}
            strokeWidth='3'
            opacity='0.4'
          />
          <line
            x1='135'
            y1='105'
            x2='135'
            y2='170'
            stroke={INK}
            strokeWidth='3'
            opacity='0.4'
          />
          <rect
            x='38'
            y='122'
            width='18'
            height='24'
            fill={WOOD_DARK}
            stroke={INK}
            strokeWidth='4'
            rx='2'
          />
          <path
            d='M41,122 Q47,112 47,122 Z'
            fill={MINT}
            stroke={INK}
            strokeWidth='2'
          />
          <path
            d='M47,122 Q53,112 53,122 Z'
            fill={MINT}
            stroke={INK}
            strokeWidth='2'
          />
          <circle
            cx='55'
            cy='170'
            r='16'
            fill={ORANGE}
            stroke={INK}
            strokeWidth='5'
          />
          <circle
            cx='55'
            cy='170'
            r='4'
            fill={CREAM}
            stroke={INK}
            strokeWidth='3'
          />
          <circle
            cx='145'
            cy='170'
            r='16'
            fill={ORANGE}
            stroke={INK}
            strokeWidth='5'
          />
          <circle
            cx='145'
            cy='170'
            r='4'
            fill={CREAM}
            stroke={INK}
            strokeWidth='3'
          />
          <rect
            x='22'
            y='95'
            width='151'
            height='10'
            fill={WOOD}
            stroke={INK}
            strokeWidth='6'
            rx='5'
          />
          <rect
            x='126'
            y='85'
            width='12'
            height='10'
            fill={ORANGE}
            stroke={INK}
            strokeWidth='3'
            rx='1'
          />
          <path
            d='M132,85 Q127,77 130,77 Q135,77 132,85 Z'
            fill={MINT}
            stroke={INK}
            strokeWidth='2'
          />
          <rect
            x='65'
            y='118'
            width='70'
            height='28'
            fill={CREAM}
            stroke={INK}
            strokeWidth='4'
            rx='3'
          />
          <text
            x='100'
            y='137'
            fontFamily='var(--font-brand)'
            fontSize='13'
            fontWeight='bold'
            fill={INK}
            textAnchor='middle'
          >
            KeyYi
          </text>
        </g>

        <g>
          <path
            d='M22,38 L45,3 L155,3 L178,38 Z'
            fill={CREAM}
            stroke={INK}
            strokeWidth='6'
            strokeLinejoin='round'
          />
          <path d='M48,3 L32,38 L54,38 L70,3 Z' fill={ORANGE} />
          <path d='M90,3 L78,38 L100,38 L112,3 Z' fill={ORANGE} />
          <path d='M132,3 L124,38 L146,38 L154,3 Z' fill={ORANGE} />
          <path
            d='M23,38 A11,11 0 0,0 45,38 A11,11 0 0,0 67,38 A11,11 0 0,0 89,38 A11,11 0 0,0 111,38 A11,11 0 0,0 133,38 A11,11 0 0,0 155,38 A11,11 0 0,0 177,38'
            fill={CREAM}
            stroke={INK}
            strokeWidth='6'
            strokeLinecap='round'
            strokeLinejoin='round'
          />
        </g>
      </svg>
    </div>
  )
}

/** Key glyph used on the primary landing call to action. */
export function KeyYiKeyIcon(props: { className?: string }) {
  return (
    <svg
      xmlns='http://www.w3.org/2000/svg'
      viewBox='0 0 64 64'
      fill='none'
      aria-hidden='true'
      className={props.className}
    >
      <path
        d='M 32 10 C 18 10 12 24 22 34 L 32 44 L 42 34 C 52 24 46 10 32 10 Z'
        fill={CREAM}
        stroke={INK}
        strokeWidth='5'
        strokeLinejoin='round'
      />
      <line
        x1='32'
        y1='44'
        x2='32'
        y2='60'
        stroke={INK}
        strokeWidth='5'
        strokeLinecap='round'
      />
      <line
        x1='32'
        y1='52'
        x2='42'
        y2='52'
        stroke={INK}
        strokeWidth='5'
        strokeLinecap='round'
      />
      <line
        x1='32'
        y1='58'
        x2='38'
        y2='58'
        stroke={INK}
        strokeWidth='5'
        strokeLinecap='round'
      />
    </svg>
  )
}
