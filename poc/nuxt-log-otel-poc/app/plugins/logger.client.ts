import { v4 as uuidv4 } from 'uuid'

export default defineNuxtPlugin(() => {
  const sessionId = sessionStorage.getItem('ops_session_id') || uuidv4()
  sessionStorage.setItem('ops_session_id', sessionId)

  const sendLog = async (level: 'INFO' | 'WARNING' | 'ERROR', message: string, payload = {}) => {
    try {
      const cleanPayload = sanitizePayload(payload)
      await $fetch('/api/telemetry/logs', {
        method: 'POST',
        body: {
          level,
          message,
          timestamp: new Date().toISOString(),
          url: window.location.href,
          sessionId,
          payload: cleanPayload
        }
      })
    } catch (e) {
      console.warn('Telemetry ingestion failed:', e)
    }
  }

  return {
    provide: {
      log: {
        info: (msg: string, data?: object) => sendLog('INFO', msg, data),
        warn: (msg: string, data?: object) => sendLog('WARNING', msg, data),
        error: (msg: string, data?: object) => sendLog('ERROR', msg, data)
      }
    }
  }
})
