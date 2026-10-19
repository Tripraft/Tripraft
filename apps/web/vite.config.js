// Purpose: Configures the React build and local API proxy for apps\web.
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:5000',
        changeOrigin: true,
        configure(proxy) {
          proxy.on('error', (_error, _request, response) => {
            if (response && 'writeHead' in response && !response.headersSent && !response.writableEnded) {
              response.writeHead(503, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'Retry-After': '2' })
                .end(JSON.stringify({ success: false, error: { code: 'API_UNAVAILABLE', message: 'TripRaft is temporarily unavailable. Try again shortly.' } }));
            }
          });
        },
      },
      '/socket.io': {
        target: 'http://127.0.0.1:5000',
        changeOrigin: true,
        ws: true,
      },
    },
  },
  esbuild: {
    // Strip console.* and debugger statements in production builds only
    ...(mode === 'production' && { drop: ['console', 'debugger'] }),
  },
}))
