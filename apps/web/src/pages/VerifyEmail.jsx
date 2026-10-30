// Purpose: Verifies a public email token with shared in-flight work under StrictMode, reports missing/expired/error states and offers explicit resend when signed in.
import React, { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import useEmailLinkToken from '../features/auth/utils/useEmailLinkToken';
import { CheckCircle, Mail, AlertCircle } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import authService from '../services/sqlAuthService';
import { invitationDestination } from '../features/auth/utils/authForms';
import './styles/VerifyEmail.css';

export default function VerifyEmail() {
  const token = useEmailLinkToken('/verify-email');
  const { currentUser, loading: authLoading } = useAuth();
  const [result, setResult] = useState({ status: 'loading', message: 'Confirming your email address…' });
  const [attempt, setAttempt] = useState(0);
  const [sending, setSending] = useState(false);
  const [resendMessage, setResendMessage] = useState('');
  const request = useRef(null);
  const resendInProgress = useRef(false);

  useEffect(() => {
    let active = true;
    setResendMessage('');
    if (!token) {
      setResult({ status: 'missing', message: 'Open the Verify Email link from your Tripraft email to confirm your address.' });
      return;
    }
    setResult({ status: 'loading', message: 'Confirming your email address…' });
    // Reuse the in-flight request during StrictMode's effect replay.
    if (request.current?.token !== token || request.current?.attempt !== attempt) {
      request.current = { token, attempt, promise: authService.verifyEmail(token) };
    }
    request.current.promise.then(response => {
      if (!active) return;
      setResult(response.success
        ? { status: 'success', message: response.message }
        : { status: response.status >= 500 ? 'network' : 'invalid', message: response.message });
    }).catch(() => {
      if (active) setResult({ status: 'network', message: 'We couldn’t reach Tripraft. Please try again.' });
    });
    return () => { active = false; };
  }, [token, attempt]);

  const resend = async () => {
    if (resendInProgress.current) return;
    resendInProgress.current = true;
    setSending(true);
    setResendMessage('');
    try {
      const response = await authService.resendVerificationEmail();
      setResendMessage(response.message);
    } catch {
      setResendMessage('We couldn’t send the email. Please try again.');
    } finally {
      resendInProgress.current = false;
      setSending(false);
    }
  };

  const titles = {
    loading: 'Verifying your email', success: 'Email verified',
    invalid: 'This link could not be verified', network: 'Verification unavailable',
    missing: 'Verify your email',
  };
  const Icon = result.status === 'success' ? CheckCircle
    : ['invalid', 'network'].includes(result.status) ? AlertCircle : Mail;

  return <main className="verify-email-page">
    <section className="verify-email-card" aria-labelledby="verification-title">
      <Link className="verify-email-brand" to="/">Tripraft</Link>
      <Icon className={`verify-email-icon ${result.status}`} size={48} aria-hidden="true" />
      <h1 id="verification-title">{titles[result.status]}</h1>
      <p role={result.status === 'invalid' || result.status === 'network' ? 'alert' : 'status'}>{result.message}</p>
      {result.status === 'success' && <>
        <p>Your email address is confirmed. You can continue using Tripraft.</p>
        <Link className="verify-email-action" to={currentUser ? invitationDestination('') || '/' : '/login'}>
          {currentUser ? 'Continue to Tripraft' : 'Sign in to continue'}
        </Link>
      </>}
      {result.status === 'network' && <button className="verify-email-action" onClick={() => setAttempt(value => value + 1)}>Try again</button>}
      {['invalid', 'missing'].includes(result.status) && !authLoading && (currentUser ? <>
        <p>Send a new verification email to {currentUser.email}.</p>
        <button className="verify-email-action" disabled={sending} onClick={resend}>
          {sending ? 'Sending…' : 'Send new verification email'}
        </button>
      </> : <Link className="verify-email-action" to="/login" state={{ from: { pathname: '/verify-email' } }}>
        Sign in to request a new link
      </Link>)}
      {resendMessage && <p role="status">{resendMessage}</p>}
      <p className="verify-email-help">Email verification confirms that your account uses an address you own.</p>
    </section>
  </main>;
}
