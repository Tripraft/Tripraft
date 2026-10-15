import React, { useEffect, useRef, useState } from 'react';
import { X, MapPin, Users, Calendar, Loader2, Mail } from 'lucide-react';
import groupPlannerApi from '../../../services/groupPlannerApi';
import { unwrap } from '../utils/groupPlannerUtils';
import '../css/CreateGroupModal.css';

export default function CreateGroupModal({ isOpen, onClose, onCreateGroup, isLoading = false }) {
  const [name, setName] = useState('');
  const [query, setQuery] = useState('');
  const [kind, setKind] = useState('all');
  const [destination, setDestination] = useState(null);
  const [dates, setDates] = useState({ start: '', end: '' });
  const [emails, setEmails] = useState('');
  const [suggestions, setSuggestions] = useState([]);
  const [open, setOpen] = useState(false);
  const [searchLoading, setSearchLoading] = useState(false);
  const [searchError, setSearchError] = useState('');
  const [errors, setErrors] = useState({});
  const [highlight, setHighlight] = useState(-1);
  const inputRef = useRef(null);
  useEffect(() => {
    if (!isOpen) return;
    setName('');
    setQuery('');
    setKind('all');
    setDestination(null);
    setDates({ start: '', end: '' });
    setEmails('');
    setErrors({});
    setOpen(false);
    setSuggestions([]);
    setHighlight(-1);
  }, [isOpen]);
  useEffect(() => {
    if (!isOpen || !open || destination) return;
    let active = true;
    setSearchLoading(true);
    setSearchError('');
    const timer = setTimeout(async () => {
      try {
        const data = unwrap(await groupPlannerApi.searchCatalogDestinations(query, kind));
        if (active) {
          setSuggestions(Array.isArray(data) ? data : []);
          setHighlight(-1);
        }
      } catch (error) {
        if (active) {
          setSuggestions([]);
          setSearchError(error.message || 'Unable to load destinations.');
        }
      } finally {
        if (active) setSearchLoading(false);
      }
    }, 250);
    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [query, kind, open, destination, isOpen]);
  const select = (item) => {
    setDestination(item);
    setQuery(item.display_name);
    setOpen(false);
    setSuggestions([]);
    setSearchLoading(false);
    setErrors((old) => ({ ...old, destination: '' }));
  };
  const submit = (event) => {
    event.preventDefault();
    if (isLoading) return;
    const next = {};
    const inviteEmails = [
      ...new Set(
        emails
          .split(',')
          .map((v) => v.trim().toLowerCase())
          .filter(Boolean),
      ),
    ];
    if (!name.trim()) next.name = 'Group name is required';
    if (!destination)
      next.destination = 'Select a country, state, or city from the catalog suggestions.';
    if (dates.start && dates.end && dates.end < dates.start)
      next.dates = 'End date must be on or after the start date.';
    if (inviteEmails.some((v) => !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)))
      next.emails = 'Enter valid email addresses separated by commas.';
    setErrors(next);
    if (Object.keys(next).length) return;
    onCreateGroup({
      name: name.trim(),
      destination: destination.display_name,
      destination_id: destination.id,
      destination_type: destination.type,
      destination_lat: destination.lat ?? null,
      destination_lng: destination.lng ?? null,
      start_date: dates.start || null,
      end_date: dates.end || null,
      invite_emails: inviteEmails,
    });
  };
  if (!isOpen) return null;
  return (
    <div className="cgm-overlay" onClick={() => !isLoading && onClose()}>
      <div
        className="cgm-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="create-group-title"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="cgm-header">
          <h2 id="create-group-title" className="cgm-title">
            Create New Group
          </h2>
          <button
            className="cgm-close-btn"
            aria-label="Close create group"
            disabled={isLoading}
            onClick={onClose}
          >
            <X size={20} />
          </button>
        </div>
        <form onSubmit={submit} className="cgm-form">
          <div className="cgm-field">
            <label className="cgm-label" htmlFor="group-name">
              <Users size={16} />
              Group Name *
            </label>
            <input
              id="group-name"
              className="cgm-input"
              placeholder="e.g., Summer Vacation 2026"
              value={name}
              maxLength={200}
              onChange={(e) => setName(e.target.value)}
              autoFocus
              disabled={isLoading}
            />
            {errors.name && (
              <span className="cgm-error" role="alert">
                {errors.name}
              </span>
            )}
          </div>
          <div className="cgm-field">
            <label className="cgm-label" htmlFor="group-destination">
              <MapPin size={16} />
              Destination *
            </label>
            <div className="cgm-destination-types" aria-label="Destination type">
              {['all', 'country', 'state', 'city'].map((type) => (
                <button
                  key={type}
                  type="button"
                  aria-pressed={kind === type}
                  disabled={isLoading}
                  onClick={() => {
                    setKind(type);
                    setQuery('');
                    setDestination(null);
                    setSuggestions([]);
                    setHighlight(-1);
                    setOpen(true);
                    inputRef.current?.focus();
                  }}
                >
                  {type === 'all'
                    ? 'All'
                    : type === 'country'
                      ? 'Countries'
                      : type === 'state'
                        ? 'States'
                        : 'Cities'}
                </button>
              ))}
            </div>
            <div className="cgm-input-wrapper">
              <input
                id="group-destination"
                ref={inputRef}
                className="cgm-input"
                placeholder="Search country, state, or city..."
                role="combobox"
                aria-expanded={open && !destination}
                aria-controls="destination-choices"
                aria-autocomplete="list"
                aria-activedescendant={
                  open && highlight >= 0 ? `destination-choice-${highlight}` : undefined
                }
                value={query}
                autoComplete="off"
                disabled={isLoading}
                onChange={(e) => {
                  setQuery(e.target.value);
                  setDestination(null);
                  setSuggestions([]);
                  setHighlight(-1);
                  setOpen(true);
                }}
                onFocus={() => !destination && setOpen(true)}
                onKeyDown={(e) => {
                  if (e.key === 'Escape') {
                    setOpen(false);
                    return;
                  }
                  if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
                    e.preventDefault();
                    setOpen(true);
                    setHighlight((old) =>
                      Math.max(
                        0,
                        Math.min(suggestions.length - 1, old + (e.key === 'ArrowDown' ? 1 : -1)),
                      ),
                    );
                  }
                  if (e.key === 'Enter' && open && highlight >= 0 && suggestions[highlight]) {
                    e.preventDefault();
                    select(suggestions[highlight]);
                  }
                }}
              />
              {searchLoading && open && <Loader2 className="cgm-input-loader" size={16} />}
            </div>
            {open && !destination && (
              <div className="cgm-catalog-results">
                {searchError ? (
                  <p role="alert">{searchError}</p>
                ) : searchLoading ? (
                  <p role="status">Searching destinations...</p>
                ) : suggestions.length === 0 ? (
                  <p>No matching destinations in the catalog.</p>
                ) : null}
                <div id="destination-choices" role="listbox" aria-label="Catalog destinations">
                  {suggestions.map((item, index) => (
                    <button
                      id={`destination-choice-${index}`}
                      type="button"
                      role="option"
                      aria-selected={highlight === index}
                      className="cgm-suggestion-item"
                      key={`${item.type}-${item.id}`}
                      onMouseDown={(e) => e.preventDefault()}
                      onClick={() => select(item)}
                    >
                      <MapPin size={15} />
                      <span className="cgm-suggestion-text">
                        <span className="cgm-suggestion-name">{item.display_name}</span>
                        <span className="cgm-suggestion-country">
                          {item.type === 'country'
                            ? 'Country'
                            : item.type === 'state'
                              ? 'State / region'
                              : 'City'}
                        </span>
                      </span>
                    </button>
                  ))}
                </div>
              </div>
            )}
            {destination && (
              <p className="cgm-hint cgm-destination-note">
                {destination.type === 'country'
                  ? 'Library will show places across all states and cities in this country.'
                  : destination.type === 'state'
                    ? 'Library will show places across all cities in this state / region.'
                    : 'Library will show all places in this city.'}
              </p>
            )}
            {errors.destination && (
              <span className="cgm-error" role="alert">
                {errors.destination}
              </span>
            )}
          </div>
          <div className="cgm-field-row">
            <div className="cgm-field">
              <label className="cgm-label" htmlFor="group-start">
                <Calendar size={16} />
                Start Date
              </label>
              <input
                id="group-start"
                type="date"
                className="cgm-input"
                value={dates.start}
                onChange={(e) => setDates({ ...dates, start: e.target.value })}
                disabled={isLoading}
              />
            </div>
            <div className="cgm-field">
              <label className="cgm-label" htmlFor="group-end">
                <Calendar size={16} />
                End Date
              </label>
              <input
                id="group-end"
                type="date"
                className="cgm-input"
                min={dates.start || undefined}
                value={dates.end}
                onChange={(e) => setDates({ ...dates, end: e.target.value })}
                disabled={isLoading}
              />
            </div>
          </div>
          {errors.dates && (
            <span className="cgm-error" role="alert">
              {errors.dates}
            </span>
          )}
          <div className="cgm-field">
            <label className="cgm-label" htmlFor="group-invites">
              <Mail size={16} />
              Invite friends <span className="cgm-optional">(optional)</span>
            </label>
            <textarea
              id="group-invites"
              className="cgm-input cgm-invite-input"
              rows={2}
              placeholder="alex@example.com, sarah@example.com"
              value={emails}
              onChange={(e) => setEmails(e.target.value)}
              aria-describedby="group-invites-hint"
              disabled={isLoading}
            />
            <p id="group-invites-hint" className="cgm-hint">
              You can send invitations later. Separate multiple email addresses with commas.
            </p>
            {errors.emails && (
              <span className="cgm-error" role="alert">
                {errors.emails}
              </span>
            )}
          </div>
          <div className="cgm-actions">
            <button type="button" className="cgm-cancel-btn" disabled={isLoading} onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="cgm-submit-btn" disabled={isLoading}>
              {isLoading ? (
                <>
                  <Loader2 className="cgm-btn-loader" size={16} />
                  Creating...
                </>
              ) : (
                'Create Group'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
