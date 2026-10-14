import React, { useState } from 'react';
import { isPlannerDemo } from '../../demo/demoMode';
import {
  MapPin,
  Plus,
  Search,
  Users,
  Calendar,
  ArrowUpRight,
  Pin,
  Compass,
  KeyRound,
  X,
} from 'lucide-react';
import { formatDateRange, formatCurrency, getInitials } from '../../utils/formatters';

function tripStatus(group) {
  const now = new Date();
  const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  if (group.end_date && group.end_date < today) return 'Completed';
  if (group.start_date && group.start_date <= today && (!group.end_date || group.end_date >= today))
    return 'Live';
  return 'Planning';
}

export default function GroupSelector({
  groups,
  groupsLoading,
  error,
  onRetry,
  onSelectGroup,
  onCreateGroup,
  onJoinGroup,
}) {
  const [search, setSearch] = useState('');
  const [joining, setJoining] = useState(false);
  const [invite, setInvite] = useState('');
  const [inviteError, setInviteError] = useState('');
  const [filter, setFilter] = useState('All');
  const [pinned, setPinned] = useState(() => {
    try {
      const saved = JSON.parse(localStorage.getItem('gp_pinned_groups') || '[]');
      return Array.isArray(saved) ? saved : [];
    } catch {
      return [];
    }
  });
  const togglePin = (id) => {
    const next = pinned.includes(String(id))
      ? pinned.filter((item) => item !== String(id))
      : [...pinned, String(id)];
    setPinned(next);
    localStorage.setItem('gp_pinned_groups', JSON.stringify(next));
  };
  const join = (event) => {
    event.preventDefault();
    let id = invite.trim();
    if (id.includes('/')) {
      try {
        const url = new URL(id, window.location.origin);
        id =
          url.searchParams.get('id') ||
          url.pathname.match(/\/invitations?\/([^/]+)\/?$/)?.[1] ||
          '';
      } catch {
        id = '';
      }
    }
    if (!/^[a-zA-Z0-9-]{1,128}$/.test(id)) {
      setInviteError('Enter a valid group invitation link or invitation ID.');
      return;
    }
    onJoinGroup(id);
  };
  const filtered = groups.filter(
    (g) =>
      `${g.name} ${g.destination || ''}`.toLowerCase().includes(search.toLowerCase()) &&
      (filter === 'All' ||
        (filter === 'Pinned' ? pinned.includes(String(g.id)) : tripStatus(g) === filter)),
  );
  return (
    <div className="gp-dashboard">
      <div className="gp-dashboard-header">
        <div>
          <span className="gp-eyebrow">Workspace Hub</span>
          <h1>Your Group Trips</h1>
          <p>Good company. Great adventures. Everything you need to plan together.</p>
        </div>
        <div className="gp-hub-hero-actions">
          {!isPlannerDemo() && (
            <a className="gp-hub-button" href="/group-planner?demo=1">
              Explore demo
            </a>
          )}
          {onJoinGroup && (
            <button
              className="gp-hub-button"
              onClick={() => {
                setJoining(true);
                setInviteError('');
              }}
            >
              <KeyRound size={15} />
              Join via Invite
            </button>
          )}
          <button className="gp-btn-create" onClick={onCreateGroup}>
            <Plus size={17} />
            Create New Group
          </button>
        </div>
      </div>
      <div className="gp-hub-toolbar">
        <div className="gp-filter-pills" aria-label="Filter trips">
          {[
            ['All', 'All Trips'],
            ['Planning', 'Planning Now'],
            ['Live', 'Live / Active'],
            ['Pinned', '★ Pinned'],
            ['Completed', 'Completed'],
          ].map(([key, label]) => (
            <button
              key={key}
              className={filter === key ? 'active' : ''}
              aria-pressed={filter === key}
              onClick={() => setFilter(key)}
            >
              {label}
            </button>
          ))}
        </div>
        <label className="gp-search-field">
          <Search size={16} />
          <input
            aria-label="Search groups"
            placeholder="Search group name or destination…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </label>
      </div>
      {groupsLoading ? (
        <div className="gp-loading" role="status">
          <div className="gp-loading-spinner" />
          Loading your groups…
        </div>
      ) : error ? (
        <div className="gp-empty-agenda" role="alert">
          {error.message || 'Unable to load your groups.'}
          <button className="gp-section-action" onClick={onRetry}>
            Try again
          </button>
        </div>
      ) : (
        <>
          {filtered.length === 0 && (
            <div className="gp-empty-agenda">
              <Compass size={30} />
              <h3>{groups.length ? 'No matching trips' : 'Your next adventure starts here'}</h3>
              <p>
                {groups.length
                  ? 'Try another search or filter.'
                  : 'Create a group and bring your plans together.'}
              </p>
            </div>
          )}
          <div className="gp-groups-grid">
            {filtered.map((g, index) => (
              <article key={g.id} className="gp-group-card">
                <div className={'gp-group-cover gp-cover-' + (index % 3)}>
                  {g.group_image && (
                    <img
                      className="gp-group-cover-photo"
                      src={g.group_image}
                      alt=""
                      loading="lazy"
                    />
                  )}
                  <Compass className="gp-cover-compass" size={116} strokeWidth={0.7} />
                  <span className="gp-trip-icon">{getInitials(g.destination || g.name)}</span>
                  <span className={'gp-status gp-status-' + tripStatus(g).toLowerCase()}>
                    {tripStatus(g)}
                  </span>
                  <button
                    className={'gp-pin-button' + (pinned.includes(String(g.id)) ? ' active' : '')}
                    aria-label={`${pinned.includes(String(g.id)) ? 'Unpin' : 'Pin'} ${g.name}`}
                    aria-pressed={pinned.includes(String(g.id))}
                    onClick={() => togglePin(g.id)}
                  >
                    <Pin size={15} />
                  </button>
                </div>
                <div className="gp-group-card-body">
                  <button className="gp-group-open" onClick={() => onSelectGroup(g.id)}>
                    <h2>{g.name}</h2>
                    <ArrowUpRight size={18} />
                  </button>
                  <p className="gp-group-card-dest">
                    <MapPin size={13} />
                    {g.destination || 'Destination to be decided'}
                  </p>
                  <div className="gp-group-card-meta">
                    <span>
                      <Calendar size={13} />
                      {g.start_date
                        ? formatDateRange(g.start_date, g.end_date)
                        : 'Dates to be decided'}
                    </span>
                    <span>
                      <Users size={13} />
                      {g.member_count ?? 0} members
                    </span>
                  </div>
                  <div className="gp-group-budget">
                    <span>Trip budget</span>
                    <strong>
                      {g.estimated_budget != null
                        ? formatCurrency(g.estimated_budget, g.budget_currency)
                        : 'Not set yet'}
                    </strong>
                  </div>
                  <button className="gp-open-workspace" onClick={() => onSelectGroup(g.id)}>
                    Open Workspace
                    <ArrowUpRight size={14} />
                  </button>
                </div>
              </article>
            ))}
            <button className="gp-new-trip-card" onClick={onCreateGroup}>
              <span>
                <Plus size={25} />
              </span>
              <strong>Start a new adventure</strong>
              <small>Create a group trip</small>
            </button>
          </div>
        </>
      )}
      {joining && (
        <div className="gp-modal-overlay" onClick={() => setJoining(false)}>
          <form
            className="gp-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="gp-join-title"
            onSubmit={join}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="gp-section-header">
              <h2 id="gp-join-title" className="gp-modal-title">
                Join a Group
              </h2>
              <button
                type="button"
                className="gp-icon-button"
                onClick={() => setJoining(false)}
                aria-label="Close join group"
              >
                <X size={16} />
              </button>
            </div>
            <label className="gp-modal-label" htmlFor="gp-join-invite">
              Invitation link or ID
            </label>
            <input
              id="gp-join-invite"
              className="gp-modal-input"
              value={invite}
              onChange={(e) => setInvite(e.target.value)}
              required
              autoFocus
            />
            <p className="gp-form-hint">
              Paste the invitation shared by your trip organizer to review and join their group.
            </p>
            {inviteError && <p role="alert">{inviteError}</p>}
            <button className="gp-modal-btn-primary" type="submit">
              Review Invitation
            </button>
          </form>
        </div>
      )}
    </div>
  );
}
