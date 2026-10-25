// Purpose: Coordinates personal/group expense data, group selection, transaction editing, invitations, settlements, history, PDF export and live refresh.
/**
 * Uses the expense query hooks for ledger state and API mutations for user actions.
 * Live notifications invalidate server data; local state owns selection and dialogs.
 */

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { useParams, useNavigate, useSearchParams } from 'react-router-dom';
import ExpenseSummary from './ExpenseSummary';
import CurrencySelect from '../../../components/common/jsx/CurrencySelect';
import CurrencyConversion from '../../../components/common/jsx/CurrencyConversion';
import usePersonalDashboard from '../../../hooks/usePersonalDashboard';
import usePersonalCurrency from '../../../hooks/usePersonalCurrency';

import TransactionModal from './TransactionModal';
import GroupManager from './GroupManager';
import GroupDashboard from './GroupDashboard';
import ExpenseDialog from './ExpenseDialog';
import GroupDetailHeader from './GroupDetailHeader';
import NewExpenseGroupModal from './NewExpenseGroupModal';
import { groupOverview } from '../utils/groupOverview';

import GroupSummaryCards from './GroupSummaryCards';
import SettlementHistoryModal from './SettlementHistoryModal';
import TabbedGroupView from './TabbedGroupView';
import PersonalTabbedView from './PersonalTabbedView';
import ModeToggle from './ModeToggle';
import PendingInvitations from './PendingInvitations';


import Toast from '@tripraft/ui/Toast';
import ErrorBoundary from '../../../components/common/jsx/ErrorBoundary';
import { PlusCircle, RefreshCw } from 'lucide-react';
import expenseApi from '../../../services/expenseApi';
import useExpenseLiveUpdates from '../../../hooks/useExpenseLiveUpdates';
import { generateExpensePDF } from '../../../services/pdfExportService';
import {
  useAuth,
  useGroups,
  useGroupDetail,
  useInvitations,
  usePersonalExpenses
} from '../../../hooks/useExpenseQuery';
import '../css/ExpenseManager.css';
import '../css/ExpenseGroups.css';
import '../css/ExpenseResponsive.css';
import { expensePayload } from '../../../utils/money';

/** Unwrap backend response envelope { success, data, meta } -> inner data */
const unwrapEnvelope = (r) => (r && typeof r === 'object' && 'success' in r && 'data' in r) ? r.data : r;

