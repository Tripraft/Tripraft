// Purpose: Canonical browser links never include an account identifier.
export function expensePath(mode = 'personal', groupId) {
  return mode === 'group' && groupId
    ? `/groups/${encodeURIComponent(groupId)}/expenses`
    : `/expenses/${mode === 'group' ? 'group' : 'personal'}`;
}
