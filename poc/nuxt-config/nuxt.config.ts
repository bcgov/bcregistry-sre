// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: [
    '@nuxt/eslint',
    '@nuxt/ui'
  ],

  ssr: false,

  devtools: {
    enabled: true
  },

  css: ['~/assets/css/main.css'],

  runtimeConfig: {
    public: {
      bootstrapDelay: 2000,
      configEndpoint: process.env.NUXT_PUBLIC_CONFIG_ENDPOINT || '/api/config',
      mobileConfigBase: process.env.NUXT_PUBLIC_MOBILE_CONFIG_BASE || 'https://api.yourproductiondomain.com'
    }
  },

  routeRules: {
    '/': { prerender: true }
  },

  compatibilityDate: '2026-04-15',

  nitro: {
    preset: 'node-server' // Builds a clean node package ideal for a Cloud Run Docker container
  },

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  }
})
