export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const headers = getHeaders(event)

  const traceparent = headers['traceparent'] || headers['x-cloud-trace-context']
  let traceId = ''

  if (traceparent && traceparent.startsWith('00-')) {
    traceId = traceparent.split('-')[1] || ''
  }

  const projectId = process.env.GOOGLE_CLOUD_PROJECT || 'gcp-project-placeholder'

  const logPayload: Record<string, unknown> = {
    severity: body.level || 'INFO',
    message: `[Browser] ${body.message}`,
    timestamp: body.timestamp,
    client_context: {
      url: body.url,
      sessionId: body.sessionId,
      userAgent: headers['user-agent'],
      custom_metadata: body.payload || {}
    }
  }

  if (traceId) {
    logPayload['logging.googleapis.com/trace'] = `projects/${projectId}/traces/${traceId}`
  }

  if (body.level === 'ERROR' || body.stack) {
    logPayload['@type'] = 'type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent'
    logPayload['stack_trace'] = body.stack || new Error(body.message).stack

    console.error(JSON.stringify(logPayload))
  } else {
    console.log(JSON.stringify(logPayload))
  }

  return { status: 'synchronized' }
})
