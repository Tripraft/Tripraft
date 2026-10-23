// Purpose: Serves the staff app on port 5174, proxies /api to Flask on port 5000, and returns a structured 503 if the proxy cannot connect.
import { defineConfig, mergeConfig } from "vite";
import { existsSync, statSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import react from "@vitejs/plugin-react";
const repository = resolve(__dirname, "../..");
const portalRoot = existsSync(resolve(repository, "apps/admin/src/LocalAdminApp.tsx"))
  ? repository : resolve(repository, ".tripraft/employee-access-portal");
const localPlugin = resolve(portalRoot, "apps/admin/employeeLocalPlugin.mjs");
const employee = existsSync(localPlugin)
  // Local demo APIs and cookies stay isolated from the regular website.
  ? (await import(pathToFileURL(localPlugin).href + "?v=" + statSync(localPlugin).mtimeMs)).employeeLocalDevelopment(__dirname, portalRoot) : {};
export default mergeConfig(defineConfig({
  plugins: [react()],
  server: {
    port: 5174,
    proxy: { ...employee.server?.proxy, "/api": {
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
}), employee);
