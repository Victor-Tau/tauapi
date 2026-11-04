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
import type { Transition, Variants } from 'motion/react'

const EASE_OUT_CUBIC = [0.33, 1, 0.68, 1] as const

// Minimalist Flat: motion is limited to short opacity fades (no blur, slide,
// scale or springs). Export names and shapes are unchanged for callers;
// components still honour prefers-reduced-motion via useReducedMotion.
const DURATION = {
  instant: 0,
  fast: 0.12,
  normal: 0.15,
  slow: 0.2,
} as const

export const MOTION_TRANSITION: Record<string, Transition> = {
  default: { duration: DURATION.normal, ease: EASE_OUT_CUBIC },
  fast: { duration: DURATION.fast, ease: EASE_OUT_CUBIC },
  slow: { duration: DURATION.slow, ease: EASE_OUT_CUBIC },
  spring: { duration: DURATION.normal, ease: EASE_OUT_CUBIC },
  none: { duration: DURATION.instant },
}

const FADE = {
  initial: { opacity: 0 },
  animate: { opacity: 1 },
  exit: { opacity: 0 },
} as const

export const MOTION_VARIANTS = {
  pageEnter: FADE,
  fadeIn: FADE,
  scaleIn: FADE,
  slideUp: FADE,
  slideDown: FADE,
  tableRow: { initial: FADE.initial, animate: FADE.animate },
  cardItem: { initial: FADE.initial, animate: FADE.animate },
  sidebarSlide: FADE,
} as const

export const STAGGER_VARIANTS: Variants = {
  initial: {},
  animate: {},
}

export const STAGGER_ITEM_VARIANTS: Variants = {
  initial: { opacity: 0 },
  animate: { opacity: 1, transition: MOTION_TRANSITION.default },
}

export const TABLE_STAGGER_VARIANTS: Variants = {
  initial: {},
  animate: {},
}

export const TABLE_ROW_VARIANTS: Variants = {
  initial: { opacity: 0 },
  animate: { opacity: 1, transition: MOTION_TRANSITION.fast },
}

export const CARD_STAGGER_VARIANTS: Variants = {
  initial: {},
  animate: {},
}

export const CARD_ITEM_VARIANTS: Variants = {
  initial: { opacity: 0 },
  animate: { opacity: 1, transition: MOTION_TRANSITION.default },
}

export const SIDEBAR_STAGGER_VARIANTS: Variants = {
  initial: {},
  animate: {},
}

export const SIDEBAR_ITEM_VARIANTS: Variants = {
  initial: { opacity: 0 },
  animate: { opacity: 1, transition: MOTION_TRANSITION.fast },
}
