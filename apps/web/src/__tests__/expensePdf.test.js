/** @jest-environment node */
// Purpose: Verify statement cash-flow semantics, source receipts and real multi-page PDF generation.
import autoTable from 'jspdf-autotable';
import {buildExpensePDF} from '../services/pdfExportService';

jest.mock('jspdf-autotable', () => ({__esModule: true,
  default: jest.fn((...args) => jest.requireActual('jspdf-autotable').default(...args))}));
beforeEach(() => jest.clearAllMocks());
const section = heading => autoTable.mock.calls.map(([, options]) => options).find(options => options.head[0].includes(heading));

it('separates income, refunds and spending, preserving calendar dates and source money', () => {
  const doc = buildExpensePDF({mode: 'personal', currency: 'USD', expenses: [
    {id: 'a', income_date: '2026-10-01', amount: 1000, type: 'income', description: 'Salary'},
    {id: 'b', expense_date: '2026-10-02', amount: 10.53, description: 'Dinner', original_currency: 'INR', original_amount: 1000},
    {id: 'c', expense_date: '2026-10-03', amount: -2, description: 'Refund'},
    {id: 'd', expense_date: '2026-10-03', amount: 999, is_deleted: true},
  ]});
  const activity = section('Money out');
  expect(activity.body[0]).toEqual(['01 Oct 2026', expect.stringContaining('Income'), '-', 'USD 1,000.00', 'USD 1,000.00']);
  expect(activity.body[1]).toEqual(['02 Oct 2026', expect.stringContaining('Original: INR 1,000.00'), 'USD 10.53', '-', 'USD 989.47']);
  expect(activity.foot).toEqual([['Totals', '', 'USD 8.53', 'USD 1,000.00', 'USD 991.47']]);
  expect(activity.body).toHaveLength(3);
  expect(doc.output('arraybuffer').byteLength).toBeGreaterThan(1000);
});

it('uses saved settlement names and dates and keeps one-cent balances visible', () => {
  buildExpensePDF({mode: 'group', currency: 'USD', members: [],
    balances: [{user_name: 'Old member', balance: -.01}],
    settlements: [{settlement_date: '2026-10-01', created_at: '2026-10-26', from_user_name: 'Alice', to_user_name: 'Bob', amount: 10},
      {settlement_date: '2026-10-02', amount: 999, is_deleted: true}]});
  expect(section('From').body).toEqual([['01 Oct 2026', 'Alice', 'Bob', 'USD 10.00']]);
  expect(section('Gets back').body).toEqual([['Old member', '-', 'USD 0.01']]);
});

it('generates real pages for long references and large values with headers and reserved footers', () => {
  const doc = buildExpensePDF({mode: 'group', currency: 'INR', expenses: Array.from({length: 30}, (_, i) => ({
    id: String(i), expense_date: '2026-10-26', description: 'Very long merchant reference and full description '.repeat(10), amount: 9999999999.99,
  }))});
  expect(doc.getNumberOfPages()).toBeGreaterThan(2);
  const activity = section('Paid by');
  expect(activity.body[0][3]).toBe('INR 9,999,999,999.99');
  expect(activity.body[0][1]).toContain('Very long merchant reference and full description '.repeat(10));
  expect(activity.showHead).toBe('everyPage');
  expect(activity.rowPageBreak).toBe('avoid');
  expect(activity.styles.overflow).toBe('linebreak');
  expect(activity.margin.bottom).toBe(20);
  const commands = doc.internal.pages.flat().join('\n');
  for (let page = 1; page <= doc.getNumberOfPages(); page++) expect(commands).toContain(`Page ${page} of ${doc.getNumberOfPages()}`);
});
