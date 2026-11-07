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
import { siteConfig } from '@/config/site'

export function useApiInfo() {
  return {
    items: siteConfig.dashboard.apiInfoEnabled
      ? siteConfig.dashboard.apiInfo
      : [],
    loading: false,
  }
}
export function useAnnouncements() {
  return {
    items: siteConfig.dashboard.announcementsEnabled
      ? siteConfig.dashboard.announcements
      : [],
    loading: false,
  }
}
export function useFAQ() {
  return {
    items: siteConfig.dashboard.faqEnabled ? siteConfig.dashboard.faq : [],
    loading: false,
  }
}
export function useDashboardContentVisibility() {
  return {
    apiInfo: siteConfig.dashboard.apiInfoEnabled,
    announcements: siteConfig.dashboard.announcementsEnabled,
    faq: siteConfig.dashboard.faqEnabled,
    uptimeKuma: Boolean(siteConfig.dashboard.uptimeUrl),
  }
}
