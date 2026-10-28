// Purpose: Regression tests for planner Time, including success and failure behavior.
import { formatDate, formatCalendarDate, formatTime, formatRelativeTime, parsePlannerInstant } from '../features/trips/utils/formatters';
import { settlePlannerInvitations } from '../features/trips/utils/groupPlannerUtils';

it('interprets old UTC timestamps and explicit offsets as the same instant', () => {
  for (const text of ['2026-10-27T01:30:00', '2026-10-27T01:30:00Z', '2026-10-27T07:00:00+05:30', '2026-10-26T18:30:00-07:00']) {
    expect(parsePlannerInstant(text).toISOString()).toBe('2026-10-27T01:30:00.000Z');
    expect(formatTime(text)).toBe(new Date('2026-10-27T01:30:00Z').toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit', hour12: false}));
    expect(formatDate(text)).toBe(new Date('2026-10-27T01:30:00Z').toLocaleDateString('en-US', {month: 'short', day: 'numeric', year: 'numeric'}));
  }
});

it('preserves calendar dates and handles invalid activity times', () => {
  expect(formatDate('2026-10-27')).toBe('Oct 27, 2026');
  expect(formatCalendarDate('2026-10-27T00:00:00+00:00')).toBe('Oct 27, 2026');
  expect(formatTime('bad')).toBe('');
  expect(formatRelativeTime('bad')).toBe('');
  jest.spyOn(Date, 'now').mockReturnValue(Date.parse('2026-10-27T01:35:00Z'));
  expect(formatRelativeTime('2026-10-27T01:30:00')).toBe('5m ago');
  jest.restoreAllMocks();
});

it('bounds invitation concurrency and retains each failed address for retry', async () => {
  let active = 0, maximum = 0;
  const results = await settlePlannerInvitations(['a', 'b', 'c', 'd', 'e'], async email => {
    maximum = Math.max(maximum, ++active);
    await Promise.resolve();
    active--;
    if (email === 'b') throw new Error('Offline');
    return email;
  });
  expect(maximum).toBe(3);
  expect(results.filter(r => r.status === 'rejected').map(r => r.email)).toEqual(['b']);
  expect(results.filter(r => r.status === 'fulfilled').map(r => r.value)).toEqual(['a', 'c', 'd', 'e']);
});
