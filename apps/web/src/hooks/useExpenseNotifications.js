// Purpose: Loads a private, paginated expense inbox with single and scoped bulk acknowledgements.
import {useMutation, useQuery, useQueryClient} from '@tanstack/react-query';
import expenseApi from '../services/expenseApi';

const unwrap = response => response?.data ?? response;

export default function useExpenseNotifications(userId, {groupId = null, unreadOnly = false, offset = 0} = {}) {
  const client = useQueryClient();
  const query = useQuery({
    queryKey: ['expense-notifications', userId, groupId, unreadOnly, offset],
    queryFn: async () => unwrap(await expenseApi.getNotifications({limit: 30, offset,
      ...(groupId && {group_id: groupId}), ...(unreadOnly && {unread_only: true})})),
    enabled: Boolean(userId), staleTime: 10_000, retry: false,
    refetchOnWindowFocus: true,
    // Reconcile other devices even when a socket notification was missed.
    refetchInterval: 60_000, refetchIntervalInBackground: false,
  });
  const read = useMutation({
    mutationFn: ids => expenseApi.readNotifications(ids),
    onSuccess: async () => {
      await client.invalidateQueries({queryKey: ['expense-notifications', userId]});
    },
  });
  const readAll = useMutation({
    mutationFn: () => expenseApi.readAllNotifications(groupId),
    onSuccess: async () => {
      await client.invalidateQueries({queryKey: ['expense-notifications', userId]});
    },
  });
  return {...query, read, readAll};
}
