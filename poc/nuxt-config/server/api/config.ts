// server/api/config.ts
import { z } from 'zod'
import { ConfigSchema } from '~/../shared/config.schema'

export default defineEventHandler(async (_event) => {
  const config = useRuntimeConfig()
  const delay = Number(config.public.bootstrapDelay) || 0

  console.log(`api/config - bootstrap delay is ${delay}`)

  if (delay > 0) {
    await new Promise(resolve => setTimeout(resolve, delay))
  }

  // Generate random values for demo purposes
  const randomSuffix = Math.random().toString(36).substring(7).toUpperCase()

  // Prepare raw config from environment
  const rawConfig = {
    analyticsId: `${process.env.NUXT_PUBLIC_ANALYTICS_ID || 'UA-DEV-12345'}-${randomSuffix}`,
    firebaseClientId: `${process.env.NUXT_PUBLIC_FIREBASE_CLIENT_ID || 'dev-key'}-${randomSuffix}`
  }

  // Validate the configuration
  const result = ConfigSchema.safeParse(rawConfig)

  if (!result.success) {
    console.error('Invalid runtime configuration:', z.treeifyError(result.error))
    throw createError({
      statusCode: 500,
      statusMessage: 'Configuration validation failed'
    })
  }

  return result.data
})
