// Purpose: Renders the Signup interface within apps\web\src\features\auth\jsx.
import React, { useState, useEffect, useRef } from 'react';
import { Plane, UserPlus, AlertCircle, Home } from 'lucide-react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { useAuth } from '../../../context/AuthContext';
import QRCode from 'qrcode';
import '../css/Signup.css';
import { isValidEmail, signupErrors, returnDestination, rememberExpenseInvitation, invitationDestination } from '../utils/authForms';

const Signup = ({ onSwitchToLogin }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const { signUp, currentUser, loading: authLoading } = useAuth();
  
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    confirmPassword: ''
  });
  const [errors, setErrors] = useState({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [invitationEmail, setInvitationEmail] = useState('');
  const [passwordStrength, setPasswordStrength] = useState({ score: 0, level: 'None', message: '' });
  
  const qrCanvasRef = useRef(null);
  const submittingRef = useRef(false);

  const currentYear = new Date().getFullYear();
  const from = returnDestination(location);

  // Check for pending invitation - ONLY if redirected from invitation page
  useEffect(() => {
    const searchParams = new URLSearchParams(location.search);
    const isInvitationRedirect = searchParams.get('redirect') === 'invitation';
    const invitationId = searchParams.get('invitationId');
    
    if (isInvitationRedirect && invitationId) {
      const cachedEmail = rememberExpenseInvitation(invitationId);
      if (cachedEmail) {
        setInvitationEmail(cachedEmail);
        setFormData(prev => ({ ...prev, email: cachedEmail }));
        return; // Skip API call - email already cached from InvitationAccept
      }
      
      setInvitationEmail('');
    } else if (!isInvitationRedirect) {
      // Not from invitation, clear any old invitation data
      setInvitationEmail('');
    }
  }, [location.search]);

  // The invitation accept page owns validation and acceptance.
  useEffect(() => {
    if (!currentUser || loading || authLoading) return;
    navigate(invitationDestination(location.search) || from, { replace: true });
  }, [currentUser, loading, authLoading, navigate, from, location.search]);

  useEffect(() => {
    if (qrCanvasRef.current) {
      QRCode.toCanvas(qrCanvasRef.current, 'https://tripraft.com/signup', {
        width: 150,
        margin: 1,
        color: { dark: '#000000', light: '#FFFFFF' }
      }).catch(() => {});
    }
  }, []);

  // Password strength checker
  const getPasswordStrength = (password) => {
    if (!password) return { score: 0, level: 'None', message: '' };
    
    let score = 0;
    const conditions = {
      hasUpperCase: /[A-Z]/.test(password),
      hasLowerCase: /[a-z]/.test(password),
      hasNumbers: /\d/.test(password),
      hasSpecialChars: [...password].some(char => '!@#$%^&*()_+-=[]{}|;:,./<>?'.includes(char)),
      isLongEnough: password.length >= 8
    };

    // Score calculation
    if (conditions.hasUpperCase) score++;
    if (conditions.hasLowerCase) score++;
    if (conditions.hasNumbers) score++;
    if (conditions.hasSpecialChars) score++;
    if (conditions.isLongEnough) score++;

    let level, message;
    if (score <= 2) {
      level = 'Weak';
      message = 'Add uppercase, numbers, and special characters';
    } else if (score === 3) {
      level = 'Fair';
      message = 'Add more character variety for better security';
    } else if (score === 4) {
      level = 'Good';
      message = 'Good password strength';
    } else {
      level = 'Strong';
      message = 'Excellent password strength';
    }

    return { score, level, message, conditions };
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    setErrors(prev => ({ ...prev, [name]: undefined }));
    setError('');
    
    // Update password strength when password changes
    if (name === 'password') {
      setPasswordStrength(getPasswordStrength(value));
    }
  };

  // Handle signup
  const handleSignup = async event => {
    event.preventDefault();
    if (submittingRef.current || authLoading) return;
    const values = new FormData(event.currentTarget);
    const submitted = Object.fromEntries(values.entries());
    const validationErrors = signupErrors(submitted);
    setErrors(validationErrors);
    if (Object.keys(validationErrors).length) return;
    submittingRef.current = true;
    
    try {
      setError('');
      setLoading(true);
      
      const displayName = `${submitted.firstName.trim()} ${submitted.lastName.trim()}`;
      const result = await signUp(submitted.email.trim().toLowerCase(), submitted.password, displayName);
      
      if (result.success) {
        // The authentication effect owns the redirect.
      } else {
        setError(result.error || 'Failed to create account. Please try again.');
      }
    } catch (err) {
      setError(err.message || 'An error occurred during sign up.');
    } finally {
      setLoading(false);
      submittingRef.current = false;
    }
  };

  return (
    <div className="signup-container">
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
      <div className="signup-boarding-pass">
        <div className="signup-left-panel">
          <div className="signup-bg-pattern">
            <div className="signup-bg-circle-1"></div>
            <div className="signup-bg-circle-2"></div>
          </div>
          <div className="signup-left-content">
            <div className="signup-header">
              <h1 className="signup-brand">Tripraft</h1>
              <UserPlus className="signup-icon" strokeWidth={2} />
            </div>
            <div className="signup-booking-info">
              <p className="signup-booking-label">Booking ID</p>
              <p className="signup-booking-number">BK{currentYear}</p>
            </div>
            <div className="signup-journey-info">
              <div className="signup-route-display">
                <div className="signup-route-item">
                  <span className="signup-route-label">From</span>
                  <span className="signup-route-value">Ideas</span>
                </div>
                <div className="signup-route-divider"></div>
                <div className="signup-plane-icon-wrapper">
                  <Plane className="signup-plane-icon" />
                </div>
                <div className="signup-route-divider"></div>
                <div className="signup-route-item">
                  <span className="signup-route-label">To</span>
                  <span className="signup-route-value">Adventures</span>
                </div>
              </div>
              <div className="signup-tagline-box">
                <p className="signup-tagline">Begin Your Journey<br />With A Single Step</p>
              </div>
            </div>
          </div>
          <div className="signup-qr-section">
            <div className="signup-qr-wrapper">
              <canvas ref={qrCanvasRef} className="signup-qr-canvas"></canvas>
            </div>

          </div>
        </div>
        <div className="signup-divider-vertical"></div>
        <div className="signup-divider-horizontal"></div>
        <div className="signup-right-panel">
          <div className="signup-form-container">
            <div className="signup-form-header">
              <h2 className="signup-form-title">Book Your Raft</h2>
              <p className="signup-form-subtitle">Create your account and start exploring</p>
            </div>
            <form onSubmit={handleSignup} className="signup-form" aria-busy={loading || authLoading} noValidate>
              <div className="signup-form-row">
                <div className="signup-form-group">
                  <label htmlFor="firstName" className="signup-label">First Name</label>
                  <input type="text" id="firstName" name="firstName" value={formData.firstName}
                    autoComplete="given-name" required disabled={loading} aria-invalid={!!errors.firstName} aria-describedby={errors.firstName ? 'firstName-error' : undefined}
                    onChange={handleInputChange} placeholder="John" className="signup-input" />
                  {errors.firstName && <p id="firstName-error" className="signup-field-error" role="alert">{errors.firstName}</p>}
                </div>
                <div className="signup-form-group">
                  <label htmlFor="lastName" className="signup-label">Last Name</label>
                  <input type="text" id="lastName" name="lastName" value={formData.lastName}
                    autoComplete="family-name" required disabled={loading} aria-invalid={!!errors.lastName} aria-describedby={errors.lastName ? 'lastName-error' : undefined}
                    onChange={handleInputChange} placeholder="Doe" className="signup-input" />
                  {errors.lastName && <p id="lastName-error" className="signup-field-error" role="alert">{errors.lastName}</p>}
                </div>
              </div>
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
                  <strong>Group Invitation:</strong> Please sign up with {invitationEmail}
                </div>
              )}
              {error && (
                <div role="alert" style={{
                  padding: '0.75rem 1rem',
                  marginBottom: '1rem',
                  backgroundColor: 'rgba(220, 38, 38, 0.1)',
                  border: '1px solid rgba(220, 38, 38, 0.3)',
                  borderRadius: '0.5rem',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  color: '#c33'
                }}>
                  <AlertCircle size={18} />
                  <span style={{ fontSize: '0.9rem' }}>{error}</span>
                </div>
              )}
              <div className="signup-form-group">
                <label htmlFor="email" className="signup-label">Email Address</label>
                <input type="email" id="email" name="email" value={formData.email}
                  autoComplete="username" required disabled={loading} aria-invalid={!!errors.email} aria-describedby={errors.email ? 'email-error' : undefined}
                  onChange={handleInputChange} placeholder="passenger@email.com"
                  className={`signup-input ${formData.email && !isValidEmail(formData.email) ? 'error' : ''}`} />
                {errors.email && <p id="email-error" className="signup-field-error" role="alert">{errors.email}</p>}
              </div>
              <div className="signup-form-group">
                <label htmlFor="password" className="signup-label">Password</label>
                <input type="password" id="password" name="password" value={formData.password}
                  autoComplete="new-password" required disabled={loading} aria-invalid={!!errors.password} aria-describedby="password-requirements password-error"
                  onChange={handleInputChange} placeholder="Min. 8 characters"
                  className={`signup-input ${errors.password ? 'error' : ''}`} />
                <p id="password-requirements" className="signup-submit-hint">Use at least 8 characters with uppercase and lowercase letters, a number and a special character such as !, @ or #.</p>
                <p id="password-error" className="signup-field-error" role={errors.password ? 'alert' : undefined}>{errors.password || ''}</p>
                {formData.password && (
                  <div style={{
                    marginTop: '0.5rem',
                    fontSize: '0.85rem',
                    padding: '0.5rem 0.75rem',
                    background: passwordStrength.score <= 2 ? '#fee' : passwordStrength.score === 3 ? '#fef3c7' : '#d1fae5',
                    border: `1px solid ${passwordStrength.score <= 2 ? '#fcc' : passwordStrength.score === 3 ? '#fcd34d' : '#6ee7b7'}`,
                    borderRadius: '4px',
                    color: passwordStrength.score <= 2 ? '#c33' : passwordStrength.score === 3 ? '#b45309' : '#047857'
                  }}>
                    <strong>Strength: {passwordStrength.level}</strong> - {passwordStrength.message}
                  </div>
                )}
              </div>
              <div className="signup-form-group">
                <label htmlFor="confirmPassword" className="signup-label">Confirm Password</label>
                <input type="password" id="confirmPassword" name="confirmPassword" value={formData.confirmPassword}
                  autoComplete="new-password" required disabled={loading} aria-invalid={!!errors.confirmPassword} aria-describedby={errors.confirmPassword ? 'confirmPassword-error' : undefined}
                  onChange={handleInputChange} 
                  placeholder="Re-enter password"
                  className={`signup-input ${errors.confirmPassword ? 'error' : ''}`} />
                {errors.confirmPassword && <p id="confirmPassword-error" className="signup-field-error" role="alert">{errors.confirmPassword}</p>}
              </div>
              <button type="submit" className="signup-submit-button" disabled={loading || authLoading}>
                <UserPlus size={20} aria-hidden="true" />
                {loading ? 'Creating account...' : authLoading ? 'Checking your session...' : 'Create Account'}
              </button>
              <p className="signup-submit-hint">You will stay signed in on this device until you sign out or your session expires.</p>
            </form>
            
            <div className="signup-footer">
              <p className="signup-footer-text">
                Already have an account?{' '}
                <button onClick={() => onSwitchToLogin ? onSwitchToLogin() : navigate('/login' + location.search, { state: location.state })} className="signup-footer-link">
                  Board Your Raft
                </button>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Signup;
