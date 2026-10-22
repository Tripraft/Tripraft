// Purpose: Restores traveler sessions from cookies, handles signup/login/verification/logout, shares refresh work and exposes auth-state listeners without storing tokens locally.
/**
 * SQL Authentication Service
 * Handles authentication against the local SQL backend
 * JWT-based authentication service
 */

import GlobalConfig from '../config/globalConfig';

class SQLAuthService {
  constructor() {
    this.baseUrl = `${GlobalConfig.API_BASE_URL}${GlobalConfig.ENDPOINTS.AUTH}`;
    this.accessToken = null;
    this.refreshToken = null;
    this.currentUser = null;
    this.authStateListeners = [];
    
    // Refresh lock to prevent concurrent refresh attempts
    this._refreshPromise = null;
    this._isRefreshing = false;
    this._initializationPromise = null;
    this._authVersion = 0;
    
    // Load the optional cached profile; cookies carry the device session.
    this._loadStoredAuth();
  }

  /**
   * Load stored user profile from localStorage.
   * Tokens are handled by httpOnly cookies -- never stored in localStorage.
   */
  _loadStoredAuth() {
    try {
      // Storage is optional: httpOnly cookies own the device session.
      localStorage.removeItem(GlobalConfig.STORAGE_KEYS.ACCESS_TOKEN);
      localStorage.removeItem(GlobalConfig.STORAGE_KEYS.REFRESH_TOKEN);
      const userData = localStorage.getItem(GlobalConfig.STORAGE_KEYS.CURRENT_USER);
      if (userData) {
        this.currentUser = JSON.parse(userData);
        if (this.currentUser?.id) this.accessToken = '__cookie__';
        else this.currentUser = null;
      }
    } catch {
      this.currentUser = null;
    }
  }

  /**
   * Save user profile to localStorage.
   * Tokens live in httpOnly cookies set by the backend -- never in localStorage.
   */
  _saveAuth(accessToken, refreshToken, user) {
    this.accessToken = accessToken || '__cookie__';
    this.refreshToken = refreshToken;
    this.currentUser = user;

    // Only store non-sensitive user profile data
    try {
      localStorage.setItem(GlobalConfig.STORAGE_KEYS.CURRENT_USER, JSON.stringify(user));
    } catch { /* Cookie sessions also work when browser storage is unavailable. */ }
  }

  /**
   * Read the readable csrf_token cookie for the double-submit header.
   *
   * These two calls use raw fetch rather than apiClient, so they never sent
   * the header apiClient adds. That only went unnoticed because
   * /api/v1/auth/* used to be blanket-exempt from CSRF; it no longer is.
   */
  _csrfHeader() {
    const match = document.cookie.match(/(?:^|; )csrf_token=([^;]*)/);
    return match ? { 'X-CSRF-Token': decodeURIComponent(match[1]) } : {};
  }

  /**
   * Clear authentication state
   */
  _clearAuth() {
    this._authVersion += 1;
    this.accessToken = null;
    this.refreshToken = null;
    this.currentUser = null;

    try {
      localStorage.removeItem(GlobalConfig.STORAGE_KEYS.CURRENT_USER);
    } catch { /* Browser storage may be disabled. */ }
  }

  _requestError(data, fallback) {
    const error = data?.error;
    const details = error?.details;
    const messages = details && typeof details === 'object'
      ? Object.values(details).flat().filter(message => typeof message === 'string')
      : [];
    return {
      success: false,
      error: (typeof error === 'string' ? error : error?.code) || 'auth_failed',
      message: messages.join(' ') || error?.message || data?.message ||
        (typeof error === 'string' ? error : fallback),
    };
  }

