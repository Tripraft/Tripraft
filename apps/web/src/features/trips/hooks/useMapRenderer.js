// Purpose: Initializes Leaflet and its MapLibre adapter/worker and styles, detects WebGL2 support, and provides a fallback capability flag.
// Load the installed map renderer with the application, including its styles.
import { useEffect, useState } from 'react';
import L from 'leaflet';
import workerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url';
import 'leaflet/dist/leaflet.css';
import 'maplibre-gl/dist/maplibre-gl.css';
let vectorSupported;
function supportsVectorMap() {
  if (vectorSupported === undefined) {
    try {
      const context = document.createElement('canvas').getContext('webgl2');
      vectorSupported = Boolean(context);
      context?.getExtension('WEBGL_lose_context')?.loseContext();
    } catch {
      vectorSupported = false;
    }
  }
  return vectorSupported;
}
export default function useLeaflet() {
  const [ready, setReady] = useState(Boolean(window.L?.maplibreGL));
  useEffect(() => {
    let active = true;
    if (!window.L) window.L = L;
    Promise.all([import('@maplibre/maplibre-gl-leaflet'), import('maplibre-gl')])
      .then(([adapter, renderer]) => {
        renderer.setWorkerUrl(workerUrl);
        window.L.maplibreGL = adapter.maplibreGL;
        window.L.supportsVectorMap = supportsVectorMap;
        if (active) setReady(true);
      })
      .catch(() => {
        window.L.supportsVectorMap = () => false;
        if (active) setReady(true);
      });
    return () => {
      active = false;
    };
  }, []);
  return ready;
}
