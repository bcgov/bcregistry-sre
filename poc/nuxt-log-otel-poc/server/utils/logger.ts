export const logger = {
  info: (message: string, payload = {}) => {
    console.log(JSON.stringify({ severity: 'INFO', message, ...payload }))
  },
  error: (error: Error, message?: string, context = {}) => {
    console.error(JSON.stringify({
      'severity': 'ERROR',
      'message': message || error.message,
      '@type': 'type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent',
      'context': {
        reportLocation: {
          filePath: error.stack?.split('\n')[1]?.trim() || 'unknown'
        },
        ...context
      },
      'stack_trace': error.stack
    }))
  }
}
