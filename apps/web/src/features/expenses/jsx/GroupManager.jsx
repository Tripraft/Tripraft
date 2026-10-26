// Purpose: Manages expense-group metadata, membership and invitations with role-aware actions, confirmation and retryable API errors.
import React, { useState, useEffect, useRef } from 'react';
import { Users, Plus, Mail, Trash2, Clock, Settings, Link, Send, LoaderCircle } from 'lucide-react';
import { formatDateLocal } from '../../../utils/timezoneUtils';
import expenseApi from '../../../services/expenseApi';
import { groupPermissions } from '../utils/groupPermissions';
import CurrencySelect from '../../../components/common/jsx/CurrencySelect';
import ExpenseDialog from './ExpenseDialog';
import ExpenseFriendPicker from './ExpenseFriendPicker';
import { formatMoney } from '../../../utils/money';

const unwrapEnvelope = response => response?.data ?? response;
const invitationLink = invitation => invitation.invitation_link ||
  `${window.location.origin}/invitation/${encodeURIComponent(invitation.invitation_id || invitation.id)}`;
const invitationExpired = invitation => {
  if (invitation.is_expired != null) return invitation.is_expired;
  const expiry = invitation.expires_at;
  return Boolean(expiry && new Date(/(?:Z|[+-]\d{2}:?\d{2})$/.test(expiry) ? expiry : `${expiry}Z`) <= new Date());
};
const deliveryMessage = status => ({
  sent: 'Invitation email sent.',
  queued: 'Invitation email queued.',
  disabled: 'Email delivery is unavailable. You can copy the invite link.',
  failed: 'Email could not be sent. Try again shortly or copy the invite link.',
}[status] || 'Invitation saved. You can copy the invite link.');



