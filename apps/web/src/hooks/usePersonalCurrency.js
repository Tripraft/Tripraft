// Purpose: Caches the account's chosen dashboard currency across tabs and saves explicit changes.
import {useRef} from 'react';
import {useMutation, useQuery, useQueryClient} from '@tanstack/react-query';
import expenseApi from '../services/expenseApi';

const unwrap = response => response?.data || response;
const preferenceKey = userId => ['user', 'personal-currency', userId];

export default function usePersonalCurrency(userId, enabled = true) {
  const client = useQueryClient();
  const saving = useRef(false);
  const query = useQuery({
    queryKey: preferenceKey(userId),
    queryFn: async () => {
      const response = await expenseApi.getUser();
      const user = unwrap(response)?.user;
      if (response?.success === false || !user) throw new Error('Unable to load your currency preference.');
      return user.personal_display_currency || '';
    },
    enabled: enabled && Boolean(userId),
    staleTime: Infinity, gcTime: Infinity, retry: false,
    refetchOnWindowFocus: false, refetchOnMount: false, refetchOnReconnect: false,
  });
  const mutation = useMutation({
    mutationFn: async ({currency}) => {
      const response = await expenseApi.updateUser({personal_display_currency: currency});
      if (response?.success === false || unwrap(response)?.user?.personal_display_currency !== currency) {
        throw new Error('Your currency preference could not be saved. Please try again.');
      }
      return currency;
    },
    onSuccess: (currency, account) => client.setQueryData(preferenceKey(account.userId), currency),
  });
  const choose = async currency => {
    if (!enabled || !userId || !currency || currency === query.data || saving.current) return;
    saving.current = true;
    try { await mutation.mutateAsync({currency, userId}); }
    catch { /* Keep the saved choice and expose the save error below. */ }
    finally { saving.current = false; }
  };
  const currentMutation = mutation.variables?.userId === userId;
  return {
    currency: query.data || '', loading: enabled && query.isPending,
    loadError: query.data === undefined ? query.error?.message : '',
    saving: currentMutation && mutation.isPending,
    targetCurrency: currentMutation && mutation.isPending ? mutation.variables.currency : query.data || '',
    saveError: currentMutation ? mutation.error?.message : '',
    choose, retry: query.refetch,
  };
}
