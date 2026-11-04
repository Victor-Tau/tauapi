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
import { zodResolver } from '@hookform/resolvers/zod'
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import * as z from 'zod'

import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import {
  DEFAULT_SYSTEM_RELEASE_REPOSITORY,
  normalizeSystemReleaseRepository,
} from '@/features/system-update/releases'
import { SystemUpdateAction } from '@/features/system-update/system-update-action'
import { useStatus } from '@/hooks/use-status'
import { formatTimestamp } from '@/lib/format'

import { SettingsForm } from '../components/settings-form-layout'
import { SettingsPageFormActions } from '../components/settings-page-context'
import { SettingsSection } from '../components/settings-section'
import { useUpdateOption } from '../hooks/use-update-option'

const repositorySchema = z.object({
  SystemUpdateRepository: z
    .string()
    .refine((value) => normalizeSystemReleaseRepository(value) !== null, {
      message:
        'Enter a GitHub repository as owner/repo or https://github.com/owner/repo',
    }),
})

type RepositoryFormValues = z.infer<typeof repositorySchema>

type UpdateCheckerSectionProps = {
  repository?: string
  currentVersion?: string | null
  startTime?: number | null
}

export function UpdateCheckerSection(props: UpdateCheckerSectionProps) {
  const { t } = useTranslation()
  const { status } = useStatus()
  const updateOption = useUpdateOption()
  const savedRepository = props.repository ?? ''
  const form = useForm<RepositoryFormValues>({
    resolver: zodResolver(repositorySchema),
    defaultValues: { SystemUpdateRepository: savedRepository },
  })

  useEffect(() => {
    form.reset({ SystemUpdateRepository: savedRepository })
  }, [savedRepository, form])

  const onSubmit = async (values: RepositoryFormValues) => {
    const normalized =
      normalizeSystemReleaseRepository(values.SystemUpdateRepository) ?? ''
    if (normalized === savedRepository) {
      form.reset({ SystemUpdateRepository: normalized })
      return
    }
    await updateOption.mutateAsync({
      key: 'SystemUpdateRepository',
      value: normalized,
    })
  }

  const uptime = props.startTime
    ? formatTimestamp(props.startTime)
    : t('Unknown')
  const version = status?.version || props.currentVersion || t('Unknown')

  return (
    <SettingsSection title={t('System maintenance')}>
      <div className='space-y-6'>
        <div className='grid gap-4 md:grid-cols-2'>
          <div className='rounded-lg border p-4'>
            <div className='text-muted-foreground text-sm'>
              {t('Current version')}
            </div>
            <div className='text-lg font-semibold break-all'>{version}</div>
          </div>
          <div className='rounded-lg border p-4'>
            <div className='text-muted-foreground text-sm'>
              {t('Uptime since')}
            </div>
            <div className='text-lg font-semibold'>{uptime}</div>
          </div>
        </div>
        <Form {...form}>
          <SettingsForm onSubmit={form.handleSubmit(onSubmit)}>
            <SettingsPageFormActions
              onSave={form.handleSubmit(onSubmit)}
              isSaving={updateOption.isPending}
            />
            <FormField
              control={form.control}
              name='SystemUpdateRepository'
              render={({ field }) => (
                <FormItem>
                  <FormLabel>{t('Update source repository')}</FormLabel>
                  <FormControl>
                    <Input
                      placeholder={DEFAULT_SYSTEM_RELEASE_REPOSITORY}
                      autoComplete='off'
                      spellCheck={false}
                      {...field}
                    />
                  </FormControl>
                  <FormDescription>
                    {t(
                      'Public GitHub repository whose Releases are checked for updates (owner/repo or GitHub URL). Leave empty to use {{repository}}.',
                      { repository: DEFAULT_SYSTEM_RELEASE_REPOSITORY }
                    )}
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />
          </SettingsForm>
        </Form>
        <SystemUpdateAction compact={false} />
      </div>
    </SettingsSection>
  )
}
