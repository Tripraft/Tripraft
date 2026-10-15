// Purpose: Shares signup validation and safe return destinations between auth forms.
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

export const passwordError = password => {
  if (password.length < 8) return 'Use at least 8 characters.';
  if (new TextEncoder().encode(password).length > 72) return 'Use a password of at most 72 bytes (72 characters for English text).';
  if (!/\p{Lu}/u.test(password)) return 'Add at least one uppercase letter.';
  if (!/\p{Ll}/u.test(password)) return 'Add at least one lowercase letter.';
  if (!/\p{Nd}/u.test(password)) return 'Add at least one number.';
  if (![...password].some(char => '!@#$%^&*()_+-=[]{}|;:,./<>?'.includes(char))) {
    return 'Add at least one special character, such as !, @ or #.';
  }
  return '';
};

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
