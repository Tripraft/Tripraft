// Purpose: Defines planner query keys and hooks for groups, destination viewports, places, polls, members, expenses, checklists, vault files and activities.
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import groupPlannerApi from '../services/groupPlannerApi';

// Use the saved server object immediately; reconciliation can run in the background.
export function upsertPlannerItem(previous, item, field) {
  if (!item?.id) return previous;
  const items = Array.isArray(previous?.data) ? previous.data : previous?.data?.[field] || [];
  const exists = items.some(entry => String(entry.id) === String(item.id));
  const next = exists
    ? items.map(entry => String(entry.id) === String(item.id) ? item : entry)
    : field === 'checklist' ? [...items, item] : [item, ...items];
  return {
    ...previous,
    data: previous?.data && !Array.isArray(previous.data)
      ? { ...previous.data, [field]: next }
      : next,
  };
}

// Cache key factory — consistent keys for invalidation
export const gpKeys = {
  all:       ['group-planner'],
  groups:    () => [...gpKeys.all, 'groups'],
  group:     (id) => [...gpKeys.all, 'group', id],
  places:    (groupId) => [...gpKeys.all, 'places', groupId],
  polls:     (groupId) => [...gpKeys.all, 'polls', groupId],
  checklist: (groupId) => [...gpKeys.all, 'checklist', groupId],
  members:   (groupId) => [...gpKeys.all, 'members', groupId],
  expenses:  (groupId) => [...gpKeys.all, 'expenses', groupId],
  vault:     (groupId) => [...gpKeys.all, 'vault', groupId],
  activities:(groupId) => [...gpKeys.all, 'activities', groupId],
};

// ── Query Hooks ─────────────────────────────────────────────────────────────

export function useGroups() {
  return useQuery({
    queryKey: gpKeys.groups(),
    queryFn: () => groupPlannerApi.getUserGroups(),
    staleTime: 30_000,
  });
}

export function useDestinationViewport(group) {
  const scope = { destination: group?.destination || '', destination_type: group?.destination_type || '', destination_id: group?.destination_id || '' };
  return useQuery({
    queryKey: [...gpKeys.all, 'destination-viewport', scope],
    queryFn: () => groupPlannerApi.getDestinationViewport(scope),
    enabled: !!(scope.destination_id || scope.destination),
    staleTime: 6 * 60 * 60 * 1000,
  });
}

export function useGroupDetail(groupId) {
  return useQuery({
    queryKey: gpKeys.group(groupId),
    queryFn: () => groupPlannerApi.getGroup(groupId),
    enabled: !!groupId,
    staleTime: 15_000,
  });
}

export function useGroupPlaces(groupId) {
  return useQuery({
    queryKey: gpKeys.places(groupId),
    queryFn: () => groupPlannerApi.getGroupPlaces(groupId),
    enabled: !!groupId,
    staleTime: 30_000,
  });
}

export function useGroupPolls(groupId) {
  return useQuery({
    queryKey: gpKeys.polls(groupId),
    queryFn: () => groupPlannerApi.getGroupPolls(groupId),
    enabled: !!groupId,
    staleTime: 30_000,
  });
}

export function useGroupMembers(groupId) {
  return useQuery({
    queryKey: gpKeys.members(groupId),
    queryFn: () => groupPlannerApi.getGroupMembers(groupId),
    enabled: !!groupId,
    staleTime: 30_000,
  });
}

export function useExpenseSummary(groupId) {
  return useQuery({
    queryKey: gpKeys.expenses(groupId),
    queryFn: () => groupPlannerApi.getExpenseSummary(groupId),
    enabled: !!groupId,
    staleTime: 60_000,
  });
}

// ── Mutation Hooks ──────────────────────────────────────────────────────────

export function useAddPlace(groupId) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (placeData) => groupPlannerApi.addPlace(groupId, placeData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: gpKeys.places(groupId) });
    },
  });
}

export function useCreatePoll(groupId) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (pollData) => groupPlannerApi.createPoll(groupId, pollData),
    onSuccess: (response) => {
      queryClient.setQueryData(gpKeys.polls(groupId), old => upsertPlannerItem(old, response.data, 'polls'));
      queryClient.invalidateQueries({ queryKey: gpKeys.polls(groupId) });
    },
  });
}

export function useToggleChecklistItem(groupId) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (itemId) => groupPlannerApi.toggleChecklistItem(groupId, itemId),
    onMutate: async (itemId) => {
      await queryClient.cancelQueries({ queryKey: gpKeys.checklist(groupId) });
      const previous = queryClient.getQueryData(gpKeys.checklist(groupId));
      queryClient.setQueryData(gpKeys.checklist(groupId), (old) => {
        const items = Array.isArray(old?.data) ? old.data : old?.data?.checklist;
        if (!Array.isArray(items)) return old;
        const updated = items.map(item => item.id === itemId ? {...item, completed: !item.completed} : item);
        return {
          ...old,
          data: Array.isArray(old.data) ? updated : {...old.data, checklist: updated},
        };
      });
      return { previous };
    },
    onError: (_err, _itemId, context) => {
      if (context) queryClient.setQueryData(gpKeys.checklist(groupId), context.previous);
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: gpKeys.checklist(groupId) });
    },
  });
}

export function useCreateGroup() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (groupData) => groupPlannerApi.createGroup(groupData),
    onSuccess: (response) => {
      if (response.data?.id) queryClient.setQueryData(gpKeys.group(response.data.id), response);
      queryClient.setQueryData(gpKeys.groups(), old => upsertPlannerItem(old, response.data, 'groups'));
      queryClient.invalidateQueries({ queryKey: gpKeys.groups() });
    },
  });
}

export function useDeleteGroup() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (groupId) => groupPlannerApi.deleteGroup(groupId),
    onSuccess: (_data, groupId) => {
      queryClient.invalidateQueries({ queryKey: gpKeys.groups() });
      queryClient.removeQueries({ queryKey: gpKeys.group(groupId) });
    },
  });
}

// ── Checklist Query ─────────────────────────────────────────────────────────

export function useGroupChecklist(groupId) {
  return useQuery({
    queryKey: gpKeys.checklist(groupId),
    queryFn: () => groupPlannerApi.getGroupChecklist(groupId),
    enabled: !!groupId,
    staleTime: 10_000,
  });
}

// ── Vault Query ─────────────────────────────────────────────────────────────

export function useVaultFiles(groupId) {
  return useQuery({
    queryKey: gpKeys.vault(groupId),
    queryFn: () => groupPlannerApi.getVaultFiles(groupId),
    enabled: !!groupId,
    staleTime: 30_000,
  });
}

export function useUploadVaultFile(groupId) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (file) => groupPlannerApi.uploadVaultFile(groupId, file),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: gpKeys.vault(groupId) });
    },
  });
}

export function useDeleteVaultFile(groupId) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (docId) => groupPlannerApi.deleteVaultFile(groupId, docId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: gpKeys.vault(groupId) });
    },
  });
}

// ── Activities Query ────────────────────────────────────────────────────────

export function useGroupActivities(groupId) {
  return useQuery({
    queryKey: gpKeys.activities(groupId),
    queryFn: () => groupPlannerApi.getGroupActivities(groupId),
    enabled: !!groupId,
    staleTime: 15_000,
  });
}
