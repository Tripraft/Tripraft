// Purpose: Handles expense invitation details, sign-in continuation, account mismatch and single acceptance, then navigates to the joined expense group.
import React, { useEffect, useState, useRef } from 'react';
import { useParams, useNavigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import expenseApi from '../services/expenseApi';
import { rememberExpenseInvitation, removeAuthStorage } from '../features/auth/utils/authForms';

export default function InvitationAccept() {
  const { invitationId: pathInvitationId } = useParams();
  const [searchParams] = useSearchParams();
  const invitationId = pathInvitationId || searchParams.get('id');
  
  const { currentUser, signOut, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const [status, setStatus] = useState('loading');
  const [message, setMessage] = useState('');
  const [invitationDetails, setInvitationDetails] = useState(null);
  const [showWrongUserWarning, setShowWrongUserWarning] = useState(false);
  
  // Prevent duplicate API calls
  const acceptInProgress = useRef(false);
  const initialized = useRef(false);
  const redirectTimer = useRef(null);

  useEffect(() => () => clearTimeout(redirectTimer.current), []);

  const openJoinedGroup = (groupId) => {
    const userId = currentUser?.uid || currentUser?.user_id;
    const query = new URLSearchParams({ groupId });
    redirectTimer.current = setTimeout(() => {
      navigate(`/expenses/${userId}/group?${query}`, { replace: true });
    }, 2000);
  };

  useEffect(() => {
    if (authLoading) return;
    if (!invitationId) {
      // No invitation ID, redirect to login
      navigate('/login', { replace: true });
      return;
    }

    // Prevent duplicate execution - only run once
    const requestKey = invitationId + ':' + (currentUser?.uid || 'signed-out');
    if (initialized.current === requestKey || acceptInProgress.current) {
      return;
    }
    
    initialized.current = requestKey;

    // If user is logged in, directly try to accept
    if (currentUser) {
      handleAcceptInvitation();
    } else {
      redirectToSignIn();
    }
  }, [invitationId, currentUser, authLoading]);

  const redirectToSignIn = () => {
    rememberExpenseInvitation(invitationId);
    navigate(`/login?redirect=invitation&invitationId=${encodeURIComponent(invitationId)}`, { replace: true });
  };

  const handleLogoutAndRetry = async () => {
    await signOut();
    redirectToSignIn();
  };

  const handleAcceptInvitation = async () => {
    if (acceptInProgress.current) return;
    acceptInProgress.current = true;
    
    try {
      setStatus('loading');
      setMessage('Processing invitation...');
      setShowWrongUserWarning(false);

      const response = await expenseApi.acceptInvitation(invitationId);

      if (response.success) {
        const groupId = response.data?.group?.id || response.data?.group?.group_id;
        if (!groupId) throw new Error('The joined group could not be loaded. Please try the invitation again.');
        setStatus('success');
        const joinedName = response.data?.group?.name || response.group_name || response.data?.group_name;
        setMessage(joinedName
          ? `You've successfully joined the group "${joinedName}"!`
          : "You've successfully joined the group!");
        setInvitationDetails(response);

        // Clear the pending invitation from localStorage
        removeAuthStorage('pendingInvitation');
        removeAuthStorage('invitationEmail');

        openJoinedGroup(groupId);
      } else {
        setStatus('error');
        setMessage(response.message || 'Failed to accept invitation');
      }
    } catch (error) {
      setStatus('error');

      if (error.status === 401) {
        redirectToSignIn();
      } else if (error.status === 404 || error.status === 410 || error.message.includes('404')) {
        setMessage('This invitation link is invalid or has expired.');
        removeAuthStorage('pendingInvitation');
        removeAuthStorage('invitationEmail');
      } else if (error.message.includes('already accepted')) {
        try {
          const details = await expenseApi.getInvitationDetails(invitationId);
          const groupId = details.data?.invitation?.group_id;
          if (!groupId) throw new Error('Group unavailable');
          setStatus('success');
          setMessage('You have already accepted this invitation. Opening your group...');
          removeAuthStorage('pendingInvitation');
          removeAuthStorage('invitationEmail');
          openJoinedGroup(groupId);
        } catch {
          setMessage('Your group could not be loaded. Please try the invitation again.');
        }
      } else if (error.status === 409 && /cancelled|declined/i.test(error.message)) {
        const state = /cancelled/i.test(error.message) ? 'cancelled' : 'declined';
        setMessage(`This invitation was ${state}. Ask the inviter to send a new invitation.`);
        removeAuthStorage('pendingInvitation');
        removeAuthStorage('invitationEmail');
      } else if (error.status === 403 || error.message.includes('403')) {
        setMessage('This invitation is not for your account. Please log in with the invited email address.');
        setShowWrongUserWarning(true);
      } else {
        setMessage(`Failed to accept invitation: ${error.message}`);
      }
    } finally {
      acceptInProgress.current = false;
    }
  };

  const getStatusIcon = () => {
    switch (status) {
      case 'loading':
        return (
          <div className="spinner">
            <div className="spinner-circle"></div>
          </div>
        );
      case 'success':
        return (
          <svg className="status-icon success" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <circle cx="12" cy="12" r="10" strokeWidth="2"/>
            <path d="M9 12l2 2 4-4" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        );
      case 'error':
        return (
          <svg className="status-icon error" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <circle cx="12" cy="12" r="10" strokeWidth="2"/>
            <path d="M15 9l-6 6M9 9l6 6" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        );
      default:
        return null;
    }
  };

  return (
    <div className="invitation-accept-container">
      <div className="invitation-card">
        <div className="invitation-header">
          <h1>TravelApp Expense Tracker</h1>
        </div>

        <div className="invitation-content">
          {getStatusIcon()}
          <h2>{status === 'success' ? 'Success!' : 'Processing Invitation'}</h2>
          <p className="message">{message}</p>

          {status === 'success' && invitationDetails && (
            <div className="invitation-details">
              <p>Opening your group expenses...</p>
            </div>
          )}

          {showWrongUserWarning && (
            <div className="action-buttons">
              <button 
                className="btn-primary"
                onClick={handleLogoutAndRetry}
              >
                Sign in with the invited email
              </button>
              <button 
                className="btn-secondary"
                onClick={() => navigate('/expenses')}
              >
                Continue as {currentUser?.email}
              </button>
            </div>
          )}
        </div>
      </div>

      <style>{`
        .invitation-accept-container {
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          padding: 20px;
        }

        .invitation-card {
          max-width: 600px;
          width: 100%;
          background: white;
          border-radius: 12px;
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
          overflow: hidden;
        }

        .invitation-header {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 30px;
          text-align: center;
        }

        .invitation-header h1 {
          margin: 0;
          font-size: 28px;
          font-weight: 600;
        }

        .invitation-content {
          padding: 40px;
          text-align: center;
        }

        .spinner {
          display: flex;
          justify-content: center;
          margin-bottom: 20px;
        }

        .spinner-circle {
          width: 60px;
          height: 60px;
          border: 4px solid #f3f4f6;
          border-top-color: #667eea;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }

        @keyframes spin {
          to { transform: rotate(360deg); }
        }

        .status-icon {
          width: 80px;
          height: 80px;
          margin: 0 auto 20px;
        }

        .status-icon.success {
          color: #10b981;
        }

        .status-icon.error {
          color: #ef4444;
        }

        .invitation-content h2 {
          margin: 0 0 15px 0;
          font-size: 24px;
          color: #1f2937;
        }

        .message {
          font-size: 16px;
          color: #6b7280;
          margin-bottom: 20px;
          line-height: 1.6;
        }

        .invitation-details {
          margin-top: 20px;
          padding: 20px;
          background: #f9fafb;
          border-radius: 8px;
        }

        .invitation-details p {
          margin: 0;
          color: #374151;
        }

        .invitation-info {
          margin-top: 20px;
          padding: 20px;
          background: #eff6ff;
          border: 1px solid #dbeafe;
          border-radius: 8px;
          text-align: left;
        }

        .invitation-info p {
          margin: 8px 0;
          color: #1e40af;
          font-size: 14px;
        }

        .invitation-info strong {
          color: #1e3a8a;
        }

        .action-buttons {
          display: flex;
          gap: 15px;
          justify-content: center;
          margin-top: 30px;
          flex-wrap: wrap;
        }

        .btn-primary, .btn-secondary {
          padding: 12px 30px;
          border: none;
          border-radius: 6px;
          font-size: 16px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s;
          white-space: nowrap;
        }

        .btn-primary {
          background: #667eea;
          color: white;
        }

        .btn-primary:hover {
          background: #5568d3;
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }

        .btn-secondary {
          background: #e5e7eb;
          color: #374151;
        }

        .btn-secondary:hover {
          background: #d1d5db;
          transform: translateY(-1px);
        }

        @media (max-width: 640px) {
          .invitation-card {
            margin: 10px;
          }

          .invitation-header {
            padding: 20px;
          }

          .invitation-header h1 {
            font-size: 22px;
          }

          .invitation-content {
            padding: 30px 20px;
          }

          .action-buttons {
            flex-direction: column;
          }

          .btn-primary, .btn-secondary {
            width: 100%;
          }
        }
      `}</style>
    </div>
  );
}
