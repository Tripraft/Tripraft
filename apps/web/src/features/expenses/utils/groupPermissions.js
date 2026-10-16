const sameId = (left, right) => left != null && right != null && String(left) === String(right);

export function groupPermissions(group, userId) {
  if (!group || !userId) return {};
  const owner = sameId(group.created_by, userId);
  const admin = owner || group.my_role === 'admin';
  const contribute = group.my_role !== 'viewer';
  return {
    can_invite: contribute, can_add_expense: contribute,
    can_update_group: admin, can_add_members: admin,
    can_manage_roles: owner, can_remove_members: owner, can_delete_group: owner,
    can_leave_group: !owner, can_record_any_settlement: admin,
    can_recalculate_balances: admin,
    ...group.permissions,
  };
}

export function expensePermissions(expense, group, userId, mode = 'group') {
  if (mode === 'group' && group?.my_role === 'viewer') return {can_edit: false, can_delete: false, can_restore: false};
  if (!userId) return { can_edit: false, can_delete: false, can_restore: false };
  if (expense.is_deleted) {
    const own = sameId(expense.created_by, userId) || (mode === 'group' && sameId(group?.created_by, userId));
    return { can_edit: false, can_delete: false, can_restore: expense.permissions?.can_restore ?? own };
  }
  if (mode !== 'group') return { can_edit: true, can_delete: true };
  const own = Boolean(userId) && (sameId(group?.created_by, userId) || sameId(expense.created_by, userId));
  return { can_edit: own, can_delete: own, ...expense.permissions };
}

export function canRecordSettlement(group, userId, from, to) {
  if (group?.my_role === 'viewer') return false;
  return Boolean(userId) && (groupPermissions(group, userId).can_record_any_settlement ||
    sameId(from, userId) || sameId(to, userId));
}

export function canDeleteSettlement(settlement, group, userId) {
  if (group?.my_role === 'viewer') return false;
  if (!userId || settlement.is_deleted) return false;
  return settlement.permissions?.can_delete ?? Boolean(
    groupPermissions(group, userId).can_record_any_settlement ||
    sameId(settlement.from_user_id, userId) || sameId(settlement.to_user_id, userId) ||
    sameId(settlement.recorded_by, userId));
}
