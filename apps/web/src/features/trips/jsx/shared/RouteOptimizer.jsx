// Purpose: Previews a reordered itinerary using local route helpers and saves the selected day's updated stop schedule through the planner API.
import React, { useMemo, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { WandSparkles, X } from 'lucide-react';
import groupPlannerApi from '../../../../services/groupPlannerApi';
import { gpKeys } from '../../../../hooks/useGroupPlannerQuery';
import { tripDayNumber } from '../../utils/groupPlannerUtils';
import { optimizeStops, routeDistance, stopTimeSlots } from '../../utils/plannerSchedule';
import { validCoordinates } from '../../../../utils/coordinates';
export default function RouteOptimizer({ groupId, group, places, activeDay, showToast, canEdit }) {
  const client = useQueryClient(),
    [open, setOpen] = useState(false),
    [saving, setSaving] = useState(false);
  const dates = [
    ...new Set(places.filter((p) => p.visit_date && !p.is_deleted).map((p) => p.visit_date)),
  ].sort();
  const date =
    dates.find((d) => String(tripDayNumber(d, group.start_date, dates)) === activeDay) || dates[0];
  const current = useMemo(
    () =>
      places
        .filter((p) => p.visit_date === date && !p.is_deleted)
        .sort((a, b) => (a.suggested_time || '99:99').localeCompare(b.suggested_time || '99:99')),
    [places, date],
  );
  const proposed = useMemo(() => optimizeStops(current), [current]);
  const ready =
    current.length >= 3 && current.every((p) => validCoordinates(p.latitude, p.longitude));
  const changed = proposed.some((p, i) => p.id !== current[i]?.id);
  const apply = async () => {
    if (saving) return;
    setSaving(true);
    try {
      const times = stopTimeSlots(current);
      for (let i = 0; i < proposed.length; i++)
        await groupPlannerApi.updatePlace(groupId, proposed[i].id, { suggested_time: times[i] });
      showToast('Route order saved');
      setOpen(false);
    } catch (e) {
      showToast(
        e.message || 'Some stops could not be updated. Review the refreshed schedule.',
        'error',
      );
      setOpen(false);
    } finally {
      client.invalidateQueries({ queryKey: gpKeys.places(groupId) });
      client.invalidateQueries({ queryKey: gpKeys.activities(groupId) });
      setSaving(false);
    }
  };
  return (
    <>
      <button className="gp-map-optimize gp-icon-button" onClick={() => setOpen(true)}>
        <WandSparkles size={15} />
        <span>Optimize Route</span>
      </button>
      {open && (
        <div className="gp-modal-overlay" onClick={() => !saving && setOpen(false)}>
          <div
            className="gp-modal"
            role="dialog"
            aria-modal="true"
            aria-label="Optimize Route"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="gp-section-header">
              <h2 className="gp-modal-title">
                Optimize Day {date ? tripDayNumber(date, group.start_date, dates) : ''}
              </h2>
              <button
                className="gp-icon-button"
                disabled={saving}
                onClick={() => setOpen(false)}
                aria-label="Close route optimizer"
              >
                <X size={16} />
              </button>
            </div>
            {!ready ? (
              <p className="gp-form-hint">
                Add at least three stops with map coordinates to preview a shorter route.
              </p>
            ) : (
              <>
                <p className="gp-form-hint">
                  Keep the first stop and your day's time slots. Preview a shorter path between map
                  pins before applying it. Road distances and travel times can differ.
                </p>
                <div className="gp-route-comparison">
                  <div>
                    <span>Current route</span>
                    <strong>{routeDistance(current).toFixed(1)} km</strong>
                  </div>
                  <div>
                    <span>Suggested route</span>
                    <strong>{routeDistance(proposed).toFixed(1)} km</strong>
                  </div>
                </div>
                <ol className="gp-route-list">
                  {proposed.map((p) => (
                    <li key={p.id}>{p.name}</li>
                  ))}
                </ol>
                {!changed && (
                  <p className="gp-form-hint">
                    Your current order already follows the shortest suggested path.
                  </p>
                )}
                <button
                  className="gp-modal-btn-primary"
                  disabled={!canEdit || !changed || saving}
                  onClick={apply}
                >
                  {saving ? 'Saving...' : 'Apply Order'}
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </>
  );
}