const ExpenseManager = () => {
  const navigate = useNavigate();
  const { userId: routeUserId, mode: routeMode } = useParams();
  const [searchParams] = useSearchParams();
  const mode = routeMode === 'group' || (!routeMode && searchParams.get('view') === 'group') ? 'group' : 'personal';
  const activeGroupId = mode === 'group' ? searchParams.get('groupId') : null;
  
  // Auth state
  const { isAuthenticated, currentUser, loading: authLoading } = useAuth();
  const currencyPreference = usePersonalCurrency(currentUser?.uid || currentUser?.user_id || currentUser?.id, mode === 'personal' && isAuthenticated);
  const personalCurrency = currencyPreference.currency;
  useExpenseLiveUpdates(isAuthenticated ? currentUser?.uid || currentUser?.user_id || currentUser?.id : null, activeGroupId);
  
  // Query-backed account/group data; live invalidation is handled above.
  const {
    groups,
    loading: groupsLoading,
    error: groupsError,
    refetch: refetchGroups,
    updateGroupsFromResponse,  // INSTANT UPDATE helper
    setGroups
  } = useGroups();
  
  const [state, setState] = useState({
    editingTransactionId: null,
    filter: { type: 'all', sortBy: 'date-desc' }
  });
  
  // Group detail (only when group is selected) - with INSTANT UPDATE helpers
  const {
    group: activeGroupData,
    members: activeGroupMembers,
    expenses: activeGroupExpenses,
    balances: activeGroupBalances,
    settlements: activeGroupSettlements,
    invitations: groupInvitations,
    loading: groupDetailLoading,
    error: groupDetailError,
    refetch: refetchGroupDetail,
    updateFromResponse: updateGroupDetailFromResponse,  // INSTANT UPDATE helper
    updateExpensesAndBalances,  // INSTANT UPDATE helper
    updateSettlementsAndBalances,  // INSTANT UPDATE helper for settlements
    updateMembers  // INSTANT UPDATE helper
  } = useGroupDetail(activeGroupId);
  
  // Invitations for current user - with INSTANT UPDATE helpers
  const {
    invitations,
    loading: invitationsLoading,
    refetch: refetchInvitations,
    updateInvitationsFromResponse,  // INSTANT UPDATE helper
    removeInvitation  // INSTANT UPDATE helper
  } = useInvitations();
  
  // Personal expenses
  const {
    expenses: personalExpenses,
    loading: personalLoading,
    refetch: refetchPersonalExpenses,
    markAsDeleted: markPersonalAsDeleted,
    rollbackDelete: rollbackPersonalDelete
  } = usePersonalExpenses();

  const personalDashboard = usePersonalDashboard(personalExpenses || [], personalCurrency || 'USD', mode === 'personal' && Boolean(personalCurrency));
  const personalConversionPending = !personalCurrency || personalDashboard.loading || Boolean(personalDashboard.error);

  // UI State
  const [showTransactionModal, setShowTransactionModal] = useState(false);
  const [showAlertModal, setShowAlertModal] = useState(false);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [alertMessage, setAlertMessage] = useState('');
  const [confirmMessage, setConfirmMessage] = useState('');
  const [confirmCallback, setConfirmCallback] = useState(null);
  const [refreshing, setRefreshing] = useState(false);
  const [toasts, setToasts] = useState([]);
  const [isHistoryModalOpen, setIsHistoryModalOpen] = useState(false);
  const [mutationLoading, setMutationLoading] = useState(false);
  const [showNewGroup, setShowNewGroup] = useState(false);
  const [groupTab, setGroupTab] = useState('balances');
  const groupTabsRef = useRef(null);
  const addTransactionRef = useRef(null);
  const [showFloatingAdd, setShowFloatingAdd] = useState(false);
  useEffect(() => {
    const button = addTransactionRef.current;
    if (mode !== 'personal' || !button) return;
    const update = () => {
      const rect = button.getBoundingClientRect();
      setShowFloatingAdd(rect.top < 0 && rect.bottom <= 0);
    };
    update();
    if (typeof IntersectionObserver !== 'undefined') {
      const observer = new IntersectionObserver(([entry]) => setShowFloatingAdd(entry.boundingClientRect.top < 0 && entry.boundingClientRect.bottom <= 0));
      observer.observe(button);
      return () => observer.disconnect();
    }
    window.addEventListener('scroll', update, true);
    window.addEventListener('resize', update);
    return () => { window.removeEventListener('scroll', update, true); window.removeEventListener('resize', update); };
  }, [mode, authLoading, isAuthenticated]);
  const openGroupTab = tab => {
    setGroupTab(tab);
    // The cards sit above the tab content, often outside the current viewport.
    groupTabsRef.current?.scrollIntoView?.({ behavior: window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth', block: 'start' });
    groupTabsRef.current?.querySelector(`#group-tab-${tab}`)?.focus({ preventScroll: true });
  };

  const setExpenseView = useCallback((nextMode, groupId, options = {}) => {
    const userId = currentUser?.uid || currentUser?.user_id;
    if (!userId) return;
    const query = nextMode === 'group' && groupId
      ? `?${new URLSearchParams({ groupId })}` : '';
    navigate(`/expenses/${userId}/${nextMode}${query}`, options);
  }, [currentUser, navigate]);

  // Canonicalize legacy URLs without losing the selected invitation group.
  useEffect(() => {
    if (authLoading || !currentUser) return;
    if (routeMode !== mode || routeUserId !== (currentUser.uid || currentUser.user_id)) {
      setExpenseView(mode, activeGroupId, { replace: true });
    }
  }, [routeMode, routeUserId, mode, activeGroupId, currentUser, authLoading, setExpenseView]);

  // A pending action belongs to the group where it was opened.
  useEffect(() => {
    setShowTransactionModal(false);
    setGroupTab('balances');
    setShowConfirmModal(false);
    setIsHistoryModalOpen(false);
    setState(previous => ({ ...previous, editingTransactionId: null }));
  }, [activeGroupId, mode]);

  useEffect(() => {
    if (mode === 'group' && groupDetailError && !activeGroupData) {
      setShowTransactionModal(false);
      setShowConfirmModal(false);
      setIsHistoryModalOpen(false);
      setState(previous => ({ ...previous, editingTransactionId: null }));
    }
  }, [mode, groupDetailError, activeGroupData]);

  // Helper functions
  const showAlert = (message) => {
    setAlertMessage(message);
    setShowAlertModal(true);
  };
  
  const showToast = (message, type = 'success') => {
    const id = Date.now();
    setToasts(prev => [...prev, { id, message, type }]);
  };
  
  const hideToast = (id) => {
    setToasts(prev => prev.filter(toast => toast.id !== id));
  };

  const showConfirm = (message, callback) => {
    setConfirmMessage(message);
    setConfirmCallback(() => callback);
    setShowConfirmModal(true);
  };

  // Get current transactions based on mode
  const getCurrentTransactions = () => {
    if (mode === 'personal') {
      return personalDashboard.transactions;
    }
    if (!activeGroupId) return [];
    return activeGroupExpenses || [];
  };
  
  // Get current balances
  const getCurrentBalances = () => {
    if (mode === 'personal') return null;
    if (!activeGroupId) return null;
    
    let balances = activeGroupBalances || [];
    
    // Handle various balance formats
    if (!Array.isArray(balances) && typeof balances === 'object') {
      if (Object.keys(balances).length === 0) return [];
      
      if (balances.member_balances && Array.isArray(balances.member_balances)) {
        return balances.member_balances;
      }
      
      if (balances.member_balances && typeof balances.member_balances === 'object') {
        return Object.entries(balances.member_balances).map(([userId, balance]) => ({
          user_id: userId,
          balance: parseFloat(balance) || 0,
          net_balance: parseFloat(balance) || 0
        }));
      }
      
      const firstValue = Object.values(balances)[0];
      if (typeof firstValue === 'number' || typeof firstValue === 'string') {
        return Object.entries(balances).map(([userId, balance]) => ({
          user_id: userId,
          balance: parseFloat(balance) || 0,
          net_balance: parseFloat(balance) || 0
        }));
      }
      
      return [];
    }
    
    return Array.isArray(balances) ? balances : [];
  };

  // Build members map
  const getAllMembersMap = () => {
    const map = {};
    (activeGroupMembers || []).forEach(m => {
      const userId = m.user_id || m.id;
      if (userId) {
        map[userId] = {
          user_id: userId,
          display_name: m.display_name || m.username || 'Unknown',
          email: m.email
        };
      }
    });
    return map;
  };

  // Event Handlers
  const handleModeToggle = () => {
    setExpenseView(mode === 'personal' ? 'group' : 'personal');
  };

  const handleGroupChange = (groupId) => {
    setExpenseView('group', groupId);
  };

  const handleOpenModal = () => {
    if (mode === 'group') {
      if (!activeGroupId) {
        showAlert('Please select a group first.');
        return;
      }
      if (!activeGroupMembers || activeGroupMembers.length === 0) {
        showAlert('Please add members to the group before adding an expense.');
        return;
      }
      if (activeGroupMembers.length < 2) {
        showAlert('At least 2 members required to create group expense. Invite more members first.');
        return;
      }
    }
    setState(prev => ({ ...prev, editingTransactionId: null }));
    setShowTransactionModal(true);
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      if (mode === 'personal') {
        await refetchPersonalExpenses();
      } else if (activeGroupId) {
        await refetchGroupDetail();
      }
      await refetchGroups();
      await refetchInvitations();
    } catch (error) {
      showAlert(`Failed to refresh: ${error.message}`);
    } finally {
      setRefreshing(false);
    }
  };

  // Group CRUD - with INSTANT UPDATES
  const handleCreateGroup = async (groupData) => {
    try {
      setMutationLoading(true);
      
      const result = unwrapEnvelope(await expenseApi.createGroup(groupData));
      
      showToast('Group created successfully!', 'success');
      
      // INSTANT UPDATE: Use returned groups directly instead of refetching
      if (result?.groups && Array.isArray(result.groups)) {
        updateGroupsFromResponse(result.groups);
      } else {
        // Fallback: Refetch groups if not returned
        await refetchGroups();
      }
      
      // Switch to the newly created group
      const newGroupId = result?.group?.group_id || result?.group?.id || result?.group_id;
      if (newGroupId) {
        setExpenseView('group', newGroupId);
      }
      
      return result;
    } catch (error) {
      showToast(`Failed to create group: ${error.message}`, 'error');
      throw error;
    } finally {
      setMutationLoading(false);
    }
  };

  const handleDeleteGroup = async (groupId) => {
    try {
      setMutationLoading(true);
      
      const result = await expenseApi.deleteGroup(groupId);
      
      // Check for explicit failure in response
      if (result?.success === false || result?.error) {
        throw new Error(result.error || result.message || 'Cannot delete group');
      }
      
      // Only show success and switch mode if deletion actually succeeded
      showToast('Group deleted successfully!', 'success');
      
      // Clear active group AFTER successful deletion
      if (activeGroupId === groupId) {
        setExpenseView('group');
      }
      
      // Refetch groups
      await refetchGroups();
    } catch (error) {
      // Only show error toast, don't redirect
      showToast(error.message || 'Cannot delete group', 'error');
      // Re-throw so GroupManager knows it failed
      throw error;
    } finally {
      setMutationLoading(false);
    }
  };

  // Transaction CRUD
  // Transaction CRUD - with INSTANT UPDATES
  const handleSaveTransaction = async (transactionData) => {
    try {
      setMutationLoading(true);
      
      if (mode === 'personal') {
        let result;
        if (state.editingTransactionId) {
          result = await expenseApi.updateExpense(state.editingTransactionId, transactionData);
          showToast('Transaction updated!', 'success');
        } else {
          result = await expenseApi.createExpense({
            group_id: null,
            description: transactionData.description,
            amount: transactionData.amount,
            currency: transactionData.currency || 'USD',
            category: transactionData.category,
            expense_date: transactionData.expense_date,
            paid_by: currentUser.uid || currentUser.user_id,
            split_type: 'equal',
            splits: [{ user_id: currentUser.uid || currentUser.user_id, amount: transactionData.amount }]
          });
          showToast('Transaction created!', 'success');
        }
        await refetchPersonalExpenses();
      } else {
        // Group expense
        const editingExpense = state.editingTransactionId
          ? activeGroupExpenses.find(e => (e.id || e.expense_id) === state.editingTransactionId)
          : null;
        if (state.editingTransactionId && !editingExpense) throw new Error('This expense is no longer available. Refresh the group before editing.');
        const expenseData = expensePayload(transactionData, {
          groupId: activeGroupId, editingExpense,
          currency: transactionData.currency || activeGroupData?.currency || 'USD',
        });

        let result;
        if (state.editingTransactionId) {
          result = unwrapEnvelope(await expenseApi.updateExpense(state.editingTransactionId, expenseData));
          showToast('Transaction updated!', 'success');
        } else {
          result = unwrapEnvelope(await expenseApi.createExpense(expenseData));
          showToast('Transaction created!', 'success');
        }
        
        // INSTANT UPDATE: Add new expense to list immediately
        if (result?.expense) {
          const newExpense = result.expense;
          const updatedExpenses = state.editingTransactionId
            ? activeGroupExpenses.map(e => (e.id === state.editingTransactionId || e.expense_id === state.editingTransactionId) ? newExpense : e)
            : [newExpense, ...(activeGroupExpenses || [])];
          
          // Use new balances if returned, otherwise refetch to get accurate balances
          if (result.group_balances && result.group_balances.length > 0) {
            updateExpensesAndBalances(updatedExpenses, result.group_balances);
            await refetchGroupDetail();
          } else {
            // Balances not returned - refetch to ensure accurate calculation
            await refetchGroupDetail();
          }
        } else {
          // Fallback: Refetch group data
          await refetchGroupDetail();
        }
      }
      
      setShowTransactionModal(false);
      setState(prev => ({ ...prev, editingTransactionId: null }));
    } catch (error) {
      showToast(`Failed to save transaction: ${error.message}`, 'error');
      throw error;
    } finally {
      setMutationLoading(false);
    }
  };

  const handleEditTransaction = (transaction) => {
    const expenseId = transaction.id || transaction.expense_id;
    if (expenseId && expenseId.toString().startsWith('temp-')) {
      showToast('Please wait, expense is still being created...', 'info');
      return;
    }
    setState(prev => ({ ...prev, editingTransactionId: expenseId }));
    setShowTransactionModal(true);
  };

  const handleDeleteTransaction = async (id) => {
    try {
      if (id && id.toString().startsWith('temp-')) return;
      
      setMutationLoading(true);
      showToast('Deleting transaction...', 'info');
      
      if (mode === 'personal') {
        markPersonalAsDeleted(id);
      }
      
      const result = unwrapEnvelope(await expenseApi.deleteExpense(id));
      
      // INSTANT UPDATE: Use returned data if available
      if (mode === 'group' && (result?.expenses || result?.group_balances)) {
        updateExpensesAndBalances(activeGroupExpenses.map(item => (item.id || item.expense_id) === id
          ? { ...item, is_deleted: true } : item), result.group_balances);
        await refetchGroupDetail();
      } else if (mode === 'personal') {
        await refetchPersonalExpenses();
      } else {
        await refetchGroupDetail();
      }
      
      showToast('Transaction deleted!', 'success');
    } catch (error) {
      if (mode === 'personal') {
        rollbackPersonalDelete(id);
      }
      showToast(`Failed to delete: ${error.message}`, 'error');
    } finally {
      setMutationLoading(false);
    }
  };

  const handleRestoreTransaction = async id => {
    setMutationLoading(true);
    try {
      await expenseApi.restoreExpense(id);
      if (mode === 'personal') await refetchPersonalExpenses();
      else { await refetchGroupDetail(); await refetchGroups(); }
      showToast('Transaction restored!', 'success');
    } catch (error) {
      showToast(`Failed to restore: ${error.message}`, 'error');
      throw error;
    } finally { setMutationLoading(false); }
  };

  // Settlement handler - with INSTANT UPDATES
  const handleSettlementSuccess = async (settlementData) => {
    try {
      setMutationLoading(true);
      showToast('Creating settlement...', 'info');
      
      await expenseApi.createSettlement(settlementData);
      // Mutation responses may contain only the default first page of history.
      await refetchGroupDetail();
      showToast('Settlement recorded successfully', 'success');
    } catch (error) {
      showToast(error.message || 'Failed to record settlement', 'error');
      throw error;
    } finally {
      setMutationLoading(false);
    }
  };

  const handleSettlementDelete = async (settlementId) => {
    const result = unwrapEnvelope(await expenseApi.deleteSettlement(settlementId));
    updateSettlementsAndBalances(
      activeGroupSettlements.filter(item => (item.id || item.settlement_id) !== settlementId),
      result.balances,
    );
    await refetchGroupDetail();
    showToast('Settlement deleted. Outstanding balances restored.', 'success');
  };

  // Get editing transaction
  const editingTransaction = state.editingTransactionId
    ? (mode === 'personal' ? personalExpenses || [] : getCurrentTransactions()).find(t => t.id === state.editingTransactionId || t.expense_id === state.editingTransactionId)
    : null;

  // PDF Export handler
  const handleExportPDF = () => {
    if (mode === 'personal' && personalConversionPending) {
      showAlert('Wait for currency conversion to finish before exporting. Retry if rates are unavailable.');
      return;
    }
    try {
      showToast('Generating PDF report...', 'info');
      
      generateExpensePDF({
        mode,
        groupName: mode === 'group' ? (activeGroupData?.name || 'Group') : 'Personal',
        expenses: getCurrentTransactions().filter(t => !t.is_deleted),
        settlements: activeGroupSettlements || [],
        members: activeGroupMembers || [],
        balances: getCurrentBalances() || [],
        currency: mode === 'group' ? (activeGroupData?.currency || 'USD') : personalCurrency,
        userName: currentUser?.display_name || currentUser?.email || 'User'
      });
      
      showToast('PDF downloaded successfully!', 'success');
    } catch (error) {
      showToast('Failed to generate PDF', 'error');
    }
  };

  // Loading state
  if (authLoading) {
    return (
      <div className="expense-manager">
        <div style={{ textAlign: 'center', padding: '4rem' }}>
          <RefreshCw className="spinning" size={48} />
          <p>Loading...</p>
        </div>
      </div>
    );
  }

  // Auth required
  if (!isAuthenticated) {
    return (
      <div className="expense-manager">
        <div style={{ textAlign: 'center', padding: '4rem' }}>
          <h2>Welcome Back!</h2>
          <p>Sign in to manage your expenses and keep your budget on track.</p>
        </div>
      </div>
    );
  }

  return (
    <ErrorBoundary 
      onRetry={handleRefresh}
      onGoHome={() => navigate('/')}
    >
    <div className="expense-manager">
      <header className="expense-header">
        <div>
          <h1>{mode === 'group' ? 'Group expenses' : 'Expense Dashboard'}</h1>
          <p>{mode === 'group' ? 'Share the costs. Enjoy the journey.' : 'Manage your personal and group trip expenses.'}</p>
        </div>
        <div className="header-actions">
          <button 
            className="btn-refresh" 
            onClick={handleRefresh}
            disabled={refreshing || mutationLoading}
            title="Refresh data"
          >
            <RefreshCw size={20} className={refreshing ? 'spinning' : ''} />
          </button>
          <ModeToggle mode={mode} onToggle={handleModeToggle} />
          {mode === 'personal' && <button ref={addTransactionRef} className="btn-add-transaction" onClick={handleOpenModal} disabled={mutationLoading}>
            <PlusCircle size={20} />
            <span>Add Transaction</span>
          </button>}
        </div>
      </header>

      {/* Pending Invitations - with INSTANT UPDATES */}
      <PendingInvitations 
        invitationsFromParent={invitations}
        onRefreshInvitations={refetchInvitations}
        onGroupsUpdate={updateGroupsFromResponse}
        onInvitationAccepted={async (response) => {
          const result = unwrapEnvelope(response);
          if (Array.isArray(result?.groups)) updateGroupsFromResponse(result.groups);
          else await refetchGroups();
          const groupId = result?.group?.id || result?.group?.group_id;
          setExpenseView('group', groupId);
          showToast('Welcome to the group!', 'success');
        }}
        currentUser={currentUser}
      />

      {mode === 'group' && !activeGroupId && <GroupDashboard
        groups={(groups || []).filter(group => group && (group.id || group.group_id))}
        currentUserId={currentUser?.uid || currentUser?.user_id || currentUser?.id}
        loading={groupsLoading} error={groupsError}
        onSelect={handleGroupChange} onCreate={() => setShowNewGroup(true)} onRetry={refetchGroups}
      />}
      {mode === 'group' && activeGroupId && groupDetailLoading && !activeGroupData && <p role="status">Loading group…</p>}

      {mode === 'personal' && <section className="expense-dashboard-currency" aria-label="Dashboard currency preference">
        {currencyPreference.loading ? <p role="status">Loading your currency preference...</p> : currencyPreference.loadError ? <div role="alert">Unable to load your currency preference. <button onClick={currencyPreference.retry}>Retry</button></div> : <>
          {!personalCurrency && <h2>Choose your dashboard currency</h2>}
          <label htmlFor="personal-display-currency">Show all transactions in</label>
          <CurrencySelect id="personal-display-currency" value={personalCurrency || ''} placeholder="Choose your currency"
            disabled={currencyPreference.saving || mutationLoading} onChange={event => currencyPreference.choose(event.target.value)} />
          <p>{personalCurrency ? 'All your transactions are converted automatically. Change this anytime.' : 'Choose once and we will remember it. You can change it anytime.'}</p>
          {currencyPreference.saving && <span role="status">Saving currency preference...</span>}
          {currencyPreference.saveError && <p role="alert">{currencyPreference.saveError}</p>}
        </>}
      </section>}
      {mode === 'personal' && personalDashboard.loading && <p role="status">Converting transactions to {personalCurrency}...</p>}
      {mode === 'personal' && personalDashboard.error && <div role="alert">Unable to convert all transactions. Totals and analytics will be available when exchange rates return. Original amounts are shown below. <button onClick={personalDashboard.retry}>Retry conversion</button></div>}
      {mode === 'personal' && personalDashboard.stale && <p role="status">Using the last available exchange rates for this session.</p>}
      {/* Personal Expense Summary */}
      {mode === 'personal' && !personalConversionPending && (
        <ExpenseSummary 
          transactions={getCurrentTransactions()}
          mode={mode}
          currency={personalCurrency}
        />
      )}

      {mode === 'group' && activeGroupId && activeGroupData && (() => {
        const transactions = getCurrentTransactions();
        const balances = getCurrentBalances() || [];
        const overview = groupOverview(activeGroupData, currentUser?.uid || currentUser?.user_id || currentUser?.id, transactions, balances);
        const remainingBalance = balances.reduce((sum, balance) => sum + Math.max(0, Number(balance.net_balance ?? balance.balance) || 0), 0);
        return <>
          <GroupDetailHeader group={activeGroupData} members={activeGroupMembers || []} overview={overview}
            busy={mutationLoading || groupDetailLoading} onBack={() => { setExpenseView('group'); refetchGroups(); }}
            onCreate={() => setShowNewGroup(true)} onAdd={handleOpenModal} onSettle={() => openGroupTab('settleup')} />
          <CurrencyConversion key={activeGroupId} base={activeGroupData.currency || 'USD'} preferredCurrency={activeGroupData.display_currency || activeGroupData.currency || 'USD'} amounts={[
            {label: 'Total group spend', amount: transactions.filter(t => !t.is_deleted).reduce((sum, t) => sum + Number(t.amount || 0), 0)},
            {label: 'Outstanding balances', amount: remainingBalance},
            {label: 'Settled', amount: (activeGroupSettlements || []).reduce((sum, t) => sum + Number(t.amount || 0), 0)},
          ]} />
          <GroupSummaryCards remainingBalance={remainingBalance}
            totalSettlements={(activeGroupSettlements || []).reduce((sum, settlement) => sum + (Number(settlement.amount) || 0), 0)}
            settlementCount={(activeGroupSettlements || []).length}
            changeCount={transactions.filter(transaction => transaction.is_edited).length}
            currency={activeGroupData.currency || 'USD'} displayCurrency={activeGroupData.display_currency || activeGroupData.currency || 'USD'} onSettlementCardClick={() => setIsHistoryModalOpen(true)}
            onSettleClick={() => openGroupTab('settleup')} onHistoryClick={() => openGroupTab('transactions')} />
          <SettlementHistoryModal isOpen={isHistoryModalOpen} onClose={() => setIsHistoryModalOpen(false)}
            settlements={activeGroupSettlements || []} group={activeGroupData}
            currentUserId={currentUser?.uid || currentUser?.user_id || currentUser?.id}
            onDelete={handleSettlementDelete} currency={activeGroupData.currency || 'USD'} />
        </>;
      })()}

      {mode === 'group' && groupDetailError && <div className="expense-groups-empty" role="alert"><p>Unable to open this group: {groupDetailError}</p><button className="expense-secondary-button" onClick={() => setExpenseView('group')}>Back to all groups</button></div>}

      {/* Group View with Tabs (Balances, Settle Up, Spending, Transactions, Analytics) */}
      {mode === 'group' && activeGroupId && activeGroupData && (
        <div ref={groupTabsRef} className="expense-group-tab-target"><TabbedGroupView
          key={activeGroupId}
          activeTab={groupTab}
          onTabChange={setGroupTab}
          membersContent={<GroupManager
            groups={(groups || []).filter(g => g && (g.id || g.group_id))}
            activeGroupId={activeGroupId}
            activeGroup={activeGroupData}
            members={activeGroupMembers || []}
            loading={groupsLoading || groupDetailLoading}
            onGroupChange={handleGroupChange}
            onGroupCreate={handleCreateGroup}
            onGroupDelete={handleDeleteGroup}
            onGroupUpdated={async () => { await refetchGroupDetail(); await refetchGroups(); }}
            onGroupLeave={async () => { setExpenseView('group'); await refetchGroups(); }}
            onMemberAdd={async () => await refetchGroupDetail()}
            onMemberRemove={async () => await refetchGroupDetail()}
            showAlert={showAlert}
            currentUser={currentUser}
            pendingInvitationsFromParent={groupInvitations}
            onRefreshInvitations={refetchGroupDetail}
            usingMegaBootstrap={false}
            compact
            expenses={getCurrentTransactions()}
          />}
          group={activeGroupData}
          balances={getCurrentBalances() || []}
          members={activeGroupMembers || []}
          allMembersMap={getAllMembersMap()}
          onBalanceUpdate={refetchGroupDetail}
          settlementHistory={activeGroupSettlements || []}
          onSettlementSuccess={handleSettlementSuccess}
          onSettlementDelete={handleSettlementDelete}
          transactions={getCurrentTransactions()}
          filter={state.filter}
          onFilterChange={(filterType, value) => setState(prev => ({
            ...prev,
            filter: { ...prev.filter, [filterType]: value }
          }))}
          activeGroupMembers={activeGroupMembers || []}
          currentUserId={currentUser?.uid || currentUser?.user_id}
          onEdit={handleEditTransaction}
          onDelete={(id) => showConfirm('Are you sure you want to delete this transaction?', () => handleDeleteTransaction(id))}
          onRestore={handleRestoreTransaction}
          onExportPDF={handleExportPDF}
        /></div>
      )}

      {/* Personal Mode - Tabbed View (Transaction History + Analytics) */}
      {mode === 'personal' && (
        <PersonalTabbedView
          transactions={getCurrentTransactions()}
          conversionPending={personalConversionPending}
          filter={state.filter}
          onFilterChange={(filterType, value) => setState(prev => ({
            ...prev,
            filter: { ...prev.filter, [filterType]: value }
          }))}
          onEdit={handleEditTransaction}
          onDelete={(id) => showConfirm('Are you sure you want to delete this transaction?', () => handleDeleteTransaction(id))}
          onRestore={handleRestoreTransaction}
          currentUserId={currentUser?.uid || currentUser?.user_id}
          currency={personalCurrency || 'USD'}
          onExportPDF={handleExportPDF}
        />
      )}

      {showNewGroup && <NewExpenseGroupModal onClose={() => setShowNewGroup(false)} onCreate={handleCreateGroup} />}

      {mode === 'personal' && showFloatingAdd && !showTransactionModal && <button
        className="btn-add-transaction expense-floating-add" onClick={handleOpenModal} disabled={mutationLoading}>
        <PlusCircle size={20} aria-hidden="true" /><span>Add Transaction</span>
      </button>}

      {/* Transaction Modal */}
      {showTransactionModal && (
        <TransactionModal
          mode={mode}
          activeGroup={activeGroupData}
          members={activeGroupMembers || []}
          editingTransaction={editingTransaction}
          currency={mode === 'group' ? activeGroupData?.currency : personalCurrency}
          currentUser={currentUser}
          onSave={handleSaveTransaction}
          onClose={() => setShowTransactionModal(false)}
          onAlert={showAlert}
        />
      )}

      {/* Alert Modal */}
      {showAlertModal && (
        <ExpenseDialog label="Heads up" onClose={() => setShowAlertModal(false)} className="modal modal-small">
            <h2>Heads up!</h2>
            <p>{alertMessage}</p>
            <div className="modal-actions">
              <button className="btn-save" onClick={() => setShowAlertModal(false)}>OK</button>
            </div>
        </ExpenseDialog>
      )}

      {/* Confirm Modal */}
      {showConfirmModal && (
        <ExpenseDialog label="Confirm expense deletion" onClose={() => setShowConfirmModal(false)} className="modal modal-small">
            <h2>Are you sure?</h2>
            <p>{confirmMessage}</p>
            <div className="modal-actions">
              <button className="btn-cancel" onClick={() => setShowConfirmModal(false)}>Cancel</button>
              <button 
                className="btn-delete"
                onClick={() => {
                  if (confirmCallback) confirmCallback();
                  setShowConfirmModal(false);
                }}
              >
                Delete
              </button>
            </div>
        </ExpenseDialog>
      )}
      
      {/* Toast notifications */}
      {toasts.map(toast => (
        <Toast
          key={toast.id}
          message={toast.message}
          type={toast.type}
          onClose={() => hideToast(toast.id)}
        />
      ))}
    </div>
    </ErrorBoundary>
  );
};

export default ExpenseManager;
