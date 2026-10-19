// Purpose: Guards decimal conversion for private proposals against floating-point rounding and precision loss.
import { displayAmount, minorAmount } from '../rateAmounts';

test.each([['15500.01', 2, '1550001'], ['0.01', 2, '1'], ['123', 0, '123'], ['12.345', 3, '12345'], ['', 2, '']])('converts %s with exponent %s', (amount, exponent, expected) => {
  expect(minorAmount(String(amount), Number(exponent))).toBe(expected);
});
test.each(['0', '-1', 'NaN', '1e5', '1.234', '999999999999999'])('rejects invalid amount %s', value => {
  expect(() => minorAmount(value, 2)).toThrow();
});
test('round-trips leading fractional zeros without number conversion', () => {
  expect(displayAmount('1', 3)).toBe('0.001');
  expect(minorAmount(displayAmount('999999999999', 2), 2)).toBe('999999999999');
});
