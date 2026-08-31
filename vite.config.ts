import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const backendTarget =
    env.VITE_BACKEND_URL ||
    'https://dukaplusbackend-production.up.railway.app'

  return {
    plugins: [react(), tailwindcss()],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
      },
    },
    server: {
      port: 5173,
      watch: {
        ignored: ['**/mobileapp/**', '**/android/**', '**/ios/**', '**/.gradle/**'],
      },
      proxy: {
        '/api': {
          target: backendTarget,
          changeOrigin: true,
          secure: true,
        },
      },
    },
  }
})
