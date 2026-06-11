<template>
  <UContainer class="py-10 space-y-8">
    <div class="border-b border-gray-200 dark:border-gray-800 pb-4">
      <h1 class="text-3xl font-bold tracking-tight">
        Observability & Diagnostics Dashboard
      </h1>
      <p class="text-gray-500 mt-1">
        Simulate application events, inspect live PII cleansing frameworks, and view real-time operations queries.
      </p>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      <UCard>
        <template #header>
          <div class="font-semibold text-lg text-gray-900 dark:text-white">
            Citizen Interface Simulation
          </div>
        </template>

        <div class="space-y-4">
          <p class="text-sm text-gray-600 dark:text-gray-400">
            Interact with the triggers below to generate contextual diagnostic outputs:
          </p>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <UButton
              color="neutral"
              variant="subtle"
              label="Emit Standard Audit Log"
              @click="triggerNormalLog"
            />
            <UButton
              color="warning"
              variant="subtle"
              label="Emit Sensitive Log (PII)"
              @click="triggerSensitiveLog"
            />
            <UButton
              color="error"
              variant="subtle"
              label="Throw Application Exception"
              @click="triggerVueError"
            />
            <UButton
              color="neutral"
              variant="solid"
              label="Reject Async Promise"
              @click="triggerPromiseRejection"
            />
            <UButton
              class="sm:col-span-2"
              color="error"
              variant="solid"
              label="Show System Error Page"
              @click="triggerShowErrorPage"
            />
          </div>

          <div
            v-if="activeSupportCode"
            class="mt-6 p-4 bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-900 rounded-lg"
          >
            <div class="flex items-center space-x-2 text-red-800 dark:text-red-400 font-medium text-sm">
              <span>⚠️ Critical Unhandled Failure Encountered</span>
            </div>
            <p class="text-xs text-red-700 dark:text-red-300 mt-1">
              The system safely cached this instance. Please provide this support ticket signature to administration:
            </p>
            <div class="font-mono text-xl font-bold mt-2 tracking-wider text-red-900 dark:text-red-200">
              {{ activeSupportCode }}
            </div>
          </div>
        </div>
      </UCard>

      <UCard>
        <template #header>
          <div class="font-semibold text-lg text-gray-900 dark:text-white">
            Cloud Operations Center
          </div>
        </template>

        <div class="space-y-4">
          <div>
            <div class="text-xs font-semibold uppercase tracking-wider text-gray-400">
              Active Telemetry Session Token
            </div>
            <div class="font-mono text-sm bg-gray-100 dark:bg-gray-800 p-2 rounded mt-1 overflow-x-auto">
              {{ activeSessionId || 'Establishing session...' }}
            </div>
          </div>

          <div class="space-y-2">
            <div class="text-xs font-semibold uppercase tracking-wider text-gray-400">
              Target Google Cloud Logging Query
            </div>
            <p class="text-xs text-gray-500">
              Execute this block inside the Google Log Explorer dashboard to map the chronological history of this individual session:
            </p>

            <div class="relative group">
              <pre class="bg-gray-900 text-emerald-400 p-4 rounded-lg font-mono text-xs overflow-x-auto whitespace-pre-wrap leading-relaxed shadow-inner border border-gray-800">{{ logQuery }}</pre>
            </div>
          </div>
        </div>
      </UCard>
    </div>
  </UContainer>
</template>

<script setup>
const { $log } = useNuxtApp()
const activeSessionId = ref('')
const activeSupportCode = ref('')

onMounted(() => {
  activeSessionId.value = sessionStorage.getItem('ops_session_id') || ''
})

const logQuery = computed(() => {
  const shortCode = activeSupportCode.value ? activeSupportCode.value.replace('ERR-', '') : 'XXXXXXXX'
  const sid = activeSessionId.value || 'your-session-uuid'
  return `resource.type="cloud_run_revision"\n(textPayload:"${shortCode}" OR jsonPayload.client_context.sessionId:"${sid}")`
})

const triggerNormalLog = () => {
  $log.info('Citizen advanced to step 3 of application process', { currentStep: 3, formType: 'Archaeological Permitting' })
}

const triggerSensitiveLog = () => {
  $log.warn('Citizen attempted to update profile metadata configurations', {
    email: 'thor.wolpert@example.ca',
    password: 'super-secret-password-123',
    billing: { creditCard: '4111-2222-3333-4444', zip: 'V8V 1X4' }
  })
}

const triggerVueError = () => {
  activeSupportCode.value = `ERR-${activeSessionId.value.split('-')[0].toUpperCase()}`
  throw new Error('Database integrity check failed during client form transmission.')
}

const triggerPromiseRejection = () => {
  activeSupportCode.value = `ERR-${activeSessionId.value.split('-')[0].toUpperCase()}`
  Promise.reject(new Error('Network response timed out on critical synchronization pipeline.'))
}

const triggerShowErrorPage = () => {
  const shortCode = activeSupportCode.value || `ERR-${(activeSessionId.value || sessionStorage.getItem('ops_session_id') || '').split('-')[0].toUpperCase()}`
  activeSupportCode.value = shortCode

  $log.error('Forced application exception from dashboard.', { supportCode: shortCode })

  showError({
    statusCode: 500,
    statusMessage: 'Forced application exception from dashboard.',
    data: {
      supportCode: shortCode
    }
  })
}
</script>
