// Purpose: Defines local currency metadata used as a fallback when the supported-currency API is unavailable.
export const currencies = {
  USD: { code: 'USD', symbol: '$', name: 'US Dollar' },
  EUR: { code: 'EUR', symbol: '\u20ac', name: 'Euro' },
  INR: { code: 'INR', symbol: '\u20b9', name: 'Indian Rupee' },
  GBP: { code: 'GBP', symbol: '\u00a3', name: 'British Pound' },
  JPY: { code: 'JPY', symbol: '\u00a5', name: 'Japanese Yen' },
  CAD: { code: 'CAD', symbol: 'C$', name: 'Canadian Dollar' },
  AUD: { code: 'AUD', symbol: 'A$', name: 'Australian Dollar' },
  CHF: { code: 'CHF', symbol: 'CHF', name: 'Swiss Franc' },
  CNY: { code: 'CNY', symbol: '\u00a5', name: 'Chinese Yuan' },
  KRW: { code: 'KRW', symbol: '\u20a9', name: 'South Korean Won' },
  BRL: { code: 'BRL', symbol: 'R$', name: 'Brazilian Real' },
  MXN: { code: 'MXN', symbol: 'Mex$', name: 'Mexican Peso' },
  SGD: { code: 'SGD', symbol: 'S$', name: 'Singapore Dollar' },
  HKD: { code: 'HKD', symbol: 'HK$', name: 'Hong Kong Dollar' },
  NZD: { code: 'NZD', symbol: 'NZ$', name: 'New Zealand Dollar' }
};
