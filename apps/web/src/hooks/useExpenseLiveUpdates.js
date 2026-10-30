// Purpose: Uses private Socket.IO change notifications to invalidate expense queries, clears revoked data, and catches up through polling/reconnect/visibility changes.
// Receive private change notifications; authenticated API reads remain the source of ledger data.
import { useEffect, useRef } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { io } from 'socket.io-client';
import authService from '../services/sqlAuthService';
import GlobalConfig from '../config/globalConfig';

export default function useExpenseLiveUpdates(userId, activeGroupId) {
  const queryClient = useQueryClient();
  const activeGroupRef = useRef(activeGroupId);
  useEffect(() => {activeGroupRef.current = activeGroupId;}, [activeGroupId]);
  useEffect(() => {
    if (!userId) return;
    let cancelled = false, connecting = false, socket, timer, authRecoveryUsed = false;
    let personalChanged = false, inboxChanged = false;
    const groups = new Set(), expenses = new Set();
    // Joining the socket or returning focus must not restart a slow read that
    // is already in flight. Its authenticated response still reconciles data.
    const invalidate = (key, preserve = false) => {
      if (preserve) {
        const state = queryClient.getQueryState(key);
        // Initial socket join, focus and visibility often happen together.
        // A recent successful read already reconciled this page. Actual ledger
        // events below always invalidate, regardless of this recovery window.
        if (state?.fetchStatus === 'fetching' || (state?.dataUpdatedAt && !state.isInvalidated &&
            !state.error && Date.now() - state.dataUpdatedAt < 10_000)) return;
      }
      return queryClient.invalidateQueries({ queryKey: key, refetchType: 'active' }, {cancelRefetch: !preserve});
    };
    const refresh = (full = true) => {
      if (cancelled || document.hidden || navigator.onLine === false) return;
      const preserve = full && !personalChanged && !inboxChanged && !groups.size && !expenses.size;
      const reconcile = key => invalidate(key, preserve);
      if (full || personalChanged) reconcile(['personalExpenses']);
      if (full || groups.size || inboxChanged) reconcile(['expense-notifications', userId]);
      if (full || groups.size) {
        reconcile(['user', 'expense-friends', userId]);
        reconcile(['groups']);
        reconcile(['invitations']);
      }
      if (full && activeGroupRef.current) groups.add(activeGroupRef.current);
      for (const id of groups) {
        for (const prefix of ['group', 'expenses', 'settlements', 'recent-history', 'mega-bootstrap']) reconcile([prefix, id]);
      }
      if (expenses.size) {
        for (const id of expenses) reconcile(['expense-edit-history', id]);
      } else if (full) reconcile(['expense-edit-history']); // Recover history after missed events.
      groups.clear(); expenses.clear(); personalChanged = false; inboxChanged = false;
    };
    const schedule = () => {
      if (timer) return;
      timer = setTimeout(() => { timer = null; refresh(false); }, 150);
    };
    const onChange = data => {
      if (cancelled) return;
      if (data?.personal) {
        personalChanged = true;
        if (data.currency_changed) invalidate(['user', 'personal-currency', userId]);
        for (const id of data.expense_ids || []) expenses.add(id);
        schedule();
        return;
      }
      if (!data?.group_id) return;
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
        queryClient.cancelQueries({queryKey: ['expense-notifications', userId]}, {revert: false});
        queryClient.setQueriesData({queryKey: ['expense-notifications', userId]}, old => {
          if (!old) return old;
          const groupCounts = {...old.group_counts};
          const removedUnread = groupCounts[data.group_id] || 0;
          delete groupCounts[data.group_id];
          const notifications = (old.notifications || []).filter(row => String(row.group_id) !== String(data.group_id));
          return {...old, notifications, group_counts: groupCounts,
            unread_count: Math.max(0, (old.unread_count || 0) - removedUnread),
            groups: (old.groups || []).filter(group => String(group.id) !== String(data.group_id)),
            ...(old.pagination && {pagination: {...old.pagination,
              total: Math.max(0, old.pagination.total - ((old.notifications || []).length - notifications.length))}})};
        });
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
          transports: ['polling', 'websocket'], withCredentials: true, forceNew: true,
          reconnection: true, reconnectionDelay: 1000, reconnectionDelayMax: 10000,
          auth: { ...(token ? { token } : {}), public_ids: true },
        });
        socket.on('expenses:changed', onChange);
        socket.on('expenses:notifications-changed', () => {
          if (!cancelled) {inboxChanged = true; schedule();}
        });
        socket.on('expenses:friends-changed', () => {
          if (!cancelled) invalidate(['user', 'expense-friends', userId]);
        });
        socket.on('connect', () => {authRecoveryUsed = false; refresh();}); // Initial join and every reconnect catch up.
        socket.on('connect_error', async error => {
          const message = error.message || '';
          const authError = /auth|unauthor|401|connection rejected/i.test(message);
          if (cancelled) return;
          if (authError && !authRecoveryUsed) {
            authRecoveryUsed = true;
            socket.io.opts.reconnection = false;
            try {
              const restored = await authService.refreshAccessToken();
              if (cancelled) return;
              if (restored.success) {
                const token = await authService.getIdToken();
                if (cancelled) return;
                socket.auth = token ? {token} : {};
                socket.io.opts.reconnection = true;
                socket.connect();
                return;
              }
            } catch { /* Stop repeated authentication failures. */ }
          }
          if (authError || /forbidden|403/i.test(message)) socket.disconnect();
        });
      } catch { /* Focus/online recovery and polling continue when connection setup fails. */ }
      finally { connecting = false; }
    };
    connect();
    const recover = () => {
      // A healthy socket already records changes while hidden. Flush those
      // events on return; reconnects still perform full reconciliation.
      refresh(!socket?.connected);
      if (!socket) connect(); else if (!socket.connected && !authRecoveryUsed) socket.connect();
    };
    window.addEventListener('online', recover);
    window.addEventListener('focus', recover);
    document.addEventListener('visibilitychange', recover);
    // Safety net for disabled WebSockets and temporary outages.
    // Hidden/offline tabs do no polling work and catch up when they return.
    let elapsed = 0;
    const fallback = setInterval(() => {
      if (socket?.connected) { elapsed = 0; return; }
      elapsed += 10000;
      if (elapsed >= 20000) { elapsed = 0; refresh(); }
    }, 10000);
    return () => {
      cancelled = true;
      clearTimeout(timer); clearInterval(fallback);
      window.removeEventListener('online', recover);
      window.removeEventListener('focus', recover);
      document.removeEventListener('visibilitychange', recover);
      socket?.disconnect();
    };
  }, [userId, queryClient]);
}
