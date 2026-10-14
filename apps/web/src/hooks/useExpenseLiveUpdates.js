// Receive private change notifications; authenticated API reads remain the source of ledger data.
import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { io } from 'socket.io-client';
import authService from '../services/sqlAuthService';
import GlobalConfig from '../config/globalConfig';

export default function useExpenseLiveUpdates(userId, activeGroupId) {
  const queryClient = useQueryClient();
  useEffect(() => {
    if (!userId) return;
    let cancelled = false, connecting = false, socket, timer;
    const groups = new Set(), expenses = new Set();
    const invalidate = key => queryClient.invalidateQueries({ queryKey: key, refetchType: 'active' });
    const refresh = () => {
      if (cancelled || document.hidden || navigator.onLine === false) return;
      invalidate(['groups']);
      invalidate(['invitations']);
      if (activeGroupId) groups.add(activeGroupId);
      for (const id of groups) {
        for (const prefix of ['group', 'expenses', 'settlements', 'recent-history', 'mega-bootstrap']) invalidate([prefix, id]);
      }
      if (expenses.size) {
        for (const id of expenses) invalidate(['expense-edit-history', id]);
      } else invalidate(['expense-edit-history']); // Also recover an already-open history after missed events.
      groups.clear(); expenses.clear();
    };
    const schedule = () => {
      if (timer) return;
      timer = setTimeout(() => { timer = null; refresh(); }, 150);
    };
    const onChange = data => {
      if (cancelled || !data?.group_id) return;
      groups.add(data.group_id);
      for (const id of data.expense_ids || []) expenses.add(id);
      if (data.access_revoked) {
        // Hide stale private data immediately, even if the following API read
        // is slow or offline. Cancel in-flight reads before replacing the cache.
        queryClient.cancelQueries({ queryKey: ['group', data.group_id] }, { revert: false });
        queryClient.setQueryData(['group', data.group_id], { group: null });
        queryClient.setQueryData(['groups'], old => old && ({ ...old,
          groups: (old.groups || []).filter(group => String(group.id || group.group_id) !== String(data.group_id)),
        }));
      }
      schedule();
    };
    const connect = async () => {
      if (cancelled || connecting) return;
      connecting = true;
      try {
        const token = await authService.getIdToken();
        if (cancelled) return;
        const base = (GlobalConfig.API_BASE_URL || '/api').replace(/\/api\/?$/, '').replace(/\/$/, '') || window.location.origin;
        socket = io(`${base}/expenses`, {
          transports: ['websocket', 'polling'], withCredentials: true, forceNew: true,
          reconnection: true, reconnectionDelay: 1000, reconnectionDelayMax: 10000,
          ...(token ? { auth: { token } } : {}),
        });
        socket.on('expenses:changed', onChange);
        socket.on('connect', refresh); // Initial join and every reconnect catch up.
        socket.on('connect_error', error => {
          if (/auth|unauthor|forbidden|401|403|refused/i.test(error.message || '')) socket.disconnect();
        });
      } catch { /* Focus/online recovery and polling continue when connection setup fails. */ }
      finally { connecting = false; }
    };
    connect();
    const recover = () => { refresh(); if (!socket) connect(); else if (!socket.connected) socket.connect(); };
    window.addEventListener('online', recover);
    window.addEventListener('focus', recover);
    document.addEventListener('visibilitychange', recover);
    // Safety net for disabled WebSockets, missed messages and temporary outages.
    // Hidden/offline tabs do no polling work and catch up when they return.
    let elapsed = 0;
    const fallback = setInterval(() => {
      elapsed += 10000;
      if (elapsed >= (socket?.connected ? 60000 : 20000)) { elapsed = 0; refresh(); }
    }, 10000);
    return () => {
      cancelled = true;
      clearTimeout(timer); clearInterval(fallback);
      window.removeEventListener('online', recover);
      window.removeEventListener('focus', recover);
      document.removeEventListener('visibilitychange', recover);
      socket?.disconnect();
    };
  }, [userId, activeGroupId, queryClient]);
}
