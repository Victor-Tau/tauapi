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
import type { RawChatConfig } from '@/features/chat/lib/chat-links'
import type {
  AnnouncementItem,
  ApiInfoItem,
  FAQItem,
} from '@/features/dashboard/types'

/** Presentation is bundled with the frontend and never read from API status. */
export const siteConfig = {
  name: 'Key姨',
  logo: '/logo.png',
  favicon: '/favicon.ico',
  footerHtml: '',
  docsUrl: 'https://docs.newapi.pro',
  releaseRepository: 'Victor-Tau/tauapi',
  homeContent: '',
  aboutContent: '',
  notice: '',
  userAgreement: '',
  privacyPolicy: '',
  demoSiteEnabled: false,
  displayTokenStatEnabled: true,
  navigation: {
    home: true,
    console: true,
    pricing: true,
    rankings: true,
    docs: true,
    about: true,
  },
  sidebar: {
    chat: {
      enabled: true,
      playground: true,
      chat: true,
    },
    console: {
      enabled: true,
      detail: true,
      token: true,
      log: true,
      audit: true,
      midjourney: true,
      task: true,
    },
    personal: {
      enabled: true,
      topup: true,
      personal: true,
      security: true,
    },
    admin: {
      enabled: true,
      channel: true,
      models: true,
      redemption: true,
      user: true,
      setting: true,
      subscription: true,
    },
  },
  dashboard: {
    apiInfoEnabled: true,
    announcementsEnabled: true,
    faqEnabled: true,
    uptimeUrl: '',
    apiInfo: [] as ApiInfoItem[],
    announcements: [] as AnnouncementItem[],
    faq: [] as FAQItem[],
  },
  chats: [
    {
      'Cherry Studio':
        'cherrystudio://providers/api-keys?v=1&data={cherryConfig}',
    },
    {
      AionUI: 'aionui://provider/add?v=1&data={aionuiConfig}',
    },
    {
      流畅阅读: 'fluentread',
    },
    {
      'CC Switch': 'ccswitch',
    },
    {
      DeepChat: 'deepchat://provider/install?v=1&data={deepchatConfig}',
    },
    {
      AQBot: 'aqbot://providers?{aqbotConfig}',
    },
    {
      'Lobe Chat 官方示例':
        'https://chat-preview.lobehub.com/?settings={"keyVaults":{"openai":{"apiKey":"{key}","baseURL":"{address}/v1"}}}',
    },
    {
      'AI as Workspace':
        'https://aiaw.app/set-provider?provider={"type":"openai","settings":{"apiKey":"{key}","baseURL":"{address}/v1","compatibility":"strict"}}',
    },
    {
      'AMA 问天': 'ama://set-api-key?server={address}&key={key}',
    },
    {
      OpenCat: 'opencat://team/join?domain={address}&token={key}',
    },
  ] as RawChatConfig,
}
