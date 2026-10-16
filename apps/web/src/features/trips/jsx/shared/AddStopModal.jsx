import React, { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { X } from 'lucide-react';
import groupPlannerApi from '../../../../services/groupPlannerApi';
import { gpKeys } from '../../../../hooks/useGroupPlannerQuery';
import { unwrap } from '../../utils/groupPlannerUtils';
import TripDateSelect from './TripDateSelect';

export default function AddStopModal({ groupId, group, initialDate, onClose, showToast }) {
  const client = useQueryClient();
  const [name, setName] = useState('');
  const [date, setDate] = useState(initialDate || '');
  const [time, setTime] = useState('');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const submit = async (event) => {
    event.preventDefault();
    if (saving || !name.trim()) return;
    setSaving(true);
    setError('');
    let created = false;
    try {
      const place = unwrap(
        await groupPlannerApi.addPlace(groupId, {
          name: name.trim(),
          visit_date: date || undefined,
          description: notes.trim(),
        }),
      );
      created = true;
      if (time || notes.trim()) {
        if (!place?.id) throw new Error('Stop saved but its schedule could not be updated.');
        await groupPlannerApi.updatePlace(groupId, place.id, {
          suggested_time: time,
          remarks: notes.trim(),
        });
      }
      showToast('Stop added');
      onClose();
    } catch (err) {
      if (created) {
        showToast('Stop saved. Use Edit to finish setting its time and notes.', 'error');
        onClose();
      } else setError(err.message || 'Unable to add this stop. Please try again.');
    } finally {
      client.invalidateQueries({ queryKey: gpKeys.places(groupId) });
      client.invalidateQueries({ queryKey: gpKeys.activities(groupId) });
      setSaving(false);
    }
  };
  return (
    <div
      className="gp-modal-overlay"
      onClick={() => {
        if (!saving) onClose();
      }}
    >
      <form
        className="gp-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="gp-add-stop-title"
        onSubmit={submit}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="gp-section-header">
          <h2 id="gp-add-stop-title" className="gp-modal-title">
            Add a Stop
          </h2>
          <button
            type="button"
            className="gp-icon-button"
            disabled={saving}
            onClick={onClose}
            aria-label="Close add stop"
          >
            <X size={17} />
          </button>
        </div>
        <label className="gp-modal-label" htmlFor="gp-stop-name">
          Place name
        </label>
        <input
          id="gp-stop-name"
          className="gp-modal-input"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          maxLength={200}
          autoFocus
        />
        <label className="gp-modal-label" htmlFor="gp-stop-date">
          Visit date
        </label>
        <TripDateSelect
          group={group}
          id="gp-stop-date"
          className="gp-modal-input"
          value={date}
          onChange={(e) => setDate(e.target.value)}
        />
        <label className="gp-modal-label" htmlFor="gp-stop-time">
          Time
        </label>
        <input
          id="gp-stop-time"
          type="time"
          className="gp-modal-input"
          value={time}
          onChange={(e) => setTime(e.target.value)}
        />
        <label className="gp-modal-label" htmlFor="gp-stop-notes">
          Notes
        </label>
        <textarea
          id="gp-stop-notes"
          className="gp-modal-input"
          rows={3}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
        />
        <p className="gp-form-hint">
          Leave the date empty to save this stop as unscheduled. Library stops appear on the map when coordinates are available.
        </p>
        {error && <p role="alert">{error}</p>}
        <div className="gp-modal-actions">
          <button type="submit" className="gp-modal-btn-primary" disabled={saving}>
            {saving ? 'Saving…' : 'Add Stop'}
          </button>
          <button
            type="button"
            className="gp-modal-btn-secondary"
            disabled={saving}
            onClick={onClose}
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}
