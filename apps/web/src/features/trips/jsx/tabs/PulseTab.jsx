// Purpose: Shows a filterable activity feed alongside group/poll/member context and links relevant activity to workspace tabs.
import React, { useMemo, useState } from 'react';
import {
  Activity,
  MapPin,
  BarChart3,
  Wallet,
  Ticket,
  Users,
  ArrowUpRight,
  CheckCircle2,
} from 'lucide-react';
import {
  useGroupActivities,
  useGroupPolls,
  useGroupMembers,
} from '../../../../hooks/useGroupPlannerQuery';
import { toArray } from '../../utils/groupPlannerUtils';
import { formatActivityMessage, formatRelativeTime, getInitials, parsePlannerInstant } from '../../utils/formatters';
const category = (event) => {
  const type = String(event.entity_type || '') + ' ' + String(event.action || '');
  return /place|itinerary/.test(type)
    ? 'Places'
    : /poll/.test(type)
      ? 'Polls'
      : /expense|budget|settlement/.test(type)
        ? 'Budget'
        : /vault|checklist/.test(type)
          ? 'Logistics'
          : 'Crew';
};
const config = {
  Places: { Icon: MapPin, tab: 'itinerary' },
  Polls: { Icon: BarChart3, tab: 'chat' },
  Budget: { Icon: Wallet, tab: 'treasury' },
  Logistics: { Icon: Ticket, tab: 'logistics' },
  Crew: { Icon: Users, tab: 'circle' },
};
export default function PulseTab({ groupId, onOpenTab }) {
  const { data: raw, isLoading, error, refetch } = useGroupActivities(groupId),
    { data: pollRaw } = useGroupPolls(groupId),
    { data: memberRaw } = useGroupMembers(groupId);
  const [filter, setFilter] = useState('All');
  const members = toArray(memberRaw, 'members');
  const events = useMemo(() => {
    const activities = toArray(raw, 'activities').filter(
      (a) => a.entity_type !== 'chat' && !String(a.action).startsWith('message_'),
    );
    const polls = toArray(pollRaw, 'polls')
      .filter(
        (p) =>
          !activities.some(
            (a) =>
              a.entity_id === p.id || (a.action === 'poll_created' && a.details?.name === p.name),
          ),
      )
      .map((p) => ({
        id: 'poll-' + p.id,
        action: 'poll_created',
        entity_type: 'poll',
        details: { name: p.name },
        user_name: p.created_by_name,
        user_id: p.created_by,
        created_at: p.created_at,
      }));
    return [...activities, ...polls].sort(
      (a, b) => (parsePlannerInstant(b.created_at).getTime() || 0) - (parsePlannerInstant(a.created_at).getTime() || 0),
    );
  }, [raw, pollRaw]);
  const visible = events.filter((e) => filter === 'All' || category(e) === filter);
  return (
    <div className="gp-view gp-pulse-view">
      <div className="gp-tab-heading">
        <div>
          <span className="gp-eyebrow">EVERYONE ON THE SAME PAGE</span>
          <h1>Group Pulse</h1>
          <p>Itinerary updates, group decisions, and shared costs in one clear timeline.</p>
        </div>
        <span className="gp-tab-count">
          <Activity size={15} />
          {events.length} updates
        </span>
      </div>
      <div className="gp-filter-pills gp-pulse-filters">
        {['All', 'Places', 'Polls', 'Budget', 'Logistics', 'Crew'].map((c) => (
          <button
            key={c}
            className={filter === c ? 'active' : ''}
            aria-pressed={filter === c}
            onClick={() => setFilter(c)}
          >
            {c}
            <span>
              {c === 'All' ? events.length : events.filter((e) => category(e) === c).length}
            </span>
          </button>
        ))}
      </div>
      {isLoading ? (
        <p role="status">Loading group updates...</p>
      ) : error ? (
        <div role="alert" className="gp-empty-agenda">
          <p>{error.message}</p>
          <button className="gp-section-action" onClick={refetch}>
            Try again
          </button>
        </div>
      ) : visible.length === 0 ? (
        <div className="gp-empty-agenda">
          <Activity size={30} />
          <h3>No {filter === 'All' ? 'group' : filter.toLowerCase()} updates yet</h3>
          <p>New activity will appear here as your group plans together.</p>
        </div>
      ) : (
        <div className="gp-activity-timeline">
          {visible.map((event, index) => {
            const cat = category(event),
              { Icon, tab } = config[cat],
              person = members.find(
                (m) =>
                  String(m.user_id || m.id) === String(event.user_id) ||
                  m.display_name === event.user_name,
              );
            const day = event.created_at
              ? parsePlannerInstant(event.created_at).toLocaleDateString('en-US', {
                  weekday: 'long',
                  month: 'short',
                  day: 'numeric',
                })
              : 'Recent updates';
            const previous = visible[index - 1]?.created_at;
            const sameDay =
              previous &&
              parsePlannerInstant(previous).toDateString() === parsePlannerInstant(event.created_at).toDateString();
            return (
              <React.Fragment key={event.id || index}>
                {!sameDay && <h2 className="gp-activity-day">{day}</h2>}
                <article className={'gp-activity-row gp-activity-' + cat.toLowerCase()}>
                  <div className="gp-activity-symbol">
                    <Icon size={17} />
                  </div>
                  <div className="gp-activity-card">
                    <div className="gp-activity-meta">
                      <span className="gp-activity-category">{cat}</span>
                      <time dateTime={event.created_at}>
                        {formatRelativeTime(event.created_at)}
                      </time>
                    </div>
                    <p>
                      <strong>{event.user_name || 'A group member'}</strong>{' '}
                      {formatActivityMessage(event)}
                    </p>
                    <div className="gp-activity-footer">
                      <span className="gp-activity-person">
                        {person?.photo_url ? (
                          <img src={person.photo_url} alt="" />
                        ) : (
                          <span>{getInitials(event.user_name || 'Group')}</span>
                        )}
                        {event.user_name || 'Group activity'}
                      </span>
                      {onOpenTab && (
                        <button onClick={() => onOpenTab(tab)}>
                          View {cat === 'Crew' ? 'Circle' : cat === 'Budget' ? 'Treasury' : cat}
                          <ArrowUpRight size={12} />
                        </button>
                      )}
                    </div>
                  </div>
                </article>
              </React.Fragment>
            );
          })}
        </div>
      )}
    </div>
  );
}
