// Purpose: Converts human-readable supplier proposals into exact decimal-string minor amounts without float rounding.
export function displayAmount(minor: string, exponent: number): string {
  if (!minor) return '';
  if (!exponent) return minor;
  const padded = minor.padStart(exponent + 1, '0');
  return `${padded.slice(0, -exponent)}.${padded.slice(-exponent)}`;
}
export function minorAmount(value: string, exponent: number): string {
  const input = value.trim();
  if (!input) return '';
  if (!Number.isInteger(exponent) || exponent < 0 || exponent > 4) throw new Error('Choose the currency decimal places.');
  const pattern = exponent ? new RegExp(`^\\d+(?:\\.\\d{0,${exponent}})?$`) : /^\d+$/;
  if (!pattern.test(input)) throw new Error(`Enter a positive amount with up to ${exponent} decimal places.`);
  const [whole, decimal = ''] = input.split('.');
  const minor = BigInt(whole + decimal.padEnd(exponent, '0')).toString();
  if (minor === '0' || minor.length > 12) throw new Error('Enter a positive amount within the supported range.');
  return minor;
}
