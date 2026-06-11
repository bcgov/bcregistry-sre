export default defineNuxtPlugin((nuxtApp) => {
  const reportError = async (error: unknown, context: string) => {
    const sessionId = sessionStorage.getItem('ops_session_id') || 'unknown'
    let errorMessage = String(error)
    let errorStack = new Error().stack

    if (error instanceof Error) {
      errorMessage = error.message
      errorStack = error.stack
    } else if (error && typeof error === 'object') {
      if ('message' in error && error.message) {
        errorMessage = String(error.message)
      }
      if ('stack' in error && error.stack) {
        errorStack = String(error.stack)
      }
    }

    const payload = {
      level: 'ERROR' as const,
      message: errorMessage,
      timestamp: new Date().toISOString(),
      url: window.location.href,
      sessionId,
      stack: errorStack,
      payload: { context }
    }

    try {
      await $fetch('/api/telemetry/logs', {
        method: 'POST',
        body: payload
      })
    } catch (e) {
      console.error('Failed to route exception telemetry:', e)
    }
  }

  nuxtApp.vueApp.config.errorHandler = (error, instance, info) => {
    reportError(error, `Vue Error Boundary: ${info}`)
    console.error(error)
  }

  window.onerror = (message, source, lineno, colno, error) => {
    reportError(error || message, `Global Window Fault: ${source}:${lineno}`)
  }

  window.onunhandledrejection = (event) => {
    reportError(event.reason, 'Unhandled Promise Rejection')
  }
})
