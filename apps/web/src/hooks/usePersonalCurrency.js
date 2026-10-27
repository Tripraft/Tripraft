// Purpose: Loads and saves the user's explicit dashboard currency choice on their account.
import {useEffect, useRef, useState} from 'react';
import expenseApi from '../services/expenseApi';

const unwrap = response => response?.data || response;

export default function usePersonalCurrency(userId, enabled = true) {
  const [state, setState] = useState({});
  const [reload, setReload] = useState(0);
  const generation = useRef(0);
  const saving = useRef(false);
  useEffect(() => {
    const request = ++generation.current;
    saving.current = false;
    if (!enabled || !userId) return;
    setState({userId, loading: true});
    expenseApi.getUser().then(response => {
      const user = unwrap(response)?.user;
      if (response?.success === false || !user) throw new Error('Unable to load your currency preference.');
      if (generation.current === request) setState({userId, currency: user.personal_display_currency || '', loading: false});
    }).catch(error => {
      if (generation.current === request) setState({userId, loading: false, loadError: error.message});
    });
    return () => { generation.current++; };
  }, [userId, enabled, reload]);

  const choose = async currency => {
    if (!userId || !enabled || saving.current || !currency) return;
    const request = generation.current;
    saving.current = true;
    setState(previous => ({...previous, saving: true, saveError: ''}));
    try {
      const response = await expenseApi.updateUser({personal_display_currency: currency});
      if (response?.success === false || unwrap(response)?.user?.personal_display_currency !== currency) {
        throw new Error('Your currency preference could not be saved. Please try again.');
      }
      if (generation.current === request) setState({userId, currency, loading: false});
    } catch (error) {
      if (generation.current === request) setState(previous => ({...previous, saving: false, saveError: error.message || 'Unable to save your currency preference.'}));
    } finally { if (generation.current === request) saving.current = false; }
  };

  return {...(state.userId === userId ? state : {loading: true}), choose, retry: () => setReload(value => value + 1)};
}
