// Load the installed map renderer with the application, including its styles.
import { useEffect, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
export default function useLeaflet() {
  const [ready, setReady] = useState(Boolean(window.L));
  useEffect(() => {
    if (!window.L) window.L = L;
    setReady(true);
  }, []);
  return ready;
}
