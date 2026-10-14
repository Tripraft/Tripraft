import React from 'react';
import {
  Compass,
  Map,
  Luggage,
  Wallet,
  Activity,
  Users,
  Plus,
  Search,
  LayoutGrid,
} from 'lucide-react';
import { TABS } from '../../constants/tabConfig';
import { getInitials } from '../../utils/formatters';

const icons = {
  itinerary: Map,
  library: Compass,
  logistics: Luggage,
  treasury: Wallet,
  pulse: Activity,
  circle: Users,
};

export default function PlannerHeader({
  groups,
  group,
  activeTab,
  onTabChange,
  onSelectGroup,
  onAllGroups,
  onCreateGroup,
  onSearch,
  members = [],
  pulseUnread,
}) {
  return (
    <header className="gp-topbar">
      <div className="gp-topbar-context">
        <button className="gp-hub-button" aria-label="All Groups" onClick={onAllGroups}>
          <LayoutGrid size={15} />
          <span>All Groups</span>
          <b>{groups.length}</b>
        </button>
        {group && (
          <>
            <span className="gp-header-divider">/</span>
            <label className="gp-group-switcher">
              <span className="gp-trip-icon">
                <Map size={16} />
              </span>
              <select
                aria-label="Active group"
                value={group.id}
                onChange={(e) => onSelectGroup(e.target.value)}
              >
                {groups.some((g) => String(g.id) === String(group.id)) ? null : (
                  <option value={group.id}>{group.name}</option>
                )}
                {groups.map((g) => (
                  <option key={g.id} value={g.id}>
                    {g.name}
                  </option>
                ))}
              </select>
            </label>
          </>
        )}
      </div>
      {group && (
        <nav className="gp-tabs" aria-label="Group planner tabs">
          {TABS.map((tab) => {
            const Icon = icons[tab.key];
            return (
              <button
                key={tab.key}
                className={'gp-tab' + (activeTab === tab.key ? ' active' : '')}
                aria-current={activeTab === tab.key ? 'page' : undefined}
                onClick={() => onTabChange(tab.key)}
              >
                <Icon size={15} />
                {tab.label}
                {tab.key === 'pulse' && pulseUnread && <span className="gp-tab-pulse-dot" />}
              </button>
            );
          })}
        </nav>
      )}
      <div className="gp-topbar-actions">
        {group && (
          <>
            <button
              className="gp-icon-button"
              title="Quick search (Ctrl+K)"
              aria-label="Quick search"
              onClick={onSearch}
            >
              <Search size={17} />
            </button>
            <button
              className="gp-member-avatars"
              onClick={() => onTabChange('circle')}
              aria-label="View group members"
            >
              {members.slice(0, 3).map((m) => (
                <span
                  key={m.id || m.user_id}
                  className="gp-member-avatar"
                  title={m.display_name || m.email}
                >
                  {m.photo_url || m.avatar ? (
                    <img src={m.photo_url || m.avatar} alt={m.display_name || 'Member'} />
                  ) : (
                    getInitials(m.display_name || m.email || 'Member')
                  )}
                </span>
              ))}
              {members.length > 3 && (
                <span className="gp-member-avatar">+{members.length - 3}</span>
              )}
            </button>
          </>
        )}
        <button className="gp-btn-create" aria-label="New Group" onClick={onCreateGroup}>
          <Plus size={16} />
          <span>New Group</span>
        </button>
      </div>
    </header>
  );
}
