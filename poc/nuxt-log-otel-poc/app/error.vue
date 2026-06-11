<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 p-6">
    <UCard class="max-w-md w-full shadow-xl">
      <div class="text-center space-y-4">
        <div class="inline-flex p-3 bg-red-100 dark:bg-red-950 text-red-600 dark:text-red-400 rounded-full">
          <svg
            class="w-8 h-8"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          ><path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
          /></svg>
        </div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          An Unexpected Error Occurred
        </h1>
        <p class="text-sm text-gray-500">
          We have logged a deep diagnostic profile. If you require immediate verification services, reach out to operations with the code signature below.
        </p>

        <div class="p-4 bg-gray-100 dark:bg-gray-800 rounded-lg font-mono text-lg font-bold text-gray-800 dark:text-gray-200 tracking-wider">
          {{ supportCode }}
        </div>

        <div class="pt-2">
          <UButton
            color="neutral"
            label="Return to Dashboard System"
            @click="handleClearError"
          />
        </div>
      </div>
    </UCard>
  </div>
</template>

<script setup>
import { v4 as uuidv4 } from 'uuid'

const error = useError()
const supportCode = ref(error.value?.data?.supportCode || 'ERR-UNKNOWN')

onMounted(() => {
  if (!supportCode.value || supportCode.value === 'ERR-UNKNOWN') {
    let sessionId = sessionStorage.getItem('ops_session_id')
    if (!sessionId) {
      sessionId = uuidv4()
      sessionStorage.setItem('ops_session_id', sessionId)
    }
    supportCode.value = `ERR-${sessionId.split('-')[0].toUpperCase()}`
  }
})

const handleClearError = () => clearError({ redirect: '/' })
</script>
