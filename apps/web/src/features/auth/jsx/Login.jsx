// Purpose: Submits traveler login, handles loading and server errors, and preserves invitations or return destinations through authentication.
import React, { useState, useEffect, useRef } from 'react';
import { Plane, Shield, AlertCircle, Home } from 'lucide-react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { useAuth } from '../../../context/AuthContext';
import QRCode from 'qrcode';
import { isValidEmail, returnDestination, readAuthStorage, rememberExpenseInvitation, invitationDestination } from '../utils/authForms';
import '../css/Login.css';

const Login = ({ onSwitchToSignup }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const { signIn, currentUser, loading: authLoading } = useAuth();
  
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [invitationEmail, setInvitationEmail] = useState('');
  
  const qrCanvasRef = useRef(null);
  const submittingRef = useRef(false);

  const currentYear = new Date().getFullYear();
  const from = returnDestination(location);

  // Check for pending invitation - ONLY if redirected from invitation page
  useEffect(() => {
    const searchParams = new URLSearchParams(location.search);
    const isInvitationRedirect = searchParams.get('redirect') === 'invitation';
    const invitationId = searchParams.get('invitationId');
    if (isInvitationRedirect && invitationId && searchParams.get('type') === 'group') {
      setInvitationEmail('');
      return;
    }
    
    if (isInvitationRedirect && invitationId) {
      const cachedEmail = rememberExpenseInvitation(invitationId);
      if (cachedEmail) {
        setInvitationEmail(cachedEmail);
        setEmail(cachedEmail);
        return; // Skip API call - email already cached from InvitationAccept
      }
      
      setInvitationEmail('');
      return; // Private invitation details are loaded only after authentication.
    } else if (!isInvitationRedirect) {
      // Not from invitation, clear any old invitation data
      setInvitationEmail('');
    }
    
    // Check for group planner invitation email
    const groupInvitationEmail = readAuthStorage('groupInvitationEmail');
    if (groupInvitationEmail) {
      setEmail(groupInvitationEmail);
      setInvitationEmail(groupInvitationEmail);
    }
  }, [location.search]);

  // Route once after authentication; the accept page owns the mutation.
  useEffect(() => {
    if (!currentUser || loading || authLoading) return;
    navigate(invitationDestination(location.search) || from, { replace: true });
  }, [currentUser, loading, authLoading, navigate, from, location.search]);

  // Generate QR Code
  useEffect(() => {
    if (qrCanvasRef.current) {
      QRCode.toCanvas(qrCanvasRef.current, 'https://tripraft.com', {
        width: 150,
        margin: 1,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        }
      }).catch(() => {});
    }
  }, []);

  // Handle email/password login
  const handleLogin = async event => {
    event.preventDefault();
    if (submittingRef.current || authLoading) return;
    const values = new FormData(event.currentTarget);
    const submittedEmail = String(values.get('email') || '').trim().toLowerCase();
    const submittedPassword = String(values.get('password') || '');
    if (!isValidEmail(submittedEmail) || !submittedPassword) {
      setError('Enter a valid email address and your password.');
      return;
    }
    submittingRef.current = true;
    
    try {
      setError('');
      setLoading(true);
      
      const result = await signIn(submittedEmail, submittedPassword);
      
      if (result.success) {
        // The authentication effect owns the redirect.
      } else {
        setError(result.error || 'Failed to sign in. Please check your credentials.');
      }
    } catch (err) {
      setError(err.message || 'An error occurred during sign in.');
    } finally {
      setLoading(false);
      submittingRef.current = false;
    }
  };

  return (
    <div className="login-container">
      {/* Home button */}
      <Link to="/" style={{
        position: 'absolute', top: '1.25rem', left: '1.25rem', zIndex: 10,
        display: 'flex', alignItems: 'center', gap: '0.4rem',
        padding: '0.5rem 1rem', background: 'rgba(255,255,255,0.15)',
        borderRadius: '10px', color: '#fff', textDecoration: 'none',
        fontSize: '0.9rem', fontWeight: '600', backdropFilter: 'blur(8px)',
        border: '1px solid rgba(255,255,255,0.2)', transition: 'background 0.2s'
      }}>
        <Home size={16} /> Home
      </Link>
      <div className="login-boarding-pass">
        
        {/* Left Side - Boarding Pass Info */}
        <div className="login-left-panel">
          {/* Background pattern */}
          <div className="login-bg-pattern">
            <div className="login-bg-circle-1"></div>
            <div className="login-bg-circle-2"></div>
          </div>

          <div className="login-left-content">
            <div className="login-header">
              <h1 className="login-brand">Tripraft</h1>
              <Shield className="login-shield-icon" strokeWidth={2} />
            </div>
            
            <div className="login-flight-info">
              <p className="login-flight-label">Flight Number</p>
              <p className="login-flight-number">TR{currentYear}</p>
            </div>

            <div className="login-journey-info">
              <div className="login-route-display">
                <div className="login-route-item">
                  <span className="login-route-label">From</span>
                  <span className="login-route-value">Dreams</span>
                </div>
                <div className="login-route-divider"></div>
                <div className="login-plane-icon-wrapper">
                  <Plane className="login-plane-icon" />
                </div>
                <div className="login-route-divider"></div>
                <div className="login-route-item">
                  <span className="login-route-label">To</span>
                  <span className="login-route-value">Reality</span>
                </div>
              </div>
              
              <div className="login-tagline-box">
                <p className="login-tagline">
                  Your Journey Begins<br />With A Click
                </p>
              </div>
            </div>
          </div>

          <div className="login-qr-section">
            <div className="login-qr-wrapper">
              <canvas ref={qrCanvasRef} className="login-qr-canvas"></canvas>
            </div>

          </div>
        </div>

        {/* Perforated divider */}
        <div className="login-divider-vertical"></div>
        <div className="login-divider-horizontal"></div>

        {/* Right Side - Login Form */}
        <div className="login-right-panel">
          <div className="login-form-container">
            <div className="login-form-header">
              <h2 className="login-form-title">Welcome Aboard</h2>
              <p className="login-form-subtitle">Present your boarding credentials</p>
            </div>

            <form onSubmit={handleLogin} className="login-form" aria-busy={loading || authLoading}>
              {invitationEmail && (
                <div style={{
                  padding: '0.75rem',
                  background: '#eff6ff',
                  border: '1px solid #dbeafe',
                  borderRadius: '8px',
                  marginBottom: '1rem',
                  color: '#1e40af',
                  fontSize: '0.9rem',
                  textAlign: 'center'
                }}>
                  <strong>Group Invitation:</strong> Please log in with {invitationEmail}
                </div>
              )}



              {error && (
                <div role="alert" style={{
                  padding: '0.75rem',
                  background: '#fee',
                  border: '1px solid #fcc',
                  borderRadius: '8px',
                  marginBottom: '1rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  color: '#c33'
                }}>
                  <AlertCircle size={18} />
                  <span style={{ fontSize: '0.9rem' }}>{error}</span>
                </div>
              )}

              <div className="login-form-group">
                <label htmlFor="login-email" className="login-label">
                  Email Address
                </label>
                <input
                  type="email"
                  id="login-email"
                  name="email"
                  autoComplete="username"
                  required
                  disabled={loading}
                  value={email}
                  onChange={(e) => { setEmail(e.target.value); setError(''); }}
                  placeholder="passenger@email.com"
                  className={`login-input ${email && !isValidEmail(email) ? 'error' : ''}`}
                />
              </div>

              <div className="login-form-group">
                <label htmlFor="login-password" className="login-label">
                  Password
                </label>
                <input
                  type="password"
                  id="login-password"
                  name="password"
                  autoComplete="current-password"
                  required
                  disabled={loading}
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); setError(''); }}
                  placeholder="Enter your password"
                  className="login-input"
                />
              </div>

              <button type="submit" className="login-submit-button" disabled={loading || authLoading}>
                <Plane size={20} aria-hidden="true" />
                {loading ? 'Signing in...' : authLoading ? 'Checking your session...' : 'Sign In'}
              </button>
              <p className="login-submit-hint">You will stay signed in on this device until you sign out or your session expires.</p>
            </form>

            <div className="login-footer">
              <p className="login-footer-text">
                Don't have a ticket?{' '}
                <button
                  onClick={() => onSwitchToSignup ? onSwitchToSignup() : navigate('/signup' + location.search, { state: location.state })}
                  className="login-footer-link"
                >
                  Book Your Raft
                </button>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
