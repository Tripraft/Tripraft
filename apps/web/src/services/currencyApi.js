// Purpose: Fetches supported currencies with short-lived listing reuse and requests current or explicitly refreshed exchange rates.
import apiClient from '../utils/apiClient';

let listing;
let expires = 0;
export async function getCurrencies() {
  if (!listing || Date.now() >= expires) {
    expires = Date.now() + 5 * 60 * 1000;
    listing = apiClient.get('/v1/currencies').then(response => response.data).catch(error => {
      listing = null;
      throw error;
    });
  }
  return listing;
}
export async function getExchangeRate(base, quote, refresh = false) {
  const params = new URLSearchParams({base, quote});
  if (refresh) params.set('refresh', '1');
  const response = await apiClient.get(`/v1/exchange-rates?${params}`);
  return response.data;
}
