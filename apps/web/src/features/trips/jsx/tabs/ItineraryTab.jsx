// Purpose: Displays the daily schedule, including empty trip dates, and supports stop edits, moves and removal with query refresh.
import React, { useMemo, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Calendar, Plus, Pencil, Trash2, ArrowUp, ArrowDown, MapPin, Clock } from 'lucide-react';
import { useGroupPlaces, gpKeys } from '../../../../hooks/useGroupPlannerQuery';
import groupPlannerApi from '../../../../services/groupPlannerApi';
import { toArray, tripDayNumber } from '../../utils/groupPlannerUtils';
import { tripDates, distanceKm, stopTimeSlots } from '../../utils/plannerSchedule';
import { formatDate, formatDateRange } from '../../utils/formatters';
import TripDateSelect from '../shared/TripDateSelect';

export default function ItineraryTab({
  groupId,
  group,
  showToast,
  activeDay: controlledDay,
  onDayChange,
  onAddStop,
  selectedPlaceId,
  onSelectPlace,
  canEdit = true,
  onOpenLibrary,
}) {
  const client = useQueryClient();
  const { data: raw, isLoading, error } = useGroupPlaces(groupId);
  const places = useMemo(() => toArray(raw, 'places').filter((p) => !p.is_deleted), [raw]);
  const dates = useMemo(
    () =>
      tripDates(
        group,
        places.map((p) => p.visit_date),
      ),
    [group, places],
  );
  const [localDay, setLocalDay] = useState('all');
  const activeDay = controlledDay ?? localDay,
    setDay = onDayChange || setLocalDay;
  const [editing, setEditing] = useState(null),
    [removing, setRemoving] = useState(null),
    [saving, setSaving] = useState(false),
    [formError, setFormError] = useState('');
  const visible = places
    .filter(
      (p) =>
        p.visit_date &&
        (activeDay === 'all' ||
          String(tripDayNumber(p.visit_date, group?.start_date, dates)) === activeDay),
    )
    .sort(
      (a, b) =>
        a.visit_date.localeCompare(b.visit_date) ||
        (a.suggested_time || '99:99').localeCompare(b.suggested_time || '99:99'),
    );
  const unscheduled = activeDay === 'all' ? places.filter((p) => !p.visit_date) : [];
  const refresh = () => {
    client.invalidateQueries({ queryKey: gpKeys.places(groupId) });
    client.invalidateQueries({ queryKey: gpKeys.activities(groupId) });
  };
  const save = async (event) => {
    event.preventDefault();
    if (saving) return;
    setSaving(true);
    setFormError('');
    try {
      await groupPlannerApi.updatePlace(groupId, editing.id, {
        visit_date: editing.visit_date || '',
        suggested_time: editing.suggested_time || '',
        remarks: editing.remarks || '',
        suggested_duration: editing.suggested_duration || '',
      });
      refresh();
      setEditing(null);
      showToast('Stop updated');
    } catch (e) {
      setFormError(e.message || 'Unable to update this stop.');
    } finally {
      setSaving(false);
    }
  };
  const remove = async () => {
    if (saving) return;
    setSaving(true);
    try {
      await groupPlannerApi.deletePlace(groupId, removing.id);
      refresh();
      setRemoving(null);
      showToast('Stop removed');
    } catch (e) {
      showToast(e.message || 'Unable to remove stop', 'error');
    } finally {
      setSaving(false);
    }
  };
  const move = async (place, dir) => {
    if (saving) return;
    const day = places
      .filter((p) => p.visit_date === place.visit_date)
      .sort((a, b) => (a.suggested_time || '99:99').localeCompare(b.suggested_time || '99:99'));
    const i = day.findIndex((p) => p.id === place.id),
      j = i + dir;
    if (j < 0 || j >= day.length) return;
    setSaving(true);
    try {
      const times = stopTimeSlots(day);
      const ordered = [...day];
      [ordered[i], ordered[j]] = [ordered[j], ordered[i]];
      for (let k = 0; k < ordered.length; k++)
        if (ordered[k].suggested_time !== times[k])
          await groupPlannerApi.updatePlace(groupId, ordered[k].id, { suggested_time: times[k] });
      showToast('Stop order updated');
    } catch (e) {
      showToast(
        e.message || 'Some times could not be updated. Review the refreshed schedule.',
        'error',
      );
    } finally {
      refresh();
      setSaving(false);
    }
  };
  const time = (value) =>
    value
      ? new Date('2000-01-01T' + value.slice(0, 5)).toLocaleTimeString('en-US', {
          hour: 'numeric',
          minute: '2-digit',
        })
      : 'Any time';
  const card = (place, index, list) => (
    <React.Fragment key={place.id}>
      {activeDay === 'all' &&
        place.visit_date &&
        (index === 0 || list[index - 1].visit_date !== place.visit_date) && (
          <div className="gp-day-divider">
            Day {tripDayNumber(place.visit_date, group?.start_date, dates)}
            <span>{formatDate(place.visit_date)}</span>
          </div>
        )}
      <article className={'gp-stop-row' + (selectedPlaceId === place.id ? ' is-selected' : '')}>
        <div className="gp-stop-time">
          {place.visit_date ? time(place.suggested_time) : <Calendar size={15} />}
          <span>{place.suggested_duration ? `${place.suggested_duration} min` : ''}</span>
        </div>
        <div className="gp-stop-card">
          <button
            className="gp-stop-select"
            onClick={() => onSelectPlace?.(place.id)}
            aria-label={`Show ${place.name} on map`}
          >
            <span>
              <h3>{place.name}</h3>
            </span>
          </button>
          {(place.remarks || place.description) && <p>{place.remarks || place.description}</p>}
          <div className="gp-stop-footer">
            <button onClick={() => onSelectPlace?.(place.id)}>
              <MapPin size={12} />
              On map
            </button>
            {canEdit && (
              <>
                <button
                  disabled={saving}
                  onClick={() => {
                    setEditing({
                      ...place,
                      suggested_time: place.suggested_time?.slice(0, 5) || '',
                    });
                    setFormError('');
                  }}
                  aria-label={`Edit ${place.name}`}
                >
                  <Pencil size={12} />
                  {place.visit_date ? 'Edit' : 'Schedule'}
                </button>
                {place.visit_date && (
                  <>
                    <button
                      disabled={
                        saving || index === 0 || list[index - 1]?.visit_date !== place.visit_date
                      }
                      onClick={() => move(place, -1)}
                      aria-label={`Move ${place.name} up`}
                    >
                      <ArrowUp size={13} />
                    </button>
                    <button
                      disabled={
                        saving ||
                        index === list.length - 1 ||
                        list[index + 1]?.visit_date !== place.visit_date
                      }
                      onClick={() => move(place, 1)}
                      aria-label={`Move ${place.name} down`}
                    >
                      <ArrowDown size={13} />
                    </button>
                  </>
                )}
                <button onClick={() => setRemoving(place)} aria-label={`Remove ${place.name}`}>
                  <Trash2 size={12} />
                </button>
              </>
            )}
          </div>
        </div>
      </article>
      {index < list.length - 1 &&
        place.visit_date === list[index + 1].visit_date &&
        distanceKm(place, list[index + 1]) != null && (
          <div className="gp-transit-connector">
            <span />
            {distanceKm(place, list[index + 1]).toFixed(1)} km to next stop
          </div>
        )}
    </React.Fragment>
  );
  return (
    <div className="gp-view gp-itinerary-view">
      <div className="gp-itinerary-intro">
        <div>
          <span className="gp-eyebrow">YOUR DAILY ADVENTURE</span>
          <h1 className="gp-itinerary-title">
            {group?.destination?.split(',')[0] || 'Your itinerary'}
          </h1>
          <p>
            {formatDateRange(group?.start_date, group?.end_date) ||
              'Set your dates in Group Settings'}
          </p>
        </div>
        <span className="gp-stop-total">
          <MapPin size={13} />
          {places.length} stops
        </span>
      </div>
      <div className="gp-day-selector">
        <div className="gp-day-tabs">
          <button
            className={'gp-day-tab' + (activeDay === 'all' ? ' active' : '')}
            onClick={() => setDay('all')}
          >
            Full Agenda
          </button>
          {dates.map((date) => {
            const day = String(tripDayNumber(date, group?.start_date, dates));
            return (
              <button
                key={date}
                className={'gp-day-tab' + (activeDay === day ? ' active' : '')}
                aria-label={'Day ' + day.padStart(2, '0')}
                onClick={() => setDay(day)}
              >
                Day {day}
                <small>
                  {new Date(date + 'T12:00:00').toLocaleDateString('en-US', {
                    month: 'short',
                    day: 'numeric',
                  })}
                </small>
              </button>
            );
          })}
        </div>
        {canEdit && onAddStop && (
          <button className="gp-add-stop" onClick={onAddStop}>
            <Plus size={14} />
            Add Stop
          </button>
        )}
      </div>
      <div className="gp-day-summary">
        <h2>
          {activeDay === 'all'
            ? 'The whole adventure'
            : `Day ${activeDay} in ${group?.destination?.split(',')[0] || 'your destination'}`}
        </h2>
        <span>{visible.length} stops</span>
      </div>
      {isLoading ? (
        <p role="status">Loading itinerary...</p>
      ) : error ? (
        <p role="alert">{error.message}</p>
      ) : (
        <>
          <div className="gp-stop-timeline">{visible.map((p, i) => card(p, i, visible))}</div>
          {unscheduled.length > 0 && (
            <>
              <div className="gp-day-divider">
                Unscheduled<span>Pick a date when you are ready</span>
              </div>
              {unscheduled.map((p, i) => card(p, i, unscheduled))}
            </>
          )}
          {visible.length === 0 && unscheduled.length === 0 && (
            <div className="gp-empty-agenda">
              <Calendar size={28} />
              <h3>A little room for adventure</h3>
              <p>No stops scheduled {activeDay === 'all' ? 'yet' : 'for this day'}.</p>
              {onOpenLibrary && (
                <button className="gp-open-workspace" onClick={onOpenLibrary}>
                  Find places in the Library
                </button>
              )}
            </div>
          )}
        </>
      )}
      {editing && (
        <div className="gp-modal-overlay" onClick={() => !saving && setEditing(null)}>
          <form
            className="gp-modal"
            role="dialog"
            aria-modal="true"
            aria-label="Edit Stop"
            onClick={(e) => e.stopPropagation()}
            onSubmit={save}
          >
            <h2 className="gp-modal-title">Edit Stop</h2>
            <p className="gp-form-hint">{editing.name}</p>
            {[
              ['visit_date', 'Date', 'date'],
              ['suggested_time', 'Time', 'time'],
              ['suggested_duration', 'Duration in minutes', 'number'],
            ].map(([key, label, type]) => (
              <label className="gp-field" key={key}>
                {label}
                {key === 'visit_date' ? <TripDateSelect group={group} className="gp-modal-input" value={editing[key] || ''} onChange={e => setEditing({...editing, [key]: e.target.value})}/> : <input
                  type={type}
                  className="gp-modal-input"
                  value={editing[key] || ''}
                  min={type === 'number' ? 1 : undefined}
                  onChange={(e) => setEditing({ ...editing, [key]: e.target.value })}
                />}
              </label>
            ))}
            <label className="gp-field">
              Notes
              <textarea
                className="gp-modal-input"
                value={editing.remarks || ''}
                onChange={(e) => setEditing({ ...editing, remarks: e.target.value })}
              />
            </label>
            {formError && <p role="alert">{formError}</p>}
            <div className="gp-modal-actions">
              <button className="gp-modal-btn-primary" disabled={saving}>
                Save Changes
              </button>
              <button
                className="gp-modal-btn-secondary"
                type="button"
                disabled={saving}
                onClick={() => setEditing(null)}
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}
      {removing && (
        <div className="gp-modal-overlay">
          <div className="gp-modal" role="dialog" aria-modal="true" aria-label="Remove Stop">
            <h2 className="gp-modal-title">Remove Stop</h2>
            <p>Remove {removing.name} from this trip?</p>
            <div className="gp-modal-actions">
              <button className="gp-modal-btn-primary" disabled={saving} onClick={remove}>
                Remove
              </button>
              <button
                className="gp-modal-btn-secondary"
                disabled={saving}
                onClick={() => setRemoving(null)}
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
