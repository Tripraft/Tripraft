// Purpose: Manages trip members, access roles, independent crew responsibilities, group settings, invitations and Scout consent controls.
import CurrencySelect from '../../../../components/common/jsx/CurrencySelect';
import React, { useState, useEffect, useRef } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Users,
  UserPlus,
  Shield,
  Eye,
  Check,
  X,
  Lock,
  Settings,
  Copy,
  Trash2,
  Sparkles,
  LogOut,
  Wallet,
  Compass,
  MapPin,
} from 'lucide-react';
import { useAuth } from '../../../../context/AuthContext';
import { useGroupMembers, gpKeys } from '../../../../hooks/useGroupPlannerQuery';
import {
  useAiConsent,
  useSubmitAiConsent,
  useRevokeAiConsent,
} from '../../../../hooks/useAiConsentQuery';
import groupPlannerApi from '../../../../services/groupPlannerApi';
import { toArray } from '../../utils/groupPlannerUtils';
import { getInitials, formatDate } from '../../utils/formatters';
import { AI_BOTS } from '../../../scout/aiBots';
import { isPlannerDemo } from '../../demo/demoMode';
import { CREW_ROLES } from '../../constants/crewRoles';
const roles = {
  creator: { label: 'Owner', description: 'Owns the trip and its membership.', Icon: Shield },
  admin: {
    label: 'Admin',
    description: 'Keeps plans, settings, and roles organized.',
    Icon: Settings,
  },
  member: {
    label: 'Member',
    description: 'Adds ideas and helps shape the adventure.',
    Icon: Users,
  },
  viewer: { label: 'Viewer', description: 'Follows the plan with read-only access.', Icon: Eye },
};
const capabilities = [
  ['View itinerary, bookings, and updates', [1, 1, 1, 1]],
  ['Add stops, vote, upload, and edit checklists', [1, 1, 1, 0]],
  ['Invite friends and send group messages', [1, 1, 1, 0]],
  ['Edit trip settings and budget', [1, 1, 0, 0]],
  ['Change member roles (except owner)', [1, 1, 0, 0]],
  ['Remove other members (except owner)', [1, 1, 0, 0]],
  ['Delete the group', [1, 0, 0, 0]],
];
export default function CircleTab({ groupId, group, showToast, onInvite, onLeave }) {
  const client = useQueryClient(),
    { currentUser } = useAuth(),
    { data: raw, isLoading, error } = useGroupMembers(groupId),
    members = toArray(raw, 'members').filter((m) => m.is_active !== false && m.type !== 'ai');
  const me = members.find((m) => String(m.user_id || m.id) === String(currentUser?.uid)),
    manage = ['creator', 'admin'].includes(me?.role),
    owner = me?.role === 'creator',
    contribute = ['creator', 'admin', 'member'].includes(me?.role);
  const { data: invitationsRaw, error: invitationError } = useQuery({
    queryKey: [...gpKeys.all, 'invitations', groupId],
    queryFn: () => groupPlannerApi.getGroupInvitations(groupId),
    enabled: manage,
    staleTime: 0,
  });
  const invitations = toArray(invitationsRaw, 'invitations').filter((i) => i.status === 'pending');
  const { data: consent, error: consentError } = useAiConsent(groupId),
    submitConsent = useSubmitAiConsent(groupId),
    revokeConsent = useRevokeAiConsent(groupId);
  const initial = {
    name: group?.name || '',
    description: group?.description || '',
    start_date: group?.start_date || '',
    end_date: group?.end_date || '',
    estimated_budget: group?.estimated_budget ?? '',
    budget_currency: group?.budget_currency || 'USD',
  };
  const [form, setForm] = useState(initial),
    [saving, setSaving] = useState(false),
    [formError, setFormError] = useState(''),
    [busyMember, setBusyMember] = useState(null),
    [confirm, setConfirm] = useState(null),
    [confirmName, setConfirmName] = useState('');
  const formDirty = useRef(false);
  useEffect(() => {
    if (!formDirty.current) setForm({name: group?.name || '', description: group?.description || '', start_date: group?.start_date || '', end_date: group?.end_date || '', estimated_budget: group?.estimated_budget ?? '', budget_currency: group?.budget_currency || 'USD'});
  }, [group?.name, group?.description, group?.start_date, group?.end_date, group?.estimated_budget, group?.budget_currency]);
  const refresh = () => {
    client.invalidateQueries({predicate: query => (query.queryKey[0] === 'group-planner' && query.queryKey.includes(groupId)) || ['group','groups','mega-bootstrap','expenses','settlements'].includes(query.queryKey[0])});
    for (const key of [
      gpKeys.members(groupId),
      gpKeys.group(groupId),
      gpKeys.groups(),
      gpKeys.activities(groupId),
    ])
      client.invalidateQueries({ queryKey: key });
  };
  const updateRole = async (member, role) => {
    setBusyMember(member.user_id || member.id);
    try {
      await groupPlannerApi.updateMemberRole(groupId, member.user_id || member.id, role);
      refresh();
      showToast('Member role updated');
    } catch (e) {
      showToast(e.message || 'Could not update role', 'error');
    } finally {
      setBusyMember(null);
    }
  };
  const updateCrewRole = async (member, crewRole) => {
    if (busyMember) return;
    setBusyMember(member.user_id || member.id);
    try {
      await groupPlannerApi.updateMemberCrewRole(groupId, member.user_id || member.id, crewRole);
      refresh();
      showToast(
        crewRole ? `Assigned ${CREW_ROLES[crewRole].label}` : 'Trip responsibility cleared',
      );
    } catch (e) {
      showToast(e.message || 'Could not update responsibility', 'error');
    } finally {
      setBusyMember(null);
    }
  };
  const save = async (e) => {
    e.preventDefault();
    if (saving) return;
    setFormError('');
    if (form.start_date && form.end_date && form.end_date < form.start_date) {
      setFormError('End date must be on or after the start date.');
      return;
    }
    setSaving(true);
    try {
      await groupPlannerApi.updateGroup(groupId, {
        ...form,
        name: form.name.trim(),
        estimated_budget: Number(form.estimated_budget || 0),
      });
      refresh();
      formDirty.current = false;
      showToast('Group settings saved');
    } catch (e) {
      setFormError(e.message || 'Could not save settings');
    } finally {
      setSaving(false);
    }
  };
  const confirmAction = async () => {
    if (saving) return;
    setSaving(true);
    try {
      if (confirm.type === 'member')
        await groupPlannerApi.removeMember(groupId, confirm.member.user_id || confirm.member.id);
      else if (confirm.type === 'leave') await groupPlannerApi.leaveGroup(groupId);
      else await groupPlannerApi.deleteGroup(groupId);
      refresh();
      showToast(
        confirm.type === 'member'
          ? 'Member removed'
          : confirm.type === 'leave'
            ? 'You left the group'
            : 'Group deleted',
      );
      if (confirm.type !== 'member') onLeave?.();
      setConfirm(null);
    } catch (e) {
      showToast(e.message || 'Action could not be completed', 'error');
    } finally {
      setSaving(false);
    }
  };
  return (
    <div className="gp-view">
      <div className="gp-tab-heading">
        <div>
          <span className="gp-eyebrow">YOUR PEOPLE. YOUR PLANS.</span>
          <h1>The Circle</h1>
          <p>Meet your travel crew and choose how everyone collaborates.</p>
          <p>{members.length} group members · Owner and admins manage access roles; owners and admins can remove members.</p>
          {manage && <p className="gp-form-hint">Assigning a Treasurer replaces the current Treasurer and transfers ownership of linked expenses. Clearing the duty returns treasury ownership to the trip owner.</p>}
        </div>
        {contribute && (
          <button className="gp-btn-create" onClick={onInvite}>
            <UserPlus size={16} />
            Invite Member
          </button>
        )}
      </div>
      {isLoading ? (
        <p role="status">Loading your crew...</p>
      ) : error ? (
        <p role="alert">{error.message}</p>
      ) : (
        <div className="gp-crew-grid">
          {members.map((member) => {
            const role = roles[member.role] || roles.member,
              Icon = role.Icon,
              id = member.user_id || member.id;
            return (
              <article className="gp-crew-card" key={id}>
                <div className="gp-crew-card-top">
                  {member.photo_url || member.avatar ? (
                    <img src={member.photo_url || member.avatar} alt="" />
                  ) : (
                    <span className="gp-crew-initials">
                      {getInitials(member.display_name || member.email)}
                    </span>
                  )}
                  <span className={'gp-crew-role ' + member.role}>
                    <Icon size={11} />
                    {role.label}
                  </span>
                </div>
                <h2>{member.display_name || member.email}</h2>
                <p>{member.email}</p>
                <span className="gp-crew-description">{role.description}</span>
                {member.crew_role && CREW_ROLES[member.crew_role] && (
                  <div className="gp-crew-responsibility">
                    <strong>{CREW_ROLES[member.crew_role].label}</strong>
                    <span>{CREW_ROLES[member.crew_role].description}</span>
                  </div>
                )}
                <div className="gp-crew-assignment">
                  <label htmlFor={`crew-role-${id}`}>Trip responsibility</label>
                  {manage ? (
                    <select
                      id={`crew-role-${id}`}
                      aria-label={'Trip responsibility for ' + member.display_name}
                      value={member.crew_role || ''}
                      disabled={busyMember === id}
                      onChange={(event) => updateCrewRole(member, event.target.value)}
                    >
                      <option value="">Not assigned</option>
                      {Object.entries(CREW_ROLES).map(([value, info]) => (
                        <option key={value} value={value} disabled={value === 'treasurer' && member.role === 'viewer'}>
                          {info.label}
                        </option>
                      ))}
                    </select>
                  ) : (
                    <span>{CREW_ROLES[member.crew_role]?.label || 'Not assigned'}</span>
                  )}
                </div>
                <div className="gp-crew-controls">
                  {manage && member.role !== 'creator' ? (
                    <select
                      aria-label={'Role for ' + member.display_name}
                      value={member.role || 'member'}
                      disabled={busyMember === id}
                      onChange={(e) => updateRole(member, e.target.value)}
                    >
                      <option value="admin">Admin</option>
                      <option value="member">Member</option>
                      <option value="viewer">Viewer</option>
                    </select>
                  ) : (
                    <span>
                      <Lock size={11} />
                      {member.role === 'creator'
                        ? 'Owner role is protected'
                        : role.label + ' access'}
                    </span>
                  )}
                  {manage && member.role !== 'creator' && String(id) !== String(group?.created_by) && String(id) !== String(currentUser?.uid) && (
                    <button
                      aria-label={'Remove member ' + member.display_name}
                      onClick={() => setConfirm({ type: 'member', member })}
                    >
                      <Trash2 size={13} />
                    </button>
                  )}
                  {String(id) === String(currentUser?.uid) && (
                    <span className="gp-you-chip">You</span>
                  )}
                </div>
              </article>
            );
          })}
        </div>
      )}
      <section className="gp-crew-responsibilities" aria-labelledby="crew-responsibilities-title">
        <div className="gp-tab-heading">
          <div>
            <h2 id="crew-responsibilities-title">Trip Responsibilities</h2>
            <p>
              Owner and Admin control access. Assign a trip responsibility to coordinate the crew's
              work.
            </p>
          </div>
        </div>
        <div className="gp-responsibility-grid">
          {Object.entries(CREW_ROLES).map(([value, info]) => {
            const Icon = value === 'treasurer' ? Wallet : value === 'navigator' ? MapPin : Compass;
            const assigned = members.filter((member) => member.crew_role === value);
            return (
              <article className="gp-feature-card" key={value}>
                <div className="gp-feature-icon">
                  <Icon size={20} />
                </div>
                <h3>{info.label}</h3>
                <p>{info.description}</p>
                <span>
                  {assigned.length
                    ? assigned.map((member) => member.display_name || member.email).join(', ')
                    : 'No one assigned yet'}
                </span>
              </article>
            );
          })}
        </div>
      </section>
      <div className="gp-circle-settings-grid">
        <section className="gp-feature-card">
          <div className="gp-feature-heading">
            <div className="gp-feature-icon">
              <Settings size={20} />
            </div>
            <div>
              <h2>Group Settings</h2>
              <p>
                {manage
                  ? 'Make this adventure your own.'
                  : 'Your trip details. Owners and admins can edit these settings.'}
              </p>
            </div>
          </div>
          <form onSubmit={save}>
            <fieldset onChange={() => {formDirty.current = true;}} className="gp-settings-fieldset" disabled={!manage || saving}>
              <label className="gp-field">
                Group name
                <input
                  className="gp-modal-input"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  required
                  maxLength={200}
                />
              </label>
              <label className="gp-field">
                Trip description
                <textarea
                  className="gp-modal-input"
                  rows={3}
                  value={form.description}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                  maxLength={1000}
                />
              </label>
              <div className="gp-form-columns">
                <label className="gp-field">
                  Start date
                  <input
                    type="date"
                    className="gp-modal-input"
                    value={form.start_date}
                    onChange={(e) => setForm({ ...form, start_date: e.target.value })}
                  />
                </label>
                <label className="gp-field">
                  End date
                  <input
                    type="date"
                    className="gp-modal-input"
                    min={form.start_date || undefined}
                    value={form.end_date}
                    onChange={(e) => setForm({ ...form, end_date: e.target.value })}
                  />
                </label>
              </div>
              <div className="gp-form-columns">
                <label className="gp-field">
                  Trip budget
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    className="gp-modal-input"
                    value={form.estimated_budget}
                    onChange={(e) => setForm({ ...form, estimated_budget: e.target.value })}
                  />
                </label>
                <label className="gp-field">
                  Budget currency
                  <CurrencySelect aria-label="Budget currency" className="gp-modal-input" value={form.budget_currency}
                    onChange={e => setForm({...form, budget_currency: e.target.value})} />
                </label>
              </div>
            </fieldset>
            <p className="gp-settings-destination">
              <strong>Destination</strong>
              <span>{group?.destination || 'Not set'}</span>
            </p>
            {formError && (
              <p role="alert" className="gp-form-error">
                {formError}
              </p>
            )}
            {manage && (
              <button className="gp-modal-btn-primary" disabled={saving}>
                {saving ? 'Saving...' : 'Save Group Settings'}
              </button>
            )}
          </form>
        </section>
        <section className="gp-feature-card">
          <div className="gp-feature-heading">
            <div className="gp-feature-icon">
              <Shield size={20} />
            </div>
            <div>
              <h2>Roles & Permissions</h2>
              <p>Access follows each member's group role.</p>
            </div>
          </div>
          <div className="gp-permission-table-wrap">
            <table className="gp-permission-table">
              <thead>
                <tr>
                  <th>Capability</th>
                  {['Owner', 'Admin', 'Member', 'Viewer'].map((r) => (
                    <th key={r}>{r}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {capabilities.map(([label, allowed]) => (
                  <tr key={label}>
                    <td>{label}</td>
                    {allowed.map((value, i) => (
                      <td key={i} aria-label={value ? 'Allowed' : 'Not allowed'}>
                        {value ? <Check size={14} /> : <span>—</span>}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="gp-form-hint">
            The owner role is fixed. Expense permissions also follow the linked treasury's
            membership and payment rules.
          </p>
        </section>
      </div>
      {manage && (
        <section className="gp-feature-card gp-pending-invites">
          <div className="gp-feature-heading">
            <div className="gp-feature-icon">
              <UserPlus size={20} />
            </div>
            <div>
              <h2>Pending Invitations</h2>
              <p>Share a group's invitation link with its intended recipient.</p>
            </div>
          </div>
          {invitationError ? (
            <p role="alert">{invitationError.message}</p>
          ) : invitations.length === 0 ? (
            <p className="gp-form-hint">
              No pending invitations. Invite a friend to join the crew.
            </p>
          ) : (
            invitations.map((invitation) => (
              <div className="gp-invitation-row" key={invitation.id}>
                <div>
                  <strong>
                    {invitation.invitee_email || invitation.invited_email || invitation.email}
                  </strong>
                  <span>
                    {invitation.expires_at
                      ? 'Expires ' + formatDate(invitation.expires_at)
                      : 'Awaiting response'}
                  </span>
                </div>
                <button
                  className="gp-hub-button"
                  onClick={async () => {
                    try {
                      const link = isPlannerDemo()
                        ? `${window.location.origin}/group-planner/${groupId}?demo=1`
                        : `${window.location.origin}/invitations/${encodeURIComponent(invitation.id || invitation.invitation_id)}`;
                      await navigator.clipboard.writeText(link);
                      showToast('Invitation link copied');
                    } catch {
                      showToast('Unable to copy the link in this browser.', 'error');
                    }
                  }}
                >
                  <Copy size={12} />
                  Copy Link
                </button>
              </div>
            ))
          )}
        </section>
      )}
      <section className="gp-feature-card gp-ai-crew">
        <div className="gp-feature-heading">
          <div className="gp-feature-icon">
            <Sparkles size={20} />
          </div>
          <div>
            <h2>Your AI Crew</h2>
            <p>Optional planning help with controls for your own data.</p>
          </div>
        </div>
        <div className="gp-ai-crew-grid">
          {AI_BOTS.map((bot) => (
            <div key={bot.id}>
              <span className="gp-ai-avatar">
                <Sparkles size={18} />
              </span>
              <div>
                <strong>{bot.display_name}</strong>
                <p>{bot.email}</p>
              </div>
              <span className="gp-eyebrow">AI ASSISTANT</span>
            </div>
          ))}
        </div>
        {consentError ? (
          <p role="alert">{consentError.message}</p>
        ) : (
          <div className="gp-ai-consent-row">
            <p>
              {consent?.has_consent
                ? 'You have enabled AI assistance for this trip.'
                : 'AI assistance is optional. You control your participation.'}
            </p>
            {!consent?.has_consent ? (
              <button
                className="gp-hub-button"
                disabled={submitConsent.isPending}
                onClick={() =>
                  submitConsent.mutate(
                    { granted: true },
                    {
                      onSuccess: () => showToast('AI assistance enabled'),
                      onError: (e) => showToast(e.message, 'error'),
                    },
                  )
                }
              >
                Enable for me
              </button>
            ) : (
              <button
                className="gp-hub-button"
                disabled={revokeConsent.isPending}
                onClick={() =>
                  revokeConsent.mutate(undefined, {
                    onSuccess: () =>
                      showToast('AI consent withdrawn and your saved AI data deleted'),
                    onError: (e) => showToast(e.message, 'error'),
                  })
                }
              >
                Forget my AI data
              </button>
            )}
          </div>
        )}
      </section>
      <div className="gp-circle-danger">
        {owner ? (
          <button
            onClick={() => {
              setConfirmName('');
              setConfirm({ type: 'delete' });
            }}
          >
            <Trash2 size={14} />
            Delete Group
          </button>
        ) : (
          me && (
            <button onClick={() => setConfirm({ type: 'leave' })}>
              <LogOut size={14} />
              Leave Group
            </button>
          )
        )}
      </div>
      {confirm && (
        <div className="gp-modal-overlay" onClick={() => !saving && setConfirm(null)}>
          <div
            className="gp-modal"
            role="dialog"
            aria-modal="true"
            aria-label="Confirm Group Change"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="gp-modal-title">
              {confirm.type === 'member'
                ? 'Remove Member'
                : confirm.type === 'leave'
                  ? 'Leave Group'
                  : 'Delete Group'}
            </h2>
            <p className="gp-form-hint">
              {confirm.type === 'member'
                ? `Remove ${confirm.member.display_name} from this trip?`
                : confirm.type === 'leave'
                  ? 'You will lose access to this group after leaving.'
                  : 'This deletes the group for its members. Type the group name to confirm.'}
            </p>
            {confirm.type === 'delete' && (
              <label className="gp-field">
                Confirm group name
                <input
                  className="gp-modal-input"
                  value={confirmName}
                  onChange={(e) => setConfirmName(e.target.value)}
                />
              </label>
            )}
            <div className="gp-modal-actions">
              <button
                className="gp-danger-button"
                disabled={saving || (confirm.type === 'delete' && confirmName !== group?.name)}
                onClick={confirmAction}
              >
                {saving ? 'Saving...' : 'Confirm'}
              </button>
              <button
                className="gp-modal-btn-secondary"
                disabled={saving}
                onClick={() => setConfirm(null)}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
