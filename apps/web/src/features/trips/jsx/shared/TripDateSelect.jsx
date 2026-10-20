// Purpose: Offers the trip's calendar dates plus an unscheduled option for assigning a stop to a day.
import React from 'react';
import {tripDates} from '../../utils/plannerSchedule';
import {formatDate} from '../../utils/formatters';

export default function TripDateSelect({group, value, onChange, ...props}) {
  const dates = group?.start_date ? tripDates(group) : [];
  return <select {...props} value={value || ''} onChange={onChange}>
    <option value="">Unscheduled</option>
    {dates.map((date, index) => <option key={date} value={date}>Day {index + 1} · {formatDate(date)}</option>)}
  </select>;
}
