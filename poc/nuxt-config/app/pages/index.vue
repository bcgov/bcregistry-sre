<script setup lang="ts">
import type { TableColumn } from '@nuxt/ui'

const config = useRuntimeConfig()
const syncStatus = useState('syncStatus')
const syncHistory = useState<{ status: string, timestamp: string }[]>('syncHistory')

const columns: TableColumn<{ status: string, timestamp: string }>[] = [{
  accessorKey: 'timestamp',
  header: 'Time'
}, {
  accessorKey: 'status',
  header: 'Status'
}]
</script>

<template>
  <UContainer class="py-12">
    <UPageHero
      title="Nuxt Config Loader"
      description="Static site is loaded in every environment (dev|test|prod) and the config is served from common 'local' api"
    />

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-12">
      <!-- Runtime Configuration Card -->
      <UCard>
        <template #header>
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold">
              Runtime Configuration
            </h3>
            <UBadge
              :color="syncStatus === 'loaded' ? 'success' : 'warning'"
              variant="subtle"
            >
              {{ syncStatus }}
            </UBadge>
          </div>
        </template>

        <div class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p class="text-sm font-medium text-gray-500 dark:text-gray-400">
                Analytics ID
              </p>
              <p class="font-mono">
                {{ config.public.analyticsId || 'Loading...' }}
              </p>
            </div>
            <div>
              <p class="text-sm font-medium text-gray-500 dark:text-gray-400">
                Firebase Client ID
              </p>
              <p class="font-mono">
                {{ config.public.firebaseClientId || 'Loading...' }}
              </p>
            </div>
          </div>
        </div>
      </UCard>

      <!-- Sync History Card -->
      <UCard>
        <template #header>
          <h3 class="text-lg font-semibold">
            Sync History
          </h3>
        </template>

        <UTable
          :data="syncHistory"
          :columns="columns"
        />
      </UCard>
    </div>
  </UContainer>
</template>
