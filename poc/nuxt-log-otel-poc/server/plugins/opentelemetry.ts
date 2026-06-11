import { NodeSDK } from '@opentelemetry/sdk-node'
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node'
import { TraceExporter } from '@google-cloud/opentelemetry-cloud-trace-exporter'

export default defineNitroPlugin(() => {
  if (process.env.NODE_ENV !== 'production') return

  const sdk = new NodeSDK({
    traceExporter: new TraceExporter(),
    instrumentations: [
      getNodeAutoInstrumentations({
        '@opentelemetry/instrumentation-fs': { enabled: false }
      })
    ]
  })

  sdk.start()

  process.on('SIGTERM', () => {
    sdk.shutdown().then(() => console.log('OTel Cloud SDK Terminated'))
  })
})
