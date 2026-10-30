// Purpose: Canonical browser links never include an account identifier.
export function expensePath(mode = 'personal', groupId) {
  return mode === 'group' && groupId
    ? `/groups/${encodeURIComponent(groupId)}/expenses`
    : mode === 'group' ? '/groups' : '/expenses/personal';
}

export function plannerGroupPath(groupId) {
  return `/groups/${encodeURIComponent(groupId)}/planner`;
}