const GroupManager = ({ 
  groups, 
  activeGroupId, 
  activeGroup,
  members,
  loading,
  onGroupChange, 
  onGroupCreate,
  onGroupDelete,
  onGroupUpdated,
  onGroupLeave,
  onMemberAdd,
  onMemberRemove,
  showAlert,
  currentUser,
  pendingInvitationsFromParent,
  onRefreshInvitations,
  usingMegaBootstrap = false,
  compact = false,
  expenses = []
}) => {
  // Simplified: No complex prefetch or mutation hooks
  
  const userId = currentUser?.uid || currentUser?.user_id || currentUser?.id;
  const canViewGroup = Boolean(activeGroup);
  const permissions = groupPermissions(activeGroup, userId);
  const [confirmation, setConfirmation] = useState(null);
  const [actionBusy, setActionBusy] = useState(false);
  const [actionError, setActionError] = useState('');
  const [editingGroup, setEditingGroup] = useState(false);
  const [groupName, setGroupName] = useState('');
  const [groupDescription, setGroupDescription] = useState('');
  const [groupCurrency, setGroupCurrency] = useState('USD');
  const [groupBudget, setGroupBudget] = useState('');
  const [groupStart, setGroupStart] = useState('');
  const [groupEnd, setGroupEnd] = useState('');
  const [groupCategory, setGroupCategory] = useState('');
  const isOwner = String(activeGroup?.created_by) === String(userId);
  useEffect(() => { setConfirmation(null); setActionError(''); setEditingGroup(false); }, [activeGroupId, canViewGroup]);
  const runAction = async (action) => {
    if (actionBusy) return;
    setActionBusy(true);
    setActionError('');
    try {
      await action();
      setConfirmation(null);
    } catch (error) { setActionError(error.message || 'Could not complete this action.'); }
    finally { setActionBusy(false); }
  };
  const confirm = (message, action) => { setActionError(''); setConfirmation({ message, action }); };
  const refreshGroup = async () => { if (onGroupUpdated) await onGroupUpdated(); else if (onMemberAdd) await onMemberAdd(); };
  const [newGroupName, setNewGroupName] = useState('');
  const [newGroupCurrency, setNewGroupCurrency] = useState('USD');
  const [newMemberEmail, setNewMemberEmail] = useState('');
  const [friendNickname, setFriendNickname] = useState('');
  const [selectedFriend, setSelectedFriend] = useState(null);
  const [friendRevision, setFriendRevision] = useState(0);
  const [savingFriend, setSavingFriend] = useState(false);
  const [friendFeedback, setFriendFeedback] = useState('');
  const [friendError, setFriendError] = useState('');
  const [inviting, setInviting] = useState(false);
  const invitingRef = useRef(false);
  const savingFriendRef = useRef(false);
  const [resendingInvitationId, setResendingInvitationId] = useState(null);
  const [creating, setCreating] = useState(false);
  const [pendingInvitations, setPendingInvitations] = useState([]);
  const [loadingInvitations, setLoadingInvitations] = useState(false);
  const [activeTab, setActiveTab] = useState('members'); // 'members' or 'pending'

  //  PHASE 16: Use invitations from parent (mega-bootstrap) if available
  useEffect(() => {
    if (pendingInvitationsFromParent !== undefined) {
      // PHASE 17 FIX: Show pending AND declined invitations to owner
      // Owner can see declined invitations and resend them
      const relevantInvitations = (pendingInvitationsFromParent || []).filter(
        inv => inv.status === 'pending' || inv.status === 'PENDING' || 
               inv.status === 'declined' || inv.status === 'DECLINED'
      );
      // PHASE 19 FIX: Deduplicate by invitation_id to prevent React key warnings
      const uniqueInvitations = relevantInvitations.filter((inv, index, self) => 
        index === self.findIndex(i => i.invitation_id === inv.invitation_id)
      );
      setPendingInvitations(uniqueInvitations);
    }
  }, [pendingInvitationsFromParent]);

  // Load pending invitations when active group changes (fallback ONLY if not using mega-bootstrap)
  useEffect(() => {
    // 🚀 PHASE 16: Skip fallback API call if mega-bootstrap is active/loading
    if (usingMegaBootstrap) {
      return;
    }
    
    // 🚀 ULTRA FIX: Skip fallback if parent already provided invitations
    // This prevents double-fetch when mega-bootstrap cache is pre-populated
    if (pendingInvitationsFromParent !== undefined) {
      return;
    }
    
    if (activeGroupId) {
      loadPendingInvitations();
    } else {
      setPendingInvitations([]);
    }
  }, [activeGroupId, usingMegaBootstrap, pendingInvitationsFromParent]);

  // 🔄 Auto-refresh pending invitations every 10 seconds when viewing "Pending" tab
  // 🔥 PHASE 16: Uses mega-bootstrap refresh, no direct API calls
  useEffect(() => {
    let intervalId = null;
    
    if (activeGroupId && activeTab === 'pending') {
      // 🚀 ULTRA FIX: Only enable polling when NOT using mega-bootstrap
      // Mega-bootstrap handles data updates
      if (!usingMegaBootstrap && pendingInvitationsFromParent === undefined) {
        // Set up polling every 10 seconds - only when truly in fallback mode
        intervalId = setInterval(() => {
          loadPendingInvitations();
        }, 10000); // 10 seconds
      }
    }
    
    return () => {
      if (intervalId) {
        clearInterval(intervalId);
      }
    };
  }, [activeGroupId, activeTab, usingMegaBootstrap, pendingInvitationsFromParent]);

  // 🔥 Listen for global invitation acceptance events
  useEffect(() => {
    const handleInvitationAccepted = () => {
      if (activeGroupId) {
        // 🚀 ULTRA FIX: Only fetch if in true fallback mode
        if (!usingMegaBootstrap && pendingInvitationsFromParent === undefined) {
          loadPendingInvitations();
        } else if (onRefreshInvitations) {
          onRefreshInvitations();
        }
        // Otherwise: REST API polling will update automatically (SQL backend)
      }
    };
    
    window.addEventListener('invitationAccepted', handleInvitationAccepted);
    
    return () => {
      window.removeEventListener('invitationAccepted', handleInvitationAccepted);
    };
  }, [activeGroupId, onRefreshInvitations, usingMegaBootstrap, pendingInvitationsFromParent]);

  const loadPendingInvitations = async () => {
    if (!activeGroupId) return;
    
    setLoadingInvitations(true);
    try {
      // CRITICAL FIX: Add cache-busting timestamp to force fresh API call
      // includeAll=true to show declined invitations to owner
      const timestamp = Date.now();
      const response = unwrapEnvelope(await expenseApi.getGroupInvitations(activeGroupId, timestamp));
      // PHASE 17 FIX: Filter for pending AND declined invitations (to show owner who declined)
      const relevantStatuses = ['pending', 'PENDING', 'declined', 'DECLINED'];
      const relevantInvitations = (response.invitations || []).filter(
        inv => relevantStatuses.includes(inv.status)
      );
      // PHASE 19 FIX: Deduplicate by invitation_id
      const uniqueInvitations = relevantInvitations.filter((inv, index, self) => 
        index === self.findIndex(i => i.invitation_id === inv.invitation_id)
      );
      setPendingInvitations(uniqueInvitations);
    } catch (error) {
      setPendingInvitations([]);
    } finally {
      setLoadingInvitations(false);
    }
  };

  const handleCreateGroup = async (e) => {
    e.preventDefault();
    if (creating) return;
    if (!newGroupName.trim()) {
      showAlert('Please enter a group name');
      return;
    }

    setCreating(true);
    try {
      await onGroupCreate({
        name: newGroupName.trim(),
        description: `Created by ${currentUser.displayName || currentUser.email}`,
        currency: newGroupCurrency
      });
      setNewGroupName('');
      setNewGroupCurrency('USD');
      showAlert('Group created successfully!');
    } catch (error) {
      showAlert(`Failed to create group: ${error.message}`);
    } finally {
      setCreating(false);
    }
  };

  const handleInviteMember = async (e, isResend = false, emailToResend = null) => {
    e.preventDefault();
    
    // Prevent double submission
    if (invitingRef.current || savingFriendRef.current) {
      return;
    }
    
    // Get email - either from resend parameter or from input field
    const invitedEmail = (emailToResend || newMemberEmail).trim().toLowerCase();
    
    if (!invitedEmail) {
      showAlert('Please enter an email address');
      return;
    }
    
    if (!activeGroupId) {
      showAlert('Please select a group first');
      return;
    }

    // Preserve the draft on both success and failure. A synchronous guard
    // prevents duplicate submissions without erasing what the user entered.
    invitingRef.current = true;
    setInviting(true);
    try {
      const existing = pendingInvitations.find(inv =>
        (inv.invitee_email || inv.invited_email || '').toLowerCase() === invitedEmail &&
        inv.status?.toLowerCase() === 'pending' && !invitationExpired(inv));
      const response = unwrapEnvelope(await (existing
        ? expenseApi.resendInvitation(existing.invitation_id || existing.id)
        : expenseApi.sendInvitation({
        group_id: activeGroupId,
        invitee_email: invitedEmail,
        ...(!isResend && (friendNickname.trim() || selectedFriend) && {nickname: friendNickname.trim() || null}),
      })));
      
      if (response.invitations) setPendingInvitations(response.invitations);
      else if (response.invitation) setPendingInvitations(previous => [
        ...previous.filter(inv => (inv.id || inv.invitation_id) !== (response.invitation.id || response.invitation.invitation_id)),
        response.invitation,
      ]);
      setFriendRevision(value => value + 1);
      setActiveTab('pending');
      showAlert(deliveryMessage(response.email_status));
      // No membership changed. Refresh once in the background after showing the result.
      if (onRefreshInvitations) Promise.resolve().then(onRefreshInvitations).catch(() => {});
    } catch (error) {
      if (error.status === 409) {
        await loadPendingInvitations();
        setActiveTab('pending');
      }
      showAlert(`Failed to send invitation: ${error.message}`);
    } finally {
      invitingRef.current = false;
      setInviting(false);
    }
  };

  const handleSaveFriend = async () => {
    if (savingFriendRef.current || invitingRef.current) return;
    const email = newMemberEmail.trim().toLowerCase();
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setFriendError('Enter a valid email address or choose a saved friend.');
      return;
    }
    savingFriendRef.current = true;
    setSavingFriend(true); setFriendError(''); setFriendFeedback('');
    try {
      const response = unwrapEnvelope(await expenseApi.saveFriend({email, nickname: friendNickname.trim() || null}));
      if (!response?.friend) throw new Error('Unable to save this friend.');
      setSelectedFriend(response.friend);
      setFriendRevision(value => value + 1);
      setFriendFeedback('Friend saved. You can invite them to any expense group later.');
    } catch (error) { setFriendError(error.message || 'Unable to save this friend.'); }
    finally { savingFriendRef.current = false; setSavingFriend(false); }
  };

  const handleResendInvitation = async invitation => {
    if (resendingInvitationId) return;
    const id = invitation.invitation_id || invitation.id;
    setResendingInvitationId(id);
    try {
      const result = unwrapEnvelope(await expenseApi.resendInvitation(id));
      const messages = {
        sent: 'Invitation email sent.',
        queued: 'Invitation email queued.',
        disabled: 'Email delivery is unavailable. You can copy the invite link.',
        failed: 'Email could not be sent. Try again shortly or copy the invite link.',
      };
      showAlert(messages[result.email_status] || 'Email delivery could not be confirmed.');
    } catch (error) {
      showAlert(`Failed to resend invitation: ${error.message}`);
    } finally {
      setResendingInvitationId(null);
    }
  };

  const handleCopyInvitation = async invitation => {
    const link = invitationLink(invitation);
    try {
      await navigator.clipboard.writeText(link);
      showAlert('Invitation link copied. Share it with the invited person.');
    } catch {
      showAlert(`Please copy this invitation link: ${link}`);
    }
  };

  const handleRemoveMember = async (memberId) => {
    if (!activeGroupId) return;
    await expenseApi.removeGroupMember(activeGroupId, memberId);
    showAlert('Member removed successfully!');
    if (onMemberRemove) await onMemberRemove(memberId);
  };

  const handleDeleteGroup = async () => {
    if (activeGroupId) await onGroupDelete(activeGroupId);
  };

  const handleGroupSelect = (e) => {
    const groupId = e.target.value || null;
    onGroupChange(groupId);
  };

  if (loading) {
    return (
      <div className="group-section">
        <div className="group-cards">
          <div className="card">
            <p style={{ textAlign: 'center', color: '#666' }}>Loading groups...</p>
          </div>
        </div>
      </div>
    );
  }

  const inviteForm = permissions.can_invite && <form className="expense-member-invite" onSubmit={handleInviteMember} aria-busy={inviting}>
    <h3><Mail size={17} />Invite your crew</h3><p>Share the journey and keep every expense together.</p>
    <ExpenseFriendPicker userId={userId} revision={friendRevision} disabled={inviting || savingFriend} onSelect={friend => {
      setSelectedFriend(friend); setNewMemberEmail(friend.email); setFriendNickname(friend.nickname || ''); setFriendFeedback(''); setFriendError('');
    }} />
    {selectedFriend ? <div className="expense-selected-friend"><strong>Inviting {selectedFriend.label}</strong><button type="button" disabled={inviting || savingFriend}
      onClick={() => { setSelectedFriend(null); setNewMemberEmail(''); setFriendNickname(''); setFriendFeedback(''); }}>Choose someone else</button></div> : <>
      <label htmlFor="expense-member-email">Email address</label><input id="expense-member-email" type="email" placeholder="Email address to invite..." value={newMemberEmail}
        onChange={event => { setNewMemberEmail(event.target.value); setFriendFeedback(''); setFriendError(''); }} required disabled={inviting || savingFriend} />
    </>}
    <label htmlFor="expense-friend-nickname">Nickname (optional)</label><input id="expense-friend-nickname" value={friendNickname} maxLength={100}
      onChange={event => setFriendNickname(event.target.value)} disabled={inviting || savingFriend} placeholder="A name you will remember" />
    <button className="expense-primary-button" disabled={inviting || savingFriend}>
      {inviting ? <LoaderCircle className="spinning" size={16} aria-hidden="true" /> : <Plus size={16} aria-hidden="true" />}{inviting ? 'Inviting...' : 'Invite Member'}</button>
    <button className="expense-secondary-button" type="button" onClick={handleSaveFriend} disabled={inviting || savingFriend}>
      {savingFriend && <LoaderCircle className="spinning" size={16} aria-hidden="true" />}{savingFriend ? 'Saving friend...' : 'Save friend without inviting'}</button>
    <p className="expense-invite-help">If the invitation is not received, ask your friend to check their spam or junk folder.</p>
    {friendFeedback && <p role="status">{friendFeedback}</p>}{friendError && <p role="alert">{friendError}</p>}
  </form>;
  const invitationsList = <section className="expense-member-invitations" aria-label="Group invitations"><h3><Clock size={16} />Pending invitations ({pendingInvitations.length})</h3>
    {loadingInvitations ? <p>Loading invitations...</p> : !pendingInvitations.length ? <p className="expense-member-empty">No pending invitations.</p> : <ul>{pendingInvitations.map(invitation => {
      const id = invitation.invitation_id || invitation.id;
      const declined = invitation.status?.toLowerCase() === 'declined';
      const expired = invitationExpired(invitation);
      const canRetry = permissions.can_invite && (String(invitation.invited_by) === String(userId) || permissions.can_update_group);
      return <li key={id}><div className="expense-member-invitation-heading"><strong>{invitation.invited_email || invitation.invitee_email || invitation.invited_username || 'Invited member'}</strong><span>{declined ? 'Declined' : expired ? 'Expired' : 'Pending'}</span></div>
        <small>Invited {formatDateLocal(invitation.created_at, { year: 'numeric', month: 'short', day: 'numeric' })}</small>
        <div className="expense-member-invitation-actions">{!declined && !expired && <button onClick={() => handleCopyInvitation(invitation)}><Link size={13} />Copy invite link</button>}
          {!declined && !expired && canRetry && <button disabled={Boolean(resendingInvitationId)} onClick={() => handleResendInvitation(invitation)}><Send size={13} />{resendingInvitationId === id ? 'Sending...' : 'Resend email'}</button>}
          {(declined || expired) && permissions.can_invite && <button disabled={inviting} onClick={event => handleInviteMember(event, true, invitation.invited_email || invitation.invitee_email)}>Resend</button>}
          {!declined && canRetry && <button disabled={actionBusy} onClick={() => confirm('Cancel this invitation? Its link will no longer allow joining.', async () => {
            await expenseApi.cancelInvitation(id); setPendingInvitations(previous => previous.filter(row => (row.invitation_id || row.id) !== id)); await refreshGroup();
          })}>Cancel invitation</button>}
        </div></li>;
    })}</ul>}
  </section>;
  const memberList = <ul className="expense-member-list">{members.map((member, index) => {
    const id = member.user_id || member.id;
    const name = member.user?.display_name || member.user?.username || member.display_name || member.username || member.user?.email || member.email || 'Unknown User';
    const isOwner = String(id) === String(activeGroup?.created_by);
    const isYou = String(id) === String(userId);
    const paid = expenses.filter(expense => !expense.is_deleted && String(expense.paid_by) === String(id)).reduce((sum, expense) => sum + (Number(expense.amount) || 0), 0);
    return <li key={id}><span className={`expense-member-avatar avatar-${index % 4}`} aria-hidden="true">{name.split(/\s+/).map(part => part[0]).slice(0, 2).join('').toUpperCase()}</span>
      <div className="expense-member-identity"><strong>{name}{isYou && <small>(You)</small>}</strong><span>Paid {formatMoney(paid, activeGroup?.currency || 'USD')}</span></div>
      <span className={`expense-member-role ${isOwner ? 'is-owner' : ''}`}>{isOwner ? 'Owner' : member.role === 'admin' ? 'Admin' : 'Member'}</span>
      <div className="expense-member-actions">{permissions.can_manage_roles && !isOwner && <button disabled={actionBusy} onClick={() => confirm(`${member.role === 'admin' ? 'Remove admin access from' : 'Make admin:'} ${name}?`, async () => {
        await expenseApi.updateGroupMemberRole(activeGroupId, id, member.role === 'admin' ? 'member' : 'admin'); await refreshGroup();
      })}>{member.role === 'admin' ? 'Make member' : 'Make admin'}</button>}
      {permissions.can_remove_members && !isOwner && !isYou && <button className="expense-member-remove" title="Remove member (Owner Only)" aria-label={`Remove ${name}`} disabled={actionBusy} onClick={() => confirm(`Remove ${name}? Their balance must be zero. Their existing history will be retained.`, () => handleRemoveMember(id))}><Trash2 size={15} /></button>}</div>
    </li>;
  })}</ul>;

  return <div className="group-section expense-members-view">
    {!compact && <section className="expense-members-selector"><h2><Users size={20} />Manage Groups</h2><select className="group-select" value={activeGroupId || ''} onChange={handleGroupSelect} aria-label="Select a group"><option value="">Select a group</option>{groups.map(group => <option key={group.id || group.group_id} value={group.id || group.group_id}>{group.name} ({group.currency || 'USD'})</option>)}</select></section>}
    {activeGroupId && activeGroup && <>
      <div className="expense-members-grid"><section className="expense-members-panel"><div className="expense-section-toolbar"><h2>Group Members &amp; Invitations</h2><span className="expense-member-count">{members.length} members</span></div>
        {!compact && <div className="expense-members-switch"><button aria-pressed={activeTab === 'members'} onClick={() => setActiveTab('members')}>Members ({members.length})</button><button aria-pressed={activeTab === 'pending'} onClick={() => setActiveTab('pending')}>Pending ({pendingInvitations.length})</button></div>}
        {compact || activeTab === 'members' ? <>{members.length ? memberList : <p className="expense-member-empty">No members yet. Invite someone to get started!</p>}{!compact && inviteForm}</> : <>{!compact && inviteForm}{invitationsList}</>}
      </section>{compact && <aside className="expense-members-aside">{inviteForm}{invitationsList}</aside>}</div>
      <details className="expense-member-settings" open={!compact || editingGroup || undefined}><summary><Settings size={16} />Group settings</summary><div className="expense-member-settings-content">
        <div className="expense-member-settings-info"><strong>{activeGroup.name}</strong><span>{activeGroup.display_currency || activeGroup.currency || 'USD'} display · {activeGroup.currency || 'USD'} ledger · {members.length} members</span>
          <p>{activeGroup.description || 'No description yet'}</p><p>Budget: {activeGroup.budget != null ? formatMoney(activeGroup.budget, activeGroup.currency || 'USD') : 'Not set'}</p>
          <p>{activeGroup.start_date || 'No start date'} – {activeGroup.end_date || 'No end date'}{activeGroup.category ? ` · ${activeGroup.category}` : ''}</p></div>
        <div className="expense-member-settings-actions">{permissions.can_update_group && !editingGroup && <button className="expense-secondary-button" onClick={() => { setGroupName(activeGroup.name); setGroupDescription(activeGroup.description || ''); setGroupCurrency(activeGroup.display_currency || activeGroup.currency || 'USD'); setGroupBudget(activeGroup.budget ?? ''); setGroupStart(activeGroup.start_date || ''); setGroupEnd(activeGroup.end_date || ''); setGroupCategory(activeGroup.category || ''); setEditingGroup(true); }}>Edit group</button>}
        {permissions.can_leave_group && <button className="expense-secondary-button" disabled={actionBusy} onClick={() => confirm('Leave this group? Your balance must be zero. Your existing expense and payment history will be retained.', async () => { await expenseApi.leaveGroup(activeGroupId); if (onGroupLeave) await onGroupLeave(); })}>Leave group</button>}
        {permissions.can_delete_group && <button className="expense-secondary-button expense-member-remove" title="Delete Group (Owner Only)" onClick={() => confirm('Delete this group? All balances must be settled. The group will be archived and pending invitations cancelled.', handleDeleteGroup)}><Trash2 size={15} />Delete group</button>}</div>
        {editingGroup && permissions.can_update_group && <form className="expense-member-edit" onSubmit={event => {
          event.preventDefault(); runAction(async () => { await expenseApi.updateGroup(activeGroupId, { name: groupName.trim(), description: groupDescription.trim() || null,
            ...(groupCategory.trim() !== (activeGroup.category || '') && {category: groupCategory.trim() || null}),
            ...(isOwner && {display_currency: groupCurrency, budget: groupBudget === '' ? null : groupBudget, start_date: groupStart || null, end_date: groupEnd || null}) }); await refreshGroup(); setEditingGroup(false); });
        }}><fieldset disabled={actionBusy} style={{border: 0, padding: 0}}><label>Group name<input value={groupName} maxLength={100} required onChange={event => setGroupName(event.target.value)} /></label><label>Description<textarea value={groupDescription} maxLength={1000} onChange={event => setGroupDescription(event.target.value)} /></label>
          <label>Category<input value={groupCategory} maxLength={50} onChange={event => setGroupCategory(event.target.value)} /></label>
          {isOwner && <><label>Default display currency<CurrencySelect aria-label="Default display currency" value={groupCurrency} onChange={event => setGroupCurrency(event.target.value)} /></label>
            <p>New expenses start in {groupCurrency}. Any member can enter another currency. Saved amounts stay in the {activeGroup.currency} group ledger.</p>
            <label>Group budget ({activeGroup.currency})<input type="number" min="0" step="0.01" value={groupBudget} onChange={event => setGroupBudget(event.target.value)} /></label>
            <label>Start date<input type="date" value={groupStart} onChange={event => setGroupStart(event.target.value)} /></label><label>End date<input type="date" min={groupStart || undefined} value={groupEnd} onChange={event => setGroupEnd(event.target.value)} /></label></>}
          <div><button className="expense-primary-button" disabled={!groupName.trim()}>Save group</button><button className="expense-secondary-button" type="button" onClick={() => setEditingGroup(false)}>Cancel edit</button></div></fieldset></form>}
      </div></details>
    </>}
    {actionError && !confirmation && <p role="alert">{actionError}</p>}
    {activeGroup && confirmation && <ExpenseDialog label="Confirm group action" onClose={() => !actionBusy && setConfirmation(null)} busy={actionBusy} className="expense-group-confirm"><div role="alertdialog" aria-label="Confirm group action"><h2>Confirm group action</h2><p>{confirmation.message}</p>{actionError && <p role="alert">{actionError}</p>}<div><button className="expense-primary-button" disabled={actionBusy} onClick={() => runAction(confirmation.action)}>{actionBusy ? 'Saving...' : 'Confirm'}</button><button className="expense-secondary-button" disabled={actionBusy} onClick={() => { setConfirmation(null); setActionError(''); }}>Cancel</button></div></div></ExpenseDialog>}
    {!compact && <form className="create-group-form expense-legacy-create" onSubmit={handleCreateGroup}><input type="text" placeholder="New group name..." value={newGroupName} maxLength={100} onChange={event => setNewGroupName(event.target.value)} required disabled={creating} /><CurrencySelect aria-label="New group currency" value={newGroupCurrency} onChange={event => setNewGroupCurrency(event.target.value)} disabled={creating} /><button className="expense-primary-button" disabled={creating}><Plus size={16} />{creating ? 'Creating...' : 'Create Group'}</button></form>}
  </div>;
};

export default GroupManager;
