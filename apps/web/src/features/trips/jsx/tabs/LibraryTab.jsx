import React, { useMemo, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import {
  Heart,
  MapPin,
  Star,
  Search,
  Plus,
  ArrowRight,
  Compass,
  X,
  ExternalLink,
} from 'lucide-react';
import {
  useDestinationPlaces,
  useDestinationEvents,
  useGroupPlaces,
  gpKeys,
} from '../../../../hooks/useGroupPlannerQuery';
import groupPlannerApi from '../../../../services/groupPlannerApi';
import { unwrap, toArray, tripDayNumber } from '../../utils/groupPlannerUtils';
import { tripDates } from '../../utils/plannerSchedule';
import { isPlannerDemo } from '../../demo/demoMode';

export default function LibraryTab({
  groupId,
  destination,
  group,
  showToast,
  canEdit = true,
  onOpenItinerary,
}) {
  const client = useQueryClient();
  const { data: placesRaw, isLoading, error } = useDestinationPlaces(destination),
    { data: eventsRaw } = useDestinationEvents(destination),
    { data: savedRaw } = useGroupPlaces(groupId);
  const saved = toArray(savedRaw, 'places');
  const [filter, setFilter] = useState('All'),
    [search, setSearch] = useState(''),
    [detail, setDetail] = useState(null),
    [pushing, setPushing] = useState(false),
    [targetDate, setTargetDate] = useState(group?.start_date || '');
  const storageKey = `gp_${isPlannerDemo() ? 'demo_' : ''}shortlist_${groupId}`;
  const [shortlist, setShortlist] = useState(() => {
    try {
      const stored = JSON.parse(localStorage.getItem(storageKey));
      return Array.isArray(stored)
        ? stored
        : isPlannerDemo() && groupId === 'demo-kyoto'
          ? ['place-omurice', 'place-gion']
          : [];
    } catch {
      return [];
    }
  });
  const items = useMemo(() => {
    const data = unwrap(placesRaw),
      list = Array.isArray(data) ? data : data?.places || data?.results || [];
    const events = toArray(eventsRaw, 'events');
    return [
      ...list.map((p) => {
        const tags = (p.tags || []).join(' ').toLowerCase();
        return {
          ...p,
          id: 'place-' + p.id,
          name: p.name,
          theme:
            p.theme ||
            (tags.match(/food|dining|restaurant/)
              ? 'Dining'
              : tags.match(/nightlife|entertainment/)
                ? 'Nightlife'
                : 'Culture'),
          description: p.description || p.ai_summary || '',
          photo_url: p.photo_url || p.photos?.[0]?.url || '',
          rating: p.rating ?? p.rating_tourist_priority,
          website: p.website || p.official_website,
          address: p.address || p.city_name,
        };
      }),
      ...events.map((e) => ({
        ...e,
        id: 'event-' + e.id,
        theme: 'Events',
        description: [e.venue, e.date].filter(Boolean).join(' · '),
        photo_url: e.image_url,
        website: e.url,
        address: e.address || e.venue,
      })),
    ];
  }, [placesRaw, eventsRaw]);
  const dates = tripDates(
    group,
    saved.map((p) => p.visit_date),
  );
  const selected = items.filter((p) => shortlist.includes(p.id));
  const filtered = items.filter(
    (p) =>
      (filter === 'All' || filter === p.theme) &&
      `${p.name} ${p.address || ''}`.toLowerCase().includes(search.toLowerCase()),
  );
  const store = (next) => {
    setShortlist(next);
    try {
      localStorage.setItem(storageKey, JSON.stringify(next));
    } catch {
      /* Keep the shortlist usable without storage. */
    }
  };
  const toggle = (id) =>
    store(shortlist.includes(id) ? shortlist.filter((v) => v !== id) : [...shortlist, id]);
  const push = async () => {
    if (pushing || !targetDate || !selected.length) return;
    setPushing(true);
    const completed = [];
    let failed = 0;
    for (const item of selected) {
      try {
        const existing = saved.find(
          (p) => !p.is_deleted && p.name.toLowerCase() === item.name.toLowerCase(),
        );
        if (existing)
          await groupPlannerApi.updatePlace(groupId, existing.id, { visit_date: targetDate });
        else
          await groupPlannerApi.addPlace(groupId, {
            ...item,
            category:
              item.theme === 'Dining'
                ? 'restaurant'
                : item.theme === 'Events'
                  ? 'event'
                  : 'attraction',
            visit_date: targetDate,
          });
        completed.push(item.id);
      } catch {
        failed++;
      }
    }
    store(shortlist.filter((id) => !completed.includes(id)));
    client.invalidateQueries({ queryKey: gpKeys.places(groupId) });
    client.invalidateQueries({ queryKey: gpKeys.activities(groupId) });
    setPushing(false);
    if (completed.length)
      showToast(
        `${completed.length} place${completed.length === 1 ? '' : 's'} added to your itinerary`,
      );
    if (failed)
      showToast(
        `${failed} place${failed === 1 ? '' : 's'} could not be added. Your selection is kept for retry.`,
        'error',
      );
  };
  return (
    <div className="gp-view gp-library-view">
      <div className="gp-tab-heading">
        <div>
          <span className="gp-eyebrow">DISCOVER & DECIDE</span>
          <h1>Curated {destination?.split(',')[0] || 'Travel'} Library</h1>
          <p>Explore local places, find your favorites, and build a day worth sharing.</p>
        </div>
        <span className="gp-tab-count">
          <Compass size={15} />
          {items.length} places to explore
        </span>
      </div>
      <div className="gp-library-toolbar">
        <div className="gp-filter-pills">
          {['All', 'Dining', 'Culture', 'Nightlife', 'Events'].map((theme) => (
            <button
              key={theme}
              className={filter === theme ? 'active' : ''}
              aria-pressed={filter === theme}
              onClick={() => setFilter(theme)}
            >
              {theme}
            </button>
          ))}
        </div>
        <label className="gp-search-field">
          <Search size={15} />
          <input
            aria-label="Search destination library"
            placeholder="Find a place or neighborhood..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </label>
      </div>
      {isLoading ? (
        <p role="status">Finding local gems...</p>
      ) : error ? (
        <div className="gp-empty-agenda" role="alert">
          {error.message}
        </div>
      ) : filtered.length === 0 ? (
        <div className="gp-empty-agenda">
          <Compass size={30} />
          <h3>No places match this search</h3>
          <p>
            {destination
              ? 'Try another category or search.'
              : 'Set your destination in Group Settings to discover places.'}
          </p>
        </div>
      ) : (
        <div className="gp-discovery-grid">
          {filtered.map((item) => (
            <article className="gp-discovery-card" key={item.id}>
              <div className="gp-discovery-image">
                <button onClick={() => setDetail(item)} aria-label={'View ' + item.name}>
                  {item.photo_url ? (
                    <img src={item.photo_url} alt="" loading="lazy" />
                  ) : (
                    <span className="gp-discovery-placeholder">
                      <Compass size={40} />
                    </span>
                  )}
                </button>
                <span className="gp-discovery-theme">{item.theme}</span>
                {canEdit && (
                  <button
                    className={
                      'gp-shortlist-button' + (shortlist.includes(item.id) ? ' selected' : '')
                    }
                    aria-label={`${shortlist.includes(item.id) ? 'Unshortlist' : 'Shortlist'} ${item.name}`}
                    aria-pressed={shortlist.includes(item.id)}
                    onClick={() => toggle(item.id)}
                  >
                    <Heart size={17} fill={shortlist.includes(item.id) ? 'currentColor' : 'none'} />
                  </button>
                )}
              </div>
              <div className="gp-discovery-body">
                <div className="gp-discovery-title">
                  <button onClick={() => setDetail(item)}>
                    <h2>{item.name}</h2>
                  </button>
                  {item.rating != null && (
                    <span>
                      <Star size={11} fill="currentColor" />
                      {Number(item.rating).toFixed(1)}
                    </span>
                  )}
                </div>
                <p className="gp-discovery-address">
                  <MapPin size={12} />
                  {item.address || destination}
                </p>
                <p className="gp-discovery-description">{item.description}</p>
                <div className="gp-discovery-footer">
                  <button onClick={() => setDetail(item)}>
                    View details
                    <ArrowRight size={13} />
                  </button>
                  <span>
                    {saved.some(
                      (p) => p.visit_date && p.name.toLowerCase() === item.name.toLowerCase(),
                    )
                      ? 'In your itinerary'
                      : shortlist.includes(item.id)
                        ? 'Shortlisted'
                        : ''}
                  </span>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}
      {selected.length > 0 && canEdit && (
        <div className="gp-shortlist-dock">
          <div className="gp-shortlist-count">{selected.length}</div>
          <div className="gp-shortlist-summary">
            <strong>Places Shortlisted</strong>
            <span>{selected.map((p) => p.name).join(', ')}</span>
          </div>
          <label className="gp-field">
            <span className="gp-sr-only">Add shortlisted places to date</span>
            {dates.length ? (
              <select
                aria-label="Shortlist day"
                value={targetDate}
                onChange={(e) => setTargetDate(e.target.value)}
              >
                {dates.map((date) => (
                  <option value={date} key={date}>
                    Day {tripDayNumber(date, group?.start_date, dates)} ·{' '}
                    {new Date(date + 'T12:00:00').toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                    })}
                  </option>
                ))}
              </select>
            ) : (
              <input
                type="date"
                aria-label="Shortlist date"
                value={targetDate}
                onChange={(e) => setTargetDate(e.target.value)}
              />
            )}
          </label>
          <button className="gp-btn-create" disabled={pushing || !targetDate} onClick={push}>
            {pushing ? 'Adding...' : 'Push to Itinerary'}
            <ArrowRight size={15} />
          </button>
          {onOpenItinerary && (
            <button
              className="gp-icon-button"
              onClick={onOpenItinerary}
              aria-label="Open itinerary"
            >
              <Compass size={16} />
            </button>
          )}
        </div>
      )}
      {detail && (
        <div className="gp-modal-overlay" onClick={() => setDetail(null)}>
          <div
            className="gp-modal gp-place-detail"
            role="dialog"
            aria-modal="true"
            aria-label={detail.name}
            onClick={(e) => e.stopPropagation()}
          >
            {detail.photo_url && <img src={detail.photo_url} className="gp-detail-photo" alt="" />}
            <button
              className="gp-detail-close gp-icon-button"
              aria-label="Close place details"
              onClick={() => setDetail(null)}
            >
              <X size={17} />
            </button>
            <span className="gp-eyebrow">{detail.theme}</span>
            <h2>{detail.name}</h2>
            <p className="gp-discovery-address">
              <MapPin size={13} />
              {detail.address || destination}
            </p>
            <p className="gp-detail-description">{detail.description}</p>
            <div className="gp-modal-actions">
              {canEdit && (
                <button className="gp-modal-btn-primary" onClick={() => toggle(detail.id)}>
                  {shortlist.includes(detail.id) ? 'Remove from Shortlist' : 'Add to Shortlist'}
                </button>
              )}
              {/^https?:\/\//i.test(detail.website || '') && (
                <a
                  className="gp-modal-btn-secondary"
                  href={detail.website}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Visit website
                  <ExternalLink size={12} />
                </a>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
