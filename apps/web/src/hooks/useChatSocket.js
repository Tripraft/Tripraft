// Purpose: Maintains cookie-authenticated live chat, typing/presence/read events, session renewal and query recovery after reconnect or revoked access.
/**
 * Chat WebSocket Hook
 * Manages Socket.IO connection for real-time chat: messages, typing, read receipts.
 *
 * Owned by the GroupPlannerManager so the connection persists across tab switches.
 * Returns helpers that ChatPanel consumes.
 */

import { useEffect, useRef, useState, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { io } from 'socket.io-client';
import { isPlannerDemo } from '../features/trips/demo/demoMode';
import sqlAuthService from '../services/sqlAuthService';
import GlobalConfig from '../config/globalConfig';
import { chatKeys } from './useChatQuery';
import { mergeMessage, updateMessage } from '../lib/chatCache';
import { gpKeys } from './useGroupPlannerQuery';

const TYPING_EXPIRE_MS = 3_000;
const TYPING_THROTTLE_MS = 2_000;
const PRESENCE_HEARTBEAT_MS = 60_000;

/**
 * @param {string|null} groupId  - active group (null = dashboard notifications only)
 * @param {string|null} userId   - current user id
 */
export default function useChatSocket(groupId, userId) {
  const queryClient = useQueryClient();
  const socketRef = useRef(null);
  const lastTypingEmitRef = useRef(0);
  const [typingUsers, setTypingUsers] = useState([]);
  const [connected, setConnected] = useState(false);
  const [connectionError, setConnectionError] = useState(null);
  const lastReadRef = useRef({ id: null, time: 0 });

  const activeGroupRef = useRef(groupId);
  useEffect(() => {activeGroupRef.current = groupId;}, [groupId]);

  // Typing expiry timers per user
  const typingTimersRef = useRef({});

  // Recover authoritative state when live delivery is interrupted.
  useEffect(() => {
    if (isPlannerDemo() || connected || !userId) return;
    const timer = setInterval(() => {
      if (document.visibilityState === 'hidden') return;
      queryClient.invalidateQueries({queryKey: gpKeys.groups()});
      if (groupId) {
        for (const key of [gpKeys.group, gpKeys.places, gpKeys.polls, gpKeys.checklist, gpKeys.members, gpKeys.activities, gpKeys.vault, gpKeys.expenses]) queryClient.invalidateQueries({queryKey: key(groupId)});
        queryClient.invalidateQueries({queryKey: chatKeys.messages(groupId)});
      }
    }, 15000);
    return () => clearInterval(timer);
  }, [connected, userId, groupId, queryClient]);

  // --- Connect / disconnect lifecycle ---
  useEffect(() => {
    if (isPlannerDemo()) return;
    if (!userId) return;
    lastReadRef.current = { id: null, time: 0 };
    setConnectionError(null);

    let cancelled = false;
    let authRecoveryUsed = false;

    const connect = async () => {
      const token = await sqlAuthService.getIdToken();
      if (cancelled) return;
      // Derive base URL from API base (strip /api suffix)
      const baseUrl = (GlobalConfig.API_BASE_URL || '/api').replace(/\/api\/?$/, '') || window.location.origin;

      const opts = {
        transports: ['polling', 'websocket'],
        withCredentials: true,
        reconnection: true,
        reconnectionDelay: 1000,
        reconnectionAttempts: 10,
      };

      // In cookie-mode auth, token is null - backend reads httpOnly cookie instead
      if (token) {
        opts.auth = { token };
      }

      const socket = io(baseUrl, opts);
      socket.on('connect_error', async error => {
        if (cancelled) return;
        setConnected(false);
        const message = error.message || 'Real-time connection unavailable';
        setConnectionError(message);
        const authError = /auth|unauthor|401|connection rejected/i.test(message);
        if (authError && !authRecoveryUsed) {
          authRecoveryUsed = true;
          socket.io.opts.reconnection = false;
          try {
            const restored = await sqlAuthService.refreshAccessToken();
            if (cancelled) return;
            if (restored.success) {
              const token = await sqlAuthService.getIdToken();
              if (cancelled) return;
              socket.auth = token ? {token} : {};
              socket.io.opts.reconnection = true;
              socket.connect();
              return;
            }
          } catch { /* A failed refresh must not create an authentication loop. */ }
        }
        if (authError || /forbidden|403/i.test(message)) {
          socket.io.opts.reconnection = false;
          socket.disconnect();
        }
      });

      socketRef.current = socket;

      socket.on('connect', () => {
        const groupId = activeGroupRef.current;
        authRecoveryUsed = false;
        setConnected(true);
        setConnectionError(null);
        queryClient.invalidateQueries({ queryKey: gpKeys.groups() });
        if (!groupId) return;
        queryClient.invalidateQueries({ queryKey: chatKeys.messages(groupId) });
        // One joined socket serves both chat and the collaborative workspace.
        // Reconnects must recover changes made while this client was offline.
        for (const key of [gpKeys.group, gpKeys.places, gpKeys.polls, gpKeys.checklist, gpKeys.members, gpKeys.activities]) {
          queryClient.invalidateQueries({ queryKey: key(groupId) });
        }
      });

      socket.on('disconnect', () => {if (!cancelled) setConnected(false);});

      // --- Chat events ---
      const belongsHere = data => activeGroupRef.current && String(data?.group_id) === String(activeGroupRef.current);
      socket.on('planner:changed', async data => {
        const groupId = activeGroupRef.current;
        queryClient.invalidateQueries({queryKey: gpKeys.groups()});
        if (!belongsHere(data)) return;
        if (data.access_revoked) {
          const privateQuery = query => (query.queryKey[0] === 'group-planner' || query.queryKey[0] === 'chat') && query.queryKey.includes(groupId);
          await queryClient.cancelQueries({predicate: privateQuery});
          queryClient.removeQueries({predicate: privateQuery});
          queryClient.setQueryData(gpKeys.group(groupId), {data: null});
          queryClient.setQueryData(gpKeys.members(groupId), {data: []});
          queryClient.setQueryData(gpKeys.places(groupId), {data: []});
          queryClient.setQueryData(chatKeys.messages(groupId), {pages: [], pageParams: []});
          return;
        }
        queryClient.invalidateQueries({predicate: query => query.queryKey[0] === 'group-planner' && query.queryKey.includes(groupId)});
      });
      socket.on('chat:message', (msg) => {
        const groupId = activeGroupRef.current;
        if (!belongsHere(msg)) return;
        // Content cannot identify a send: another device can post the same text.
        // Keep every server UUID; the POST acknowledgement replaces its temp ID.
        queryClient.setQueryData(chatKeys.messages(groupId), old => mergeMessage(old, msg));
        // Bump unread
        queryClient.invalidateQueries({ queryKey: chatKeys.unread(groupId) });
      });

      socket.on('chat:deleted', (data) => {
        const groupId = activeGroupRef.current;
        if (!belongsHere(data)) return;
        queryClient.setQueryData(chatKeys.messages(groupId), (old) => {
          if (!old) return old;
          return {
            ...old,
            pages: old.pages.map((page) => {
              const msgs = page?.data?.messages ?? page?.messages ?? [];
              return {
                ...page,
                data: {
                  ...page.data,
                  messages: msgs.map((m) =>
                    m.id === data.message_id ? { ...m, is_deleted: true, content: '' } : m
                  ),
                },
              };
            }),
          };
        });
      });

      socket.on('chat:updated', data => {
        const groupId = activeGroupRef.current;
        if (belongsHere(data)) queryClient.setQueryData(chatKeys.messages(groupId), old => updateMessage(old, data));
      });

      socket.on('chat:typing', (data) => {
        if (!belongsHere(data)) return;
        if (data.user_id === userId) return;
        setTypingUsers((prev) => {
          if (prev.some((u) => u.user_id === data.user_id)) return prev;
          return [...prev, { user_id: data.user_id, email: data.email, is_ai: !!data.is_ai }];
        });
        // Clear after expiry (longer for AI since processing takes time)
        const expiry = data.is_ai ? 30_000 : TYPING_EXPIRE_MS;
        if (typingTimersRef.current[data.user_id]) {
          clearTimeout(typingTimersRef.current[data.user_id]);
        }
        typingTimersRef.current[data.user_id] = setTimeout(() => {
          setTypingUsers((prev) => prev.filter((u) => u.user_id !== data.user_id));
          delete typingTimersRef.current[data.user_id];
        }, expiry);
      });

      socket.on('chat:typing_stop', (data) => {
        if (!belongsHere(data)) return;
        setTypingUsers((prev) => prev.filter((u) => u.user_id !== data.user_id));
        if (typingTimersRef.current[data.user_id]) {
          clearTimeout(typingTimersRef.current[data.user_id]);
          delete typingTimersRef.current[data.user_id];
        }
      });

      socket.on('chat:read', (data) => {
        const groupId = activeGroupRef.current;
        if (!belongsHere(data)) return;
        queryClient.invalidateQueries({ queryKey: chatKeys.unread(groupId) });
      });

      const workspaceEvents = {
        'place:added': [gpKeys.places],
        'place:updated': [gpKeys.places],
        'place:deleted': [gpKeys.places],
        'place:voted': [gpKeys.places],
        'poll:created': [gpKeys.polls],
        'poll:voted': [gpKeys.polls],
        'poll:deleted': [gpKeys.polls],
        'checklist:toggled': [gpKeys.checklist],
        'itinerary:updated': [gpKeys.group, gpKeys.places],
        'member:joined': [gpKeys.members, gpKeys.group],
      };
      for (const [event, keys] of Object.entries(workspaceEvents)) {
        socket.on(event, data => {
          const groupId = activeGroupRef.current;
          if (!belongsHere(data)) return;
          for (const key of [...keys, gpKeys.activities]) {
            queryClient.invalidateQueries({ queryKey: key(groupId) });
          }
        });
      }
    };

    connect().catch(error => { if (!cancelled) setConnectionError(error.message || 'Real-time connection unavailable'); });

    return () => {
      cancelled = true;
      if (socketRef.current) {
        socketRef.current.disconnect();
        socketRef.current = null;
      }
      setConnected(false);
      setTypingUsers([]);
      Object.values(typingTimersRef.current).forEach(clearTimeout);
      typingTimersRef.current = {};
    };
  }, [userId, queryClient]);

  // Switching groups changes rooms, not the underlying connection/handshake.
  useEffect(() => {
    lastReadRef.current = {id: null, time: 0};
    setTypingUsers([]);
    Object.values(typingTimersRef.current).forEach(clearTimeout);
    typingTimersRef.current = {};
    if (!connected || !groupId || !socketRef.current) return;
    const socket = socketRef.current;
    socket.emit('join_group', {group_id: groupId});
    const heartbeat = setInterval(() => socket.emit('presence:heartbeat', {group_id: groupId}), PRESENCE_HEARTBEAT_MS);
    return () => {
      clearInterval(heartbeat);
      if (socket.connected) socket.emit('leave_group', {group_id: groupId});
    };
  }, [groupId, connected]);

  // --- Emit helpers ---
  const emitTyping = useCallback(() => {
    if (!socketRef.current || !groupId) return;
    const now = Date.now();
    if (now - lastTypingEmitRef.current < TYPING_THROTTLE_MS) return;
    lastTypingEmitRef.current = now;
    socketRef.current.emit('chat:typing', { group_id: groupId });
  }, [groupId]);

  const emitRead = useCallback((messageId) => {
    if (!socketRef.current || !groupId || !messageId || String(messageId).startsWith('temp-')) return;
    const now = Date.now();
    if (lastReadRef.current.id === messageId || now - lastReadRef.current.time < 1000) return;
    lastReadRef.current = { id: messageId, time: now };
    socketRef.current.emit('chat:read', { group_id: groupId, message_id: messageId });
  }, [groupId]);

  return { connected, connectionError, typingUsers, emitTyping, emitRead, socketRef };
}
