// Purpose: Restores auth before validating and accepting a trip invitation, shares StrictMode acceptance work and opens the exact joined group.
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { useAuth } from '../../../context/AuthContext';
import groupPlannerApi from '../../../services/groupPlannerApi';
import { readAuthStorage, removeAuthStorage } from '../../auth/utils/authForms';
const unwrap = (response) => response?.data ?? response ?? {};
export default function InvitationAcceptPage({ invitationId: invitationIdProp }) {
  const { invitationId: pathInvitationId } = useParams();
  const [searchParams] = useSearchParams();
  const invitationId = invitationIdProp || pathInvitationId || searchParams.get('id');
  const { currentUser, signOut, loading: authLoading } = useAuth();
  const userId = currentUser?.uid || currentUser?.id;
  const userEmail = currentUser?.email || '';
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [status, setStatus] = useState('loading');
  const [message, setMessage] = useState('Preparing your invitation...');
  const [invitation, setInvitation] = useState(null);
  const [wrongAccount, setWrongAccount] = useState(false);
  const [retry, setRetry] = useState(0);
  const requestRef = useRef(null);
  const loginPath = `/login?redirect=invitation&invitationId=${encodeURIComponent(invitationId || '')}&type=group`;
  const goToGroup = useCallback(
    (groupId) =>
      navigate(groupId ? `/group-planner/${encodeURIComponent(groupId)}` : '/group-planner', {
        replace: true,
      }),
    [navigate],
  );
  useEffect(() => {
    if (authLoading) return;
    if (!invitationId) {
      setStatus('error');
      setMessage('This invitation link is missing its invitation ID.');
      return;
    }
    if (!userId) {
      navigate(loginPath, { replace: true });
      return;
    }
    let cancelled = false,
      redirectTimer;
    setStatus('loading');
    setMessage('Joining the group...');
    setWrongAccount(false);
    const key = `${invitationId}:${userId}:${userEmail}:${retry}`;
    let record = requestRef.current;
    if (!record || record.key !== key || record.cancelled) {
      record = { key, active: true };
      record.promise = (async () => {
        const details = unwrap(await groupPlannerApi.getInvitationDetails(invitationId));
        if (!record.active) {
          record.cancelled = true;
          throw new Error('Invitation request cancelled');
        }
        if (
          details.invited_email &&
          details.invited_email.toLowerCase() !== userEmail.toLowerCase()
        )
          throw Object.assign(new Error('different email'), { invitation: details });
        if (details.status === 'accepted')
          return { details, groupId: details.group_id, alreadyAccepted: true };
        if (details.status && details.status !== 'pending')
          throw Object.assign(
            new Error(`This invitation is ${details.status}. Ask the group to send a new one.`),
            { invitation: details },
          );
        const result = unwrap(await groupPlannerApi.acceptInvitation(invitationId));
        return { details, groupId: result.group_id || details.group_id, alreadyAccepted: false };
      })();
      requestRef.current = record;
    }
    // Share the operation when StrictMode repeats the effect; never submit acceptance twice.
    record.active = true;
    record.promise
      .then(({ details, groupId, alreadyAccepted }) => {
        if (cancelled) return;
        setInvitation(details);
        setStatus('success');
        if (readAuthStorage('pendingGroupInvitation') === invitationId) {
          removeAuthStorage('pendingGroupInvitation');
          removeAuthStorage('groupInvitationEmail');
        }
        if (readAuthStorage('pendingInvitation') === invitationId) {
          removeAuthStorage('pendingInvitation');
          removeAuthStorage('invitationEmail');
        }
        setMessage(
          alreadyAccepted
            ? 'You have already accepted this invitation. Opening your group...'
            : `You've joined ${details.group_name || 'the group'}.`,
        );
        queryClient.invalidateQueries({ queryKey: ['group-planner', 'groups'] });
        queryClient.invalidateQueries({ queryKey: ['group-planner', 'members', groupId] });
        redirectTimer = setTimeout(() => goToGroup(groupId), 1200);
      })
      .catch((error) => {
        if (cancelled) return;
        const details = error.invitation;
        if (details) setInvitation(details);
        const text = String(error.message || 'Could not accept this invitation.'),
          lower = text.toLowerCase();
        setStatus('error');
        if (lower.includes('different email')) {
          setWrongAccount(true);
          setMessage(
            details?.invited_email
              ? `This invitation is for ${details.invited_email}, but you are signed in as ${userEmail}.`
              : 'Sign in with the email address this invitation was sent to.',
          );
        } else if (lower.includes('expired'))
          setMessage('This invitation has expired. Ask the group to send a new one.');
        else if (error.status === 404 || lower.includes('not found'))
          setMessage('This invitation link is invalid or no longer available.');
        else setMessage(text);
      });
    return () => {
      cancelled = true;
      record.active = false;
      clearTimeout(redirectTimer);
    };
  }, [
    authLoading,
    invitationId,
    userId,
    userEmail,
    loginPath,
    navigate,
    queryClient,
    goToGroup,
    retry,
  ]);
  const handleSwitchAccount = async () => {
    try {
      await signOut();
      navigate(loginPath, { replace: true });
    } catch (error) {
      setMessage(error.message || 'Could not sign out. Please try again.');
    }
  };
  return (
    <div className="gp-invite-accept">
      <div className="gp-invite-card">
        <h1 className="gp-invite-title">
          {status === 'success' ? 'You are in' : 'Group invitation'}
        </h1>

        {status === 'loading' && <div className="gp-invite-spinner" aria-hidden="true" />}

        <p className="gp-invite-message" role="status">
          {message}
        </p>

        {invitation?.group_name && status !== 'success' && (
          <p className="gp-invite-meta">
            {invitation.invited_by_name
              ? `${invitation.invited_by_name} invited you to `
              : 'You were invited to '}
            <strong>{invitation.group_name}</strong>
          </p>
        )}

        {status === 'error' && (
          <div className="gp-invite-actions">
            {!wrongAccount && (
              <button
                type="button"
                className="gp-invite-btn primary"
                onClick={() => setRetry((n) => n + 1)}
              >
                Try again
              </button>
            )}
            {wrongAccount && (
              <button type="button" className="gp-invite-btn primary" onClick={handleSwitchAccount}>
                Sign in with a different account
              </button>
            )}
            <button type="button" className="gp-invite-btn" onClick={() => goToGroup(null)}>
              Go to my groups
            </button>
          </div>
        )}
      </div>

      <style>{`
        .gp-invite-accept {
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 20px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .gp-invite-card {
          width: 100%;
          max-width: 480px;
          background: #fff;
          border-radius: 12px;
          padding: 40px 32px;
          text-align: center;
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
        }
        .gp-invite-title {
          margin: 0 0 18px;
          font-size: 24px;
          color: #1f2937;
        }
        .gp-invite-spinner {
          width: 48px;
          height: 48px;
          margin: 0 auto 18px;
          border: 4px solid #f3f4f6;
          border-top-color: #667eea;
          border-radius: 50%;
          animation: gp-invite-spin 1s linear infinite;
        }
        @keyframes gp-invite-spin { to { transform: rotate(360deg); } }
        .gp-invite-message { margin: 0; color: #6b7280; line-height: 1.6; }
        .gp-invite-meta { margin: 14px 0 0; color: #374151; font-size: 14px; }
        .gp-invite-actions {
          display: flex;
          flex-wrap: wrap;
          gap: 12px;
          justify-content: center;
          margin-top: 26px;
        }
        .gp-invite-btn {
          padding: 11px 22px;
          border: none;
          border-radius: 6px;
          font-size: 15px;
          font-weight: 500;
          cursor: pointer;
          background: #e5e7eb;
          color: #374151;
        }
        .gp-invite-btn.primary { background: #667eea; color: #fff; }
        @media (max-width: 640px) {
          .gp-invite-actions { flex-direction: column; }
          .gp-invite-btn { width: 100%; }
        }
      `}</style>
    </div>
  );
}
