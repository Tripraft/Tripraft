// Purpose: Wraps expense profiles, groups, members, invitations, expenses, settlements, balances, analytics and bootstrap endpoints using the shared API client.
/**
 * Expense Management API Service
 * Connects frontend to the expense backend with multi-currency support.
 *
 * All HTTP, auth, timeout, retry, and error handling is delegated to apiClient.
 */

import apiClient from '../utils/apiClient';
import GlobalConfig from '../config/globalConfig';

const BASE = GlobalConfig.ENDPOINTS.EXPENSE;
const AUTH_BASE = GlobalConfig.ENDPOINTS.AUTH;

class ExpenseApiService {
  // No-ops kept for backward compatibility with AuthContext / useExpenseQuery
  setAuthToken() {}
  setCurrentUser() {}

  // =========================================================================
  // USER OPERATIONS
  // =========================================================================

  /**
   * Create or update user profile
   */
  async createUser(userData) {
    return apiClient.post(`${AUTH_BASE}/user/profile`, {
      username: userData.email.split('@')[0],
      display_name: userData.displayName || '',
      profile_picture: userData.photoURL || null
    });
  }

  /**
   * Get current user profile
   */
  async getUser() {
    return apiClient.get(`${AUTH_BASE}/user/profile`);
  }

  /**
   * Update user profile
   */
  async updateUser(updates) {
    return apiClient.put(`${AUTH_BASE}/user/profile`, updates);
  }

  /** Private contacts are reusable across expense groups, without sending mail. */
  async getFriends({search = '', limit = 50, offset = 0} = {}) {
    return apiClient.get(`${BASE}/friends?${new URLSearchParams({search, limit, offset})}`);
  }

  async saveFriend({email, nickname}) {
    return apiClient.post(`${BASE}/friends`, {email, ...(nickname !== undefined && {nickname})});
  }

  /**
   * Get user's groups
   */
  async getUserGroups(summaryMode = true, bypassCache = false) {
    const mode = summaryMode ? 'summary' : 'full';
    const params = new URLSearchParams({ mode });
    if (bypassCache) params.append('_t', Date.now());
    return apiClient.get(`${BASE}/groups?${params}`);
  }

  /**
   * Search for users
   */
  async searchUsers(query) {
    return apiClient.get(`${AUTH_BASE}/user/search?q=${encodeURIComponent(query)}`);
  }

  // =========================================================================
  // GROUP OPERATIONS
  // =========================================================================

  async createGroup(groupData) {
    return apiClient.post(`${BASE}/groups`, groupData);
  }

  async getGroup(groupId) {
    return apiClient.get(`${BASE}/groups/${groupId}`);
  }

  async getGroupFull(groupId, bypassCache = false) {
    // Full-page summaries and exports need the entire ledger, not the default first 50 rows.
    let expenseOffset = 0;
    let settlementOffset = 0;
    let combined;
    for (;;) {
      const params = new URLSearchParams({ expense_limit: 100, settlement_limit: 100,
        expense_offset: expenseOffset, settlement_offset: settlementOffset, include_deleted: true });
      if (bypassCache) params.set('_t', Date.now());
      const response = await apiClient.get(`${BASE}/groups/${groupId}/full?${params}`);
      const data = response?.data ?? response;
      const page = data.group;
      if (!page) throw new Error('Group details are unavailable.');
      if (!combined) combined = { ...page, expenses: [], settlements: [] };
      const expenses = page.expenses || [];
      const settlements = page.settlements || [];
      combined.expenses.push(...expenses);
      combined.settlements.push(...settlements);
      expenseOffset += expenses.length;
      settlementOffset += settlements.length;
      const moreExpenses = page.expense_pagination?.has_more;
      const moreSettlements = page.settlement_pagination?.has_more;
      if (!moreExpenses && !moreSettlements) break;
      if ((moreExpenses && !expenses.length) || (moreSettlements && !settlements.length)) {
        throw new Error('Group history changed while loading. Please refresh.');
      }
    }
    // Offsets advance independently; exhausted lists return no rows on later requests.
    combined.expenses = [...new Map(combined.expenses.map(row => [row.id || row.expense_id, row])).values()];
    combined.settlements = [...new Map(combined.settlements.map(row => [row.id || row.settlement_id, row])).values()];
    combined.expense_pagination = { total: combined.expenses.length, offset: 0, limit: combined.expenses.length, has_more: false };
    combined.settlement_pagination = { total: combined.settlements.length, offset: 0, limit: combined.settlements.length, has_more: false };
    return { success: true, data: { group: combined } };
  }

  async updateGroup(groupId, updates) {
    return apiClient.put(`${BASE}/groups/${groupId}`, updates);
  }

  async deleteGroup(groupId) {
    return apiClient.delete(`${BASE}/groups/${groupId}`);
  }

  async getGroupMembers(groupId) {
    return apiClient.get(`${BASE}/groups/${groupId}/members`);
  }

  async addGroupMember(groupId, memberData) {
    return apiClient.post(`${BASE}/groups/${groupId}/members`, memberData);
  }

  async updateGroupMemberRole(groupId, userId, role) {
    return apiClient.patch(`${BASE}/groups/${groupId}/members/${userId}`, { role });
  }

  async leaveGroup(groupId) {
    return apiClient.post(`${BASE}/groups/${groupId}/leave`);
  }

  async removeGroupMember(groupId, userId) {
    return apiClient.delete(`${BASE}/groups/${groupId}/members/${userId}`);
  }

  // =========================================================================
  // INVITATION OPERATIONS
  // =========================================================================

  async sendInvitation(invitationData) {
    return apiClient.post(`${BASE}/invitations`, invitationData);
  }

