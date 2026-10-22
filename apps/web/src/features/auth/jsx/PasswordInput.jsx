// Purpose: Provides an accessible visibility toggle without changing password values or autofill.
import React, { useState } from 'react';
import { Eye, EyeOff } from 'lucide-react';
import '../css/PasswordFields.css';

export default function PasswordInput({ visibilityLabel = 'password', ...props }) {
  const [visible, setVisible] = useState(false);
  return <div className="auth-password-field">
    <input {...props} type={visible ? 'text' : 'password'} />
    <button type="button" className="auth-password-toggle" disabled={props.disabled}
      aria-label={`${visible ? 'Hide' : 'Show'} ${visibilityLabel}`} aria-pressed={visible}
      aria-controls={props.id} onClick={() => setVisible(value => !value)}>
      {visible ? <EyeOff size={20} aria-hidden="true" /> : <Eye size={20} aria-hidden="true" />}
    </button>
  </div>;
}
