// Purpose: Shows each member's payments and expands their transactions with saved participant shares.
import React, { useMemo, useState } from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';
import CurrencyAmount from './CurrencyAmount';
import { expensePeople } from '../utils/expensePeople';
import ExpenseBreakdown from './ExpenseBreakdown';
import { expensePayers, paidAmount } from '../utils/payers';

export default function MemberSpending({ expenses = [], members = [], currency = 'USD', displayCurrency = currency, currentUserId }) {
  const [expanded, setExpanded] = useState(null);
  const spending = useMemo(() => expensePeople(members, expenses).map(person => {
    const transactions = expenses.filter(e => !e.is_deleted && expensePayers(e).some(row => String(row.user_id) === person.id));
    return { ...person, transactions, paid: transactions.reduce((sum, e) => sum + paidAmount(e, person.id), 0) };
  }).sort((a, b) => b.paid - a.paid || a.name.localeCompare(b.name)), [expenses, members]);
  const total = spending.reduce((sum, person) => sum + person.paid, 0);
  return <section aria-label="Member spending">
    <div className="expense-member-spending-heading"><div><h3>Member Spending</h3><p>Select a member to see every expense they paid for.</p></div><span>{spending.length} member{spending.length === 1 ? '' : 's'}</span></div>
    {!spending.length ? <p>No member spending yet.</p> : <div className="expense-member-spending-list">{spending.map(person => {
      const open = expanded === person.id;
      return <article key={person.id}>
        <button type="button" className="expense-member-toggle" aria-expanded={open} aria-controls={`member-spending-${person.id}`}
          aria-label={`View transactions paid by ${person.name}`} onClick={() => setExpanded(open ? null : person.id)}>
          <span><strong>{person.name}{person.id === String(currentUserId) ? ' (You)' : ''}</strong><small>{person.transactions.length} expense{person.transactions.length === 1 ? '' : 's'}</small></span>
          <span><strong><CurrencyAmount amount={person.paid} currency={currency} displayCurrency={displayCurrency} /></strong><small>{total > 0 ? Number((person.paid / total * 100).toFixed(1)) : 0}% of total</small></span>
          {open ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
        </button>
        {open && <div id={`member-spending-${person.id}`}><ExpenseBreakdown title={`Transactions paid by ${person.name}`} expenses={person.transactions} members={members} currentUserId={currentUserId} currency={currency} displayCurrency={displayCurrency} /></div>}
      </article>;
    })}</div>}
    {spending.length > 0 && <div className="expense-member-spending-total"><span>Total Group Spending</span><strong><CurrencyAmount amount={total} currency={currency} displayCurrency={displayCurrency} /></strong></div>}
  </section>;
}
