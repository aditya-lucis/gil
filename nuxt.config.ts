import { defineNuxtConfig } from 'nuxt/config'
import tailwindcss from '@tailwindcss/vite'

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: false },
  telemetry: false,

  modules: [
    '@pinia/nuxt'
  ],

  vite: {
    plugins: [
      tailwindcss()
    ]
  },

  css: ['~/assets/css/main.css'],

  typescript: {
    strict: true,
    shim: false
  },

  runtimeConfig: {
    // Private server-only runtime configuration
    databaseUrl: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/gil',
    redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',
    jwtSecret: process.env.JWT_SECRET || 'dev-insecure-secret-key-for-local-development-only-replace-with-env',

    // Public runtime configuration exposed to client
    public: {
      appName: 'GIL Enterprise Accounting Platform',
      appVersion: '1.0.0'
    }
  }
})
