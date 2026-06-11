// plugins/bootstrap.client.ts
import { z } from 'zod'
import { ConfigSchema } from '~/../shared/config.schema'

export default defineNuxtPlugin((_nuxtApp) => {
  const config = useRuntimeConfig()

  // Status tracking
  const syncStatus = useState('syncStatus', () => 'init')
  const isConfigReady = useState('isConfigReady', () => false)
  const syncHistory = useState<{ status: string, timestamp: string }[]>('syncHistory', () => [{
    status: 'init',
    timestamp: new Date().toLocaleTimeString()
  }])

  const setStatus = (status: string) => {
    syncStatus.value = status
    syncHistory.value = [
      ...syncHistory.value,
      {
        status,
        timestamp: new Date().toLocaleTimeString()
      }
    ]
  }

  const init = async () => {
    setStatus('checking-cache')

    // 1. Immediate Cache Check
    const cachedConfig = localStorage.getItem('runtime_config')
    if (cachedConfig) {
      try {
        const parsed = JSON.parse(cachedConfig)
        const result = ConfigSchema.safeParse(parsed)

        if (result.success) {
          Object.assign(config.public, result.data)
          isConfigReady.value = true
          setStatus('revalidating')
        } else {
          console.warn('Cached config validation failed:', z.treeifyError(result.error))
          localStorage.removeItem('runtime_config')
          setStatus('fetching')
        }
      } catch {
        localStorage.removeItem('runtime_config')
        setStatus('fetching')
      }
    } else {
      setStatus('fetching')
    }

    // 2. Revalidation / Initial Fetch
    const isNativeMobile = typeof window !== 'undefined'
      && (window.location.protocol === 'file:' || !!(window as unknown as { Capacitor?: { isNativePlatform?: () => boolean } }).Capacitor?.isNativePlatform?.())

    // Use the endpoint from config, but allow logic for mobile overrides if not explicitly set
    let configEndpoint = config.public.configEndpoint

    if (isNativeMobile && configEndpoint.startsWith('/')) {
      // Fallback for native mobile if only a relative path was provided
      configEndpoint = `${config.public.mobileConfigBase}${configEndpoint}`
    }

    try {
      const freshConfig = await $fetch(configEndpoint)
      const result = ConfigSchema.safeParse(freshConfig)

      if (result.success) {
        Object.assign(config.public, result.data)
        localStorage.setItem('runtime_config', JSON.stringify(result.data))
        isConfigReady.value = true
        setStatus('loaded')
      } else {
        console.error('Fresh config validation failed:', z.treeifyError(result.error))
        setStatus(isConfigReady.value ? 'loaded-stale' : 'error')
      }
    } catch (error) {
      console.error('Failed to revalidate background config:', error)
      setStatus(isConfigReady.value ? 'loaded-stale' : 'error')
    }
  }

  // Non-blocking start
  init()
})
