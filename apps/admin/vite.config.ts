// Purpose: Serves the staff app on port 5174, proxies /api to Flask on port 5000, and returns a structured 503 if the proxy cannot connect.
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5174,
    proxy: { "/api": {
      target: "http://127.0.0.1:5000", changeOrigin: true,
      configure(proxy) {
        proxy.on('error', (_error, _request, response) => {
          if (response && 'writeHead' in response && !response.headersSent && !response.writableEnded) {
            response.writeHead(503, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'Retry-After': '2' })
              .end(JSON.stringify({ success: false, error: { code: 'API_UNAVAILABLE', message: 'TripRaft is temporarily unavailable. Try again shortly.' } }));
          }
        });
      },
    } },
  },
});
