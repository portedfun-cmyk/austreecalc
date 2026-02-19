import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 4545,
    proxy: {
      '/api': 'http://127.0.0.1:4545'
    }
  },
  build: {
    outDir: '../public',
    emptyOutDir: true
  }
})
