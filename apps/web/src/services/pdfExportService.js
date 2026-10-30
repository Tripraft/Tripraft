// Purpose: Builds paginated personal/group statements with wrapped details, exact money columns and repeatable page furniture.
import {jsPDF} from 'jspdf';
import autoTable from 'jspdf-autotable';
import {isPersonalIncome} from '../features/expenses/utils/personalTransactions';
import {expensePayers} from '../features/expenses/utils/payers';

const INK = [23, 37, 58], MUTED = [91, 106, 124], ACCENT = [62, 73, 153];
const numeric = value => Number.isFinite(Number(value)) ? Number(value) : 0;
const money = (amount, currency) => `${currency} ${numeric(amount).toLocaleString('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2})}`;
const day = row => String(row.expense_date || row.income_date || row.settlement_date || row.date || row.created_at || '').slice(0, 10);
const dateLabel = value => {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return '-';
  const parsed = new Date(`${value}T12:00:00Z`);
  return Number.isFinite(parsed.getTime()) ? parsed.toLocaleDateString('en-GB', {day: '2-digit', month: 'short', year: 'numeric', timeZone: 'UTC'}) : '-';
};
const text = value => String(value || '-');
const memberName = (id, members, direct) => direct?.display_name || direct?.email
  || (() => {const row = members.find(member => String(member.user_id || member.id) === String(id));
    return row?.display_name || row?.user?.display_name || row?.email || row?.user?.email;})() || 'Former member';