  async _fetch(url, options) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), GlobalConfig.API_TIMEOUT || 30000);
    try {
      return await fetch(url, { ...options, signal: controller.signal });
    } finally {
      clearTimeout(timer);
    }
  }

  /**
   * Notify all auth state listeners
   */
  _notifyAuthStateChange(user) {
    this.authStateListeners.forEach(callback => {
      try {
        callback(user);
      } catch (err) {
        // auth state listener error handled silently
      }
    });
  }

  /**
   * Sign up with email and password
   */
  async signUpWithEmail(email, password, displayName = '') {
    // Explicit credentials take priority over any pending cookie restoration.
    this._authVersion += 1;
    try {
      const response = await this._fetch(`${this.baseUrl}/signup`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: email.trim().toLowerCase(),
          password,
          display_name: displayName || email.split('@')[0]
        }),
      });

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        return this._requestError(data, 'Could not create your account. Please try again.');
      }

      const payload = data.data || data;

      // Save auth and notify listeners
      if (!payload.user?.id) return this._requestError(null, 'The server returned an incomplete account. Please try signing in.');
      this._authVersion += 1;
      this._saveAuth(payload.access_token, payload.refresh_token, payload.user);
      this._notifyAuthStateChange(this._createUserObject(payload.user, payload.access_token));

      return {
        success: true,
        user: this._createUserObject(payload.user, payload.access_token),
        token: payload.access_token
      };
    } catch (error) {
      return {
        success: false,
        error: 'network_error',
        message: 'Unable to connect. Check your connection and try again.'
      };
    }
  }

  /**
   * Sign in with email and password
   */
  async signInWithEmail(email, password) {
    // Explicit credentials take priority over any pending cookie restoration.
    this._authVersion += 1;
    try {
      const response = await this._fetch(`${this.baseUrl}/login`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email: email.trim().toLowerCase(), password }),
      });

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        return this._requestError(data, 'Could not sign in. Please try again.');
      }

      const payload = data.data || data;

      // Save auth and notify listeners
      if (!payload.user?.id) return this._requestError(null, 'The server returned an incomplete account. Please try again.');
      this._authVersion += 1;
      this._saveAuth(payload.access_token, payload.refresh_token, payload.user);
      this._notifyAuthStateChange(this._createUserObject(payload.user, payload.access_token));

      return {
        success: true,
        user: this._createUserObject(payload.user, payload.access_token),
        token: payload.access_token
      };
    } catch (error) {
      return {
        success: false,
        error: 'network_error',
        message: 'Unable to connect. Check your connection and try again.'
      };
    }
  }

  /**
   * Confirm ownership using the public verification endpoint; no session required.
   */
  async verifyEmail(token) {
    const response = await this._fetch(`${this.baseUrl}/verify-email?${new URLSearchParams({ token })}`, {
      method: 'GET', credentials: 'omit', cache: 'no-store',
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data.success !== true) {
      return { success: false, status: response.ok ? 502 : response.status,
        message: data.error?.message || data.message || 'This verification link is invalid or has expired.' };
    }
    if (this.currentUser) await this.getCurrentUserFromBackend();
    return { success: true, message: data.data?.message || data.message || 'Email verified successfully' };
  }

  async requestPasswordReset(email) {
    return this._passwordRecovery('forgot-password', { email: email.trim().toLowerCase() });
  }

  async resetPassword(token, newPassword) {
    return this._passwordRecovery('reset-password', { token, new_password: newPassword });
  }

  async _passwordRecovery(endpoint, body) {
    try {
      const response = await this._fetch(`${this.baseUrl}/${endpoint}`, {
        method: 'POST', credentials: 'omit', cache: 'no-store',
        headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
      });
      const data = await response.json().catch(() => ({}));
      if (!response.ok || data.success !== true) return this._requestError(data, 'Could not complete password recovery. Please try again.');
      return { success: true, message: data.data?.message || data.message };
    } catch {
      return { success: false, message: 'Unable to connect. Check your connection and try again.' };
    }
  }

  async resendVerificationEmail() {
    const response = await this._fetch(`${this.baseUrl}/resend-verification`, {
      method: 'POST', credentials: 'include',
      headers: { 'Content-Type': 'application/json', ...this._csrfHeader() },
    });
    const data = await response.json().catch(() => ({}));
    return { success: response.ok && data.success === true,
      message: data.error?.message || data.data?.message || data.message || 'Could not send a verification email. Please try again.' };
  }

  /**
   * Sign out
   */
  async signOut() {
    // Invalidate pending restoration before waiting on the server.
    this._clearAuth();
    this._notifyAuthStateChange(null);
    try {
      // Call backend to clear httpOnly auth cookies
      await this._fetch(`${this.baseUrl}/logout`, {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json', ...this._csrfHeader() },
      }).catch(() => {});

      return { success: true };
    } catch (error) {
      return {
        success: false,
        error: 'signout_error',
        message: error.message
      };
    }
  }

  /**
   * Refresh access token using refresh token
   * Uses a lock to prevent concurrent refresh attempts (race condition fix)
   */
  async refreshAccessToken() {
    // The refresh token always lives in an httpOnly cookie, so the attempt is
    // always worth making and the server decides. The old guard refused
    // whenever this.refreshToken was null unless accessToken happened to be
    // the literal '__cookie__', which meant an expired token in pure cookie
    // mode could never be refreshed and every 401 became a logout.

    // If already refreshing, wait for the existing refresh to complete
    if (this._isRefreshing && this._refreshPromise) {
      return this._refreshPromise;
    }

    // Set the lock
    this._isRefreshing = true;
    
    const version = this._authVersion;
    const refresh = async () => {
      try {
        if (version !== this._authVersion) return { success: false, error: 'session_changed' };
        const response = await this._fetch(`${this.baseUrl}/refresh`, {
          method: 'POST',
          credentials: 'include',
          headers: {
            'Content-Type': 'application/json',
            ...this._csrfHeader(),
          },
          // The browser cookie is shared across tabs and always holds the
          // latest rotated token; an in-memory token may already be stale.
          body: '{}',
        });

        const data = await response.json().catch(() => ({}));
        if (version !== this._authVersion) return { success: false, error: 'session_changed' };

        if (!response.ok) {
          // Only a rejected session should end it. The previous condition
          // was `if (this._isRefreshing)`, which is always true inside this
          // locked block, so a 500 or a gateway blip logged the user out.
          if (response.status === 401) {
            this._clearAuth();
            this._notifyAuthStateChange(null);
          }
          return this._requestError(data, 'Could not restore your session. Please try again.');
        }
        
        // Update in-memory token reference (actual tokens in httpOnly cookies)
        const payload = data.data || data;
        this.accessToken = payload.access_token || '__cookie__';
        
        if (payload.refresh_token) {
          this.refreshToken = payload.refresh_token;
        }

        return {
          success: true,
          token: payload.access_token
        };
      } catch (error) {
        return {
          success: false,
          error: 'network_error',
          message: error.message
        };
      } finally {
        // Release the lock
        this._isRefreshing = false;
        this._refreshPromise = null;
      }
    };
    // Serialize rotations across tabs on browsers supporting Web Locks.
    this._refreshPromise = globalThis.navigator?.locks?.request
      ? navigator.locks.request('tripraft-session-refresh', refresh)
      : refresh();

    return this._refreshPromise;
  }

  /**
   * Get current user profile from backend
   */
  async getCurrentUserFromBackend() {
    const version = this._authVersion;
    try {
      const loadProfile = () => this._fetch(`${this.baseUrl}/me`, {
        method: 'GET', credentials: 'include',
        headers: this.accessToken && this.accessToken !== '__cookie__'
          ? { Authorization: `Bearer ${this.accessToken}` } : {},
      });
      let response = await loadProfile();
      if (version !== this._authVersion) return this.getCurrentUser();
      if (response.status === 401) {
        const refreshed = await this.refreshAccessToken();
        if (version !== this._authVersion) return this.getCurrentUser();
        if (!refreshed.success) return this.getCurrentUser();
        response = await loadProfile();
        if (version !== this._authVersion) return this.getCurrentUser();
      }
      if (response.ok) {
        const data = await response.json();
        if (version !== this._authVersion) return this.getCurrentUser();
        const payload = data.data || data;
        if (payload.user?.id) {
          this._saveAuth(this.accessToken, this.refreshToken, payload.user);
          return this.getCurrentUser();
        }
      } else if (response.status === 401 || response.status === 403) {
        this._clearAuth();
        return null;
      }
    } catch { /* Temporary outages must not erase this device's saved session. */ }
    return this.getCurrentUser();
  }

  /**
   * Get current user (from memory)
   */
  getCurrentUser() {
    if (!this.currentUser || !this.accessToken) {
      return null;
    }
    return this._createUserObject(this.currentUser, this.accessToken);
  }

  /**
   * Get current ID token (access token)
   */
  async getIdToken() {
    // Cookie-mode: real token is in httpOnly cookie, not accessible to JS
    if (!this.accessToken || this.accessToken === '__cookie__') {
      return null;
    }
    try {
      const payload = JSON.parse(atob(this.accessToken.split('.')[1]));
      const now = Math.floor(Date.now() / 1000);
      if (payload.exp && payload.exp - now < 60) {
        const result = await this.refreshAccessToken();
        if (result.success) {
          return result.token;
        }
      }
    } catch (e) {
      // If we can't decode token, just return it
    }
    return this.accessToken;
  }

  /**
   * Listen to auth state changes
   * Auth state change listener
   */
  onAuthStateChanged(callback) {
    // Add listener
    this.authStateListeners.push(callback);

    // Cookies can survive without a cached profile. Share initialization across
    // subscribers (including React StrictMode), and ignore unsubscribed listeners.
    if (!this._initializationPromise) {
      this._initializationPromise = this.getCurrentUserFromBackend();
      this._initializationPromise.finally(() => { this._initializationPromise = null; });
    }
    this._initializationPromise.then(() => {
      if (this.authStateListeners.includes(callback)) callback(this.getCurrentUser());
    });

    // Return unsubscribe function
    return () => {
      const index = this.authStateListeners.indexOf(callback);
      if (index > -1) {
        this.authStateListeners.splice(index, 1);
      }
    };
  }

  /**
   * Create a user object compatible with the existing app structure
   */
  _createUserObject(userData, token) {
    return {
      uid: String(userData.id), // String for compatibility
      id: userData.id,
      email: userData.email,
      displayName: userData.display_name || String(userData.email || '').split('@')[0],
      photoURL: userData.profile_picture || '',
      emailVerified: Boolean(userData.email_verified),
      is_admin: Boolean(userData.is_admin),
      
      // Method to get token
      getIdToken: async (forceRefresh = false) => {
        if (forceRefresh) {
          const result = await this.refreshAccessToken();
          if (result.success) return result.token;
        }
        if (!this.accessToken || this.accessToken === '__cookie__') return null;
        return this.accessToken;
      }
    };
  }

  /**
   * Verify token with backend (no-op for SQL auth since token is already from backend)
   */
  async verifyWithBackend(idToken) {
    try {
      const headers = { 'Content-Type': 'application/json' };
      if (idToken && idToken !== '__cookie__') {
        headers['Authorization'] = `Bearer ${idToken}`;
      }
      const response = await fetch(`${this.baseUrl}/me`, {
        method: 'GET',
        credentials: 'include',
        headers,
      });

      if (response.ok) {
        const data = await response.json();
        return { success: true, user: data.data?.user || data.user };
      }

      return { success: false, error: 'Invalid token' };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }
}

const sqlAuthService = new SQLAuthService();
export default sqlAuthService;