  async getInvitationDetails(invitationId) {
    return apiClient.get(`${BASE}/invitations/${invitationId}/details`);
  }

  async acceptInvitation(invitationId) {
    return apiClient.post(`${BASE}/invitations/${invitationId}/accept`);
  }

  async resendInvitation(invitationId) {
    return apiClient.post(`${BASE}/invitations/${invitationId}/resend`);
  }

  async cancelInvitation(invitationId) {
    return apiClient.post(`${BASE}/invitations/${invitationId}/cancel`);
  }

  async declineInvitation(invitationId) {
    return apiClient.post(`${BASE}/invitations/${invitationId}/decline`);
  }

  async getPendingInvitations() {
    return apiClient.get(`${BASE}/invitations`);
  }

  async getGroupInvitations(groupId, timestamp = null) {
    const params = timestamp ? `?_t=${timestamp}` : '';
    return apiClient.get(`${BASE}/invitations/group/${groupId}${params}`);
  }

  // =========================================================================
  // EXPENSE OPERATIONS
  // =========================================================================

  async createExpense(expenseData) {
    return apiClient.post(`${BASE}`, expenseData);
  }

  async getExpense(expenseId) {
    return apiClient.get(`${BASE}/${expenseId}`);
  }

  async updateExpense(expenseId, updates) {
    return apiClient.put(`${BASE}/${expenseId}`, updates);
  }

  async deleteExpense(expenseId) {
    return apiClient.delete(`${BASE}/${expenseId}`);
  }

  async restoreExpense(expenseId) {
    return apiClient.post(`${BASE}/${expenseId}/restore`);
  }

  async getGroupExpenses(groupId, params = {}) {
    const queryParams = new URLSearchParams(params).toString();
    const qs = queryParams ? `?${queryParams}` : '';
    return apiClient.get(`${BASE}/group/${groupId}${qs}`);
  }

  async getUserExpenses(params = {}) {
    const queryParams = new URLSearchParams(params).toString();
    const qs = queryParams ? `?${queryParams}` : '';
    return apiClient.get(`${BASE}/user${qs}`);
  }

  async getExpenseSplits(expenseId) {
    return apiClient.get(`${BASE}/${expenseId}/splits`);
  }

  async getExpenseHistory(expenseId) {
    return apiClient.get(`${BASE}/${expenseId}/history`);
  }

  // =========================================================================
  // SETTLEMENT OPERATIONS
  // =========================================================================

  async createSettlement(settlementData) {
    return apiClient.post(`${BASE}/settlements`, settlementData);
  }

  async deleteSettlement(settlementId) {
    return apiClient.delete(`${BASE}/settlements/${settlementId}`);
  }

  async getSettlement(settlementId) {
    return apiClient.get(`${BASE}/settlements/${settlementId}`);
  }

  async confirmSettlement(settlementId) {
    return apiClient.post(`${BASE}/settlements/${settlementId}/confirm`);
  }

  async cancelSettlement(settlementId) {
    return apiClient.post(`${BASE}/settlements/${settlementId}/cancel`);
  }

  async getGroupSettlements(groupId, status = null) {
    const qs = status ? `?status=${status}` : '';
    return apiClient.get(`${BASE}/settlements/group/${groupId}${qs}`);
  }

  async getUserSettlements(uid, status = null) {
    const qs = status ? `?status=${status}` : '';
    return apiClient.get(`${BASE}/settlements/user/${uid}${qs}`);
  }

  // =========================================================================
  // BALANCE OPERATIONS
  // =========================================================================

  async getGroupBalances(groupId) {
    return apiClient.get(`${BASE}/balances/group/${groupId}`);
  }

  async getUserBalances(uid) {
    return apiClient.get(`${BASE}/balances/user/${uid}`);
  }

  async getUserBalance(uid, groupId) {
    return apiClient.get(`${BASE}/balances/user/${uid}/group/${groupId}`);
  }

  async getSimplifiedDebts(groupId) {
    return apiClient.get(`${BASE}/balances/group/${groupId}/simplified`);
  }

  async recalculateBalances(groupId) {
    return apiClient.post(`${BASE}/balances/group/${groupId}/recalculate`);
  }

  // =========================================================================
  // ANALYTICS OPERATIONS
  // =========================================================================

  async getGroupAnalytics(groupId) {
    return apiClient.get(`${BASE}/analytics/group/${groupId}`);
  }

  async getUserAnalytics(uid) {
    return apiClient.get(`${BASE}/analytics/user/${uid}`);
  }

  async getExpenseTrends(groupId, period = 'month') {
    return apiClient.get(`${BASE}/analytics/group/${groupId}/trends?period=${period}`);
  }

  // =========================================================================
  // MEGA BOOTSTRAP
  // =========================================================================

  async getMegaBootstrap(options = {}) {
    const { activeGroupId, recentExpensesLimit = GlobalConfig.EXPENSE_RECENT_LIMIT, bypassCache = false } = options;
    const params = new URLSearchParams();
    if (activeGroupId) params.append('active_group_id', activeGroupId);
    if (recentExpensesLimit) params.append('recent_expenses_limit', recentExpensesLimit);
    if (bypassCache) params.append('_t', Date.now());
    const qs = params.toString() ? `?${params.toString()}` : '';
    return apiClient.get(`${AUTH_BASE}/mega-bootstrap${qs}`);
  }

  async getExtremeDashboard(forceRefresh = false) {
    const qs = forceRefresh ? '?force_refresh=true' : '';
    return apiClient.get(`${AUTH_BASE}/extreme-dashboard${qs}`);
  }
}

const expenseApi = new ExpenseApiService();
export default expenseApi;