/** Build without downloading so the same production layout can be rendered in QA. */
export function buildExpensePDF({mode, groupName = 'Personal', expenses = [], settlements = [], members = [], balances = [], currency = 'USD', userName = 'User', generatedAt = new Date()}) {
  const group = mode === 'group';
  const doc = new jsPDF({orientation: 'portrait', unit: 'mm', format: 'a4', compress: true});
  const width = doc.internal.pageSize.getWidth(), height = doc.internal.pageSize.getHeight();
  const margin = 14, usable = width - margin * 2, bodyTop = 30, bodyBottom = height - 20;
  const reportTitle = group ? 'Group expense statement' : 'Personal expense statement';
  doc.setProperties({title: reportTitle, subject: group ? groupName : userName, author: 'TripRaft', creator: 'TripRaft Expenses'});
  const active = expenses.filter(row => !row.is_deleted).sort((a, b) => day(a).localeCompare(day(b)) || String(a.id || '').localeCompare(String(b.id || '')));
  const payments = settlements.filter(row => !row.is_deleted);
  const income = group ? [] : active.filter(isPersonalIncome);
  const spending = group ? active : active.filter(row => !isPersonalIncome(row));
  const sum = rows => rows.reduce((total, row) => total + Math.round(numeric(row.amount) * 100), 0) / 100;
  const totalSpent = sum(spending), totalIncome = sum(income);
  const dates = active.map(day).filter(Boolean).sort();
  let y = bodyTop;
  const paragraph = (value, size = 9, color = MUTED) => {
    doc.setFont('helvetica', 'normal'); doc.setFontSize(size); doc.setTextColor(...color);
    const lines = doc.splitTextToSize(text(value), usable);
    doc.text(lines, margin, y); y += lines.length * size * .4 + 3;
  };
  doc.setFont('helvetica', 'bold'); doc.setFontSize(17); doc.setTextColor(...INK);
  const titleLines = doc.splitTextToSize(group ? groupName : userName, usable);
  doc.text(titleLines, margin, y); y += titleLines.length * 7 + 3;
  paragraph(`${dates.length ? `${dateLabel(dates[0])} to ${dateLabel(dates.at(-1))}` : 'No recorded transactions'} | Statement currency: ${currency}`);
  paragraph('Amounts use the saved ledger or selected personal display currency. Original receipts appear in transaction details.', 8);

  const table = (title, head, body, widths, rightColumns = [], foot) => {
    // Keep the section label with its repeated column header and first row.
    if (y + 28 > bodyBottom) {doc.addPage(); y = bodyTop;}
    doc.setFont('helvetica', 'bold'); doc.setFontSize(11); doc.setTextColor(...INK);
    doc.text(title, margin, y); y += 5;
    const columns = Object.fromEntries(widths.map((cellWidth, index) => [index, {cellWidth, halign: rightColumns.includes(index) ? 'right' : 'left',
      ...(rightColumns.includes(index) ? {fontStyle: 'bold'} : {})}]));
    autoTable(doc, {
      startY: y, head: [head], body: body.length ? body : [['No records', ...head.slice(1).map(() => '-')]],
      ...(foot ? {foot: [foot], showFoot: 'lastPage'} : {}),
      theme: 'plain', tableWidth: usable, margin: {left: margin, right: margin, top: bodyTop, bottom: 20},
      showHead: 'everyPage', rowPageBreak: 'avoid',
      styles: {font: 'helvetica', fontSize: 8.5, cellPadding: 3, overflow: 'linebreak', valign: 'top', textColor: INK,
        lineColor: [227, 232, 239], lineWidth: {bottom: .15}},
      headStyles: {fillColor: INK, textColor: [255, 255, 255], fontStyle: 'bold', fontSize: 8},
      footStyles: {fillColor: [235, 239, 248], textColor: INK, fontStyle: 'bold'},
      alternateRowStyles: {fillColor: [246, 248, 251]}, columnStyles: columns,
      didParseCell: data => {
        // AutoTable applies head/foot defaults after columnStyles. Explicitly
        // align every section to the same column edge, including its heading.
        data.cell.styles.halign = rightColumns.includes(data.column.index) ? 'right' : 'left';
        // Keep large monetary values intact instead of wrapping digits or clipping.
        if (data.section !== 'head' && rightColumns.includes(data.column.index)) {
          const value = String(data.cell.raw ?? '');
          doc.setFont('helvetica', 'bold');
          const unitWidth = doc.getStringUnitWidth(value);
          data.cell.styles.fontSize = Math.min(8.5, (widths[data.column.index] - 6) * doc.internal.scaleFactor / Math.max(unitWidth, 1));
        }
      },
    });
    y = doc.lastAutoTable.finalY + 12;
  };

  table('Statement summary', ['Measure', 'Amount / count'], [
    ['Total spending (net of refunds)', money(totalSpent, currency)],
    ...(!group ? [['Income received', money(totalIncome, currency)], ['Net cash flow', money(totalIncome - totalSpent, currency)]] : []),
    ['Recorded transactions', String(active.length)],
    ...(group ? [['Group members', String(members.length)], ['Payments recorded', money(sum(payments), currency)]] : []),
  ], [usable - 65, 65], [1]);

  let runningCents = 0;
  const description = row => {
    const receipt = row.original || (row.original_currency ? {currency: row.original_currency, amount: row.original_amount} : null);
    return [text(row.description), `${text(row.category || 'Other')}${!group ? ` | ${isPersonalIncome(row) ? 'Income' : 'Expense'}` : ` | ${text(row.split_type || 'equal')} split`}`,
      ...(receipt ? [`Original: ${money(receipt.amount, receipt.currency)}${receipt.rate ? ` | Rate: ${receipt.rate}${receipt.rate_date ? ` (${receipt.rate_date})` : ''}` : ''}`] : [])].join('\n');
  };
  const rows = active.map(row => {
    if (group) return [dateLabel(day(row)), description(row), expensePayers(row).map(payment => {
      const source = row.original?.payers?.find(entry => String(entry.user_id) === String(payment.user_id));
      return `${payment.user_name || memberName(payment.user_id, members, String(payment.user_id) === String(row.paid_by || row.paidBy) ? row.payer || row.paid_by_user : undefined)}${expensePayers(row).length > 1 ? `: ${money(payment.amount, currency)}${source ? ` (${money(source.amount, row.original.currency)})` : ''}` : ''}`;
    }).join('\n'), money(row.amount, currency)];
    const credit = isPersonalIncome(row), amount = numeric(row.amount);
    runningCents += Math.round(amount * 100) * (credit ? 1 : -1);
    return [dateLabel(day(row)), description(row), credit ? '-' : money(amount, currency), credit ? money(amount, currency) : '-', money(runningCents / 100, currency)];
  });
  table('Transaction activity', group ? ['Date', 'Description / source receipt', 'Paid by', 'Amount'] : ['Date', 'Description / source receipt', 'Money out', 'Money in', 'Net activity'], rows,
    group ? [24, usable - 106, 40, 42] : [24, usable - 120, 32, 32, 32], group ? [3] : [2, 3, 4],
    group ? ['Total', '', '', money(totalSpent, currency)] : ['Totals', '', money(totalSpent, currency), money(totalIncome, currency), money(totalIncome - totalSpent, currency)]);

  if (!group) {
    if (y + 14 > bodyBottom) {doc.addPage(); y = bodyTop;}
    paragraph('Net activity starts at zero for the exported records and equals income minus spending.', 8);
  }
  if (group && balances.length) table('Current member balances', ['Member', 'Gets back', 'Owes'], balances.map(row => {
    const balance = numeric(row.net_balance ?? row.balance);
    return [row.display_name || row.user_name || row.user?.display_name || memberName(row.user_id || row.id, members),
      balance > 0 ? money(balance, currency) : '-', balance < 0 ? money(-balance, currency) : '-'];
  }), [usable - 92, 46, 46], [1, 2]);
  if (group && payments.length) table('Recorded payments', ['Date', 'From', 'To', 'Amount'], payments.map(row => [
    dateLabel(day(row)), row.from_user_name || row.payer_name || memberName(row.from_user_id || row.payer_id || row.from, members, row.from_user),
    row.to_user_name || row.payee_name || memberName(row.to_user_id || row.payee_id || row.to, members, row.to_user), money(row.amount, currency),
  ]), [24, (usable - 66) / 2, (usable - 66) / 2, 42], [3]);
  const categories = new Map();
  spending.forEach(row => categories.set(row.category || 'Other', (categories.get(row.category || 'Other') || 0) + Math.round(numeric(row.amount) * 100)));
  table('Spending by category', ['Category', 'Net spending'], [...categories].sort((a, b) => b[1] - a[1]).map(([category, cents]) => [category, money(cents / 100, currency)]), [usable - 65, 65], [1]);

  const pages = doc.getNumberOfPages();
  for (let page = 1; page <= pages; page++) {
    doc.setPage(page); doc.setFillColor(...INK); doc.rect(0, 0, width, 22, 'F');
    doc.setFont('helvetica', 'bold'); doc.setFontSize(16); doc.setTextColor(255, 255, 255); doc.text('TripRaft', margin, 10);
    doc.setFont('helvetica', 'normal'); doc.setFontSize(8); doc.text(reportTitle, margin, 16);
    doc.text(`Generated ${dateLabel(generatedAt.toISOString().slice(0, 10))}`, width - margin, 10, {align: 'right'});
    doc.text(`Currency ${currency} | Private statement`, width - margin, 16, {align: 'right'});
    doc.setDrawColor(222, 228, 236); doc.line(margin, height - 15, width - margin, height - 15);
    doc.setFontSize(7.5); doc.setTextColor(...MUTED);
    doc.text('TripRaft | Expense statement | Private', margin, height - 10);
    doc.setTextColor(...ACCENT); doc.text(`Page ${page} of ${pages}`, width - margin, height - 10, {align: 'right'});
  }
  return doc;
}

export const generateExpensePDF = options => {
  const doc = buildExpensePDF(options);
  const name = options.mode === 'group' ? String(options.groupName || 'Group').replace(/[^a-z0-9]/gi, '_') : 'Personal_Expenses';
  const filename = `TripRaft_${name}_${new Date().toISOString().slice(0, 10)}.pdf`;
  doc.save(filename);
  return filename;
};

export default {generateExpensePDF};
