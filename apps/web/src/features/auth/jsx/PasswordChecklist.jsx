// Purpose: Shows the same live password requirements used by submission validation.
import React from 'react';
import { passwordRequirements } from '../utils/authForms';
import '../css/PasswordFields.css';

export default function PasswordChecklist({ password }) {
  return <ul id="password-requirements" className="auth-password-checklist" aria-label="Password requirements">
    {passwordRequirements(password).map(({ label, met }) => <li key={label} data-met={met}>
      <span aria-hidden="true">{met ? '✓' : '○'}</span>
      <span className="auth-visually-hidden">{met ? 'Met: ' : 'Required: '}</span>{label}
    </li>)}
  </ul>;
}
