const SENSITIVE_KEYS = new Set(['password', 'token', 'secret', 'cc', 'creditcard', 'ssn', 'authorization'])
const EMAIL_REGEX = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g
const CREDIT_CARD_REGEX = /\b(?:\d[ -]*?){13,16}\b/g

export function sanitizePayload(obj: unknown): unknown {
  if (obj === null || obj === undefined) return obj

  if (typeof obj === 'string') {
    return obj
      .replace(EMAIL_REGEX, '[MASKED_EMAIL]')
      .replace(CREDIT_CARD_REGEX, '[MASKED_CARD]')
  }

  if (Array.isArray(obj)) {
    return obj.map(item => sanitizePayload(item))
  }

  if (typeof obj === 'object') {
    const sanitized: Record<string, unknown> = {}
    const rawObj = obj as Record<string, unknown>
    for (const key in rawObj) {
      if (Object.prototype.hasOwnProperty.call(rawObj, key)) {
        if (SENSITIVE_KEYS.has(key.toLowerCase())) {
          sanitized[key] = '[MASKED_SENSITIVE_DATA]'
        } else {
          sanitized[key] = sanitizePayload(rawObj[key])
        }
      }
    }
    return sanitized
  }

  return obj
}
