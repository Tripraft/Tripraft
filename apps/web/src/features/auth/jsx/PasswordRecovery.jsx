// Purpose: Requests recovery emails and completes emailed password resets without a session.
import React, { useRef, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import useEmailLinkToken from '../utils/useEmailLinkToken';
import authService from '../../../services/sqlAuthService';
import { isValidEmail, passwordError } from '../utils/authForms';
import PasswordInput from './PasswordInput';
import PasswordChecklist from './PasswordChecklist';
import '../css/Login.css';

export default function PasswordRecovery({ reset = false }) {
  const location = useLocation();
  const token = useEmailLinkToken('/reset-password', reset);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const submitting = useRef(false);
  const missingToken = reset && !token;

  const submit = async event => {
    event.preventDefault();
    if (submitting.current || missingToken) return;
    const values = new FormData(event.currentTarget);
    const enteredEmail = String(values.get('email') || '');
    const enteredPassword = String(values.get('password') || '');
    const validation = reset ? passwordError(enteredPassword) ||
      (enteredPassword !== values.get('confirmPassword') ? 'Passwords do not match.' : '') :
      (!isValidEmail(enteredEmail) ? 'Enter a valid email address.' : '');
    if (validation) { setError(validation); return; }
    submitting.current = true;
    setBusy(true); setError(''); setMessage('');
    try {
      const result = reset ? await authService.resetPassword(token, enteredPassword) :
        await authService.requestPasswordReset(enteredEmail);
      if (result.success) setMessage(result.message || (reset ? 'Password reset successfully. Sign in with your new password.' : 'If an account exists, a reset link will arrive shortly.'));
      else setError(result.message || 'Could not complete password recovery. Please try again.');
    } catch { setError('Unable to connect. Please try again.'); }
    finally { submitting.current = false; setBusy(false); }
  };

  return <div className="login-container">
    <main className="login-right-panel" style={{ maxWidth: 480, width: '100%', borderRadius: 16, boxSizing: 'border-box' }}>
      <div className="login-form-container">
        <h1 className="login-form-title">{reset ? 'Choose a new password' : 'Forgot password?'}</h1>
        <p className="login-form-subtitle">{reset ? 'Use a strong password to secure your account.' : 'Enter your email and we’ll send you a reset link valid for one hour.'}</p>
        {(missingToken || error) && <p role="alert" className="login-field-error">{missingToken ? 'This reset link is missing its token. Request a new link.' : error}</p>}
        {message && <p role="status" className="auth-recovery-status">{message}</p>}
        {!missingToken && !(reset && message) && <form className="login-form" onSubmit={submit} noValidate aria-busy={busy}>
          {reset ? <>
            <div className="login-form-group">
              <label className="login-label" htmlFor="new-password">New password</label>
              <PasswordInput id="new-password" name="password" className="login-input" autoComplete="new-password"
                value={password} onChange={event => setPassword(event.target.value)} disabled={busy} required aria-describedby="password-requirements" />
              <PasswordChecklist password={password} />
            </div>
            <div className="login-form-group">
              <label className="login-label" htmlFor="confirm-password">Confirm password</label>
              <PasswordInput id="confirm-password" name="confirmPassword" visibilityLabel="confirm password" className="login-input" autoComplete="new-password"
                value={confirmation} onChange={event => setConfirmation(event.target.value)} disabled={busy} required />
            </div>
          </> : <div className="login-form-group">
            <label className="login-label" htmlFor="recovery-email">Email Address</label>
            <input id="recovery-email" name="email" type="email" autoComplete="email" className="login-input"
              value={email} onChange={event => setEmail(event.target.value)} disabled={busy} required />
          </div>}
          <button className="login-submit-button" type="submit" disabled={busy}>{busy ? 'Please wait...' : reset ? 'Reset password' : 'Send reset link'}</button>
        </form>}
        {reset && <Link className="auth-recovery-link" to={'/forgot-password' + location.search} state={location.state}>Request a new reset link</Link>}
        <div className="login-footer"><Link className="auth-recovery-link" to={'/login' + location.search} state={location.state}>Back to sign in</Link></div>
      </div>
    </main>
  </div>;
}
