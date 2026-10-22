// Purpose: Provides auth validation, storage helpers that tolerate unavailable browser storage, and invitation/return-destination handling.
export const isValidEmail = email => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());

export const readAuthStorage = key => {
  try { return localStorage.getItem(key); } catch { return null; }
};

export const writeAuthStorage = (key, value) => {
  try { localStorage.setItem(key, value); } catch { /* Invitations can also use the return URL. */ }
};

export const removeAuthStorage = key => {
  try { localStorage.removeItem(key); } catch { /* The invitation ID also lives in the URL. */ }
};

export const rememberExpenseInvitation = invitationId => {
  const cachedEmail = readAuthStorage('pendingInvitation') === invitationId
    ? readAuthStorage('invitationEmail') || '' : '';
  writeAuthStorage('pendingInvitation', invitationId);
  writeAuthStorage('invitationEmail', cachedEmail);
  return cachedEmail;
};

export const invitationDestination = search => {
  const params = new URLSearchParams(search);
  const directExpenseInvite = params.get('redirect') === 'invitation' && params.get('invitationId');
  if (directExpenseInvite) return (params.get('type') === 'group' ? '/invitations/' : '/invitation/') + encodeURIComponent(directExpenseInvite);
  const groupInvite = readAuthStorage('pendingGroupInvitation');
  if (groupInvite) return '/invitations/' + encodeURIComponent(groupInvite);
  const expenseInvite = readAuthStorage('pendingInvitation');
  return expenseInvite ? '/invitation/' + encodeURIComponent(expenseInvite) : null;
};

export const passwordRequirements = password => [
  { label: 'At least 8 characters', met: [...password].length >= 8, error: 'Use at least 8 characters.' },
  { label: 'At most 72 UTF-8 bytes (72 English characters)', met: new TextEncoder().encode(password).length <= 72, error: 'Use a password of at most 72 bytes (72 characters for English text).' },
  { label: 'One uppercase letter', met: /\p{Lu}/u.test(password), error: 'Add at least one uppercase letter.' },
  { label: 'One lowercase letter', met: /\p{Ll}/u.test(password), error: 'Add at least one lowercase letter.' },
  { label: 'One number', met: /\p{Nd}/u.test(password), error: 'Add at least one number.' },
  { label: 'One special character: !@#$%^&*()_+-=[]{}|;:,./<>?', met: [...password].some(char => '!@#$%^&*()_+-=[]{}|;:,./<>?'.includes(char)), error: 'Add at least one special character, such as !, @ or #.' },
];

export const passwordError = password => passwordRequirements(password).find(item => !item.met)?.error || '';

export const signupErrors = data => {
  const errors = {};
  if (!data.firstName.trim()) errors.firstName = 'Enter your first name.';
  if (!data.lastName.trim()) errors.lastName = 'Enter your last name.';
  if (`${data.firstName.trim()} ${data.lastName.trim()}`.length > 100) errors.lastName = 'Use a full name of at most 100 characters.';
  if (!isValidEmail(data.email)) errors.email = 'Enter a valid email address.';
  const message = passwordError(data.password);
  if (message) errors.password = message;
  if (!data.confirmPassword || data.password !== data.confirmPassword) errors.confirmPassword = 'Passwords do not match.';
  return errors;
};

export const returnDestination = location => {
  const from = location.state?.from;
  const path = from?.pathname;
  if (!path?.startsWith('/') || path.startsWith('//') || ['/login', '/signup', '/auth'].includes(path)) return '/';
  return path + (from.search || '') + (from.hash || '');
};
