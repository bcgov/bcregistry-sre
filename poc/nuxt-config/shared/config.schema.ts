import { z } from 'zod'

export const ConfigSchema = z.object({
  analyticsId: z.string().min(1, 'Analytics ID is required'),
  firebaseClientId: z.string().min(1, 'Firebase Client ID is required')
})

export type Config = z.infer<typeof ConfigSchema>
