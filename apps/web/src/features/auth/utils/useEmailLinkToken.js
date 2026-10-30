// Purpose: Capture emailed secrets in memory and immediately remove them from browser history.
import { useEffect, useState } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';

export default function useEmailLinkToken(page, enabled = true) {
  const { token: pathToken } = useParams();
  const location = useLocation();
  const navigate = useNavigate();
  const [token] = useState(() => pathToken || new URLSearchParams(location.hash.slice(1)).get('token') ||
    new URLSearchParams(location.search).get('token'));
  useEffect(() => {
    if (!enabled || !token) return;
    const params = new URLSearchParams(location.search);
    params.delete('token');
    const query = params.toString();
    const clean = page + (query ? `?${query}` : '');
    if (location.pathname + location.search + location.hash !== clean) {
      navigate(clean, { replace: true });
    }
  }, [enabled, token, page, location.pathname, location.search, location.hash, navigate]);
  return token;
}
