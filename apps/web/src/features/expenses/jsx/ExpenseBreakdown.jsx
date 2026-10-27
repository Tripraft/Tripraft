// Purpose: Shows each expense's payer, purpose, category and actual shares, including non-participants.
import React from 'react';
import { ChevronDown } from 'lucide-react';
import useMoneyDisplay from '../../../hooks/useMoneyDisplay';
import { expensePeople, expenseParticipation } from '../utils/expensePeople';
import '../css/ExpenseBreakdown.css';

export default function ExpenseBreakdown({ expenses = [], members = [], currentUserId, selectedUserId,
  currency = 'USD', displayCurrency = currency, title = 'Expense breakdown' }) {
  const money = useMoneyDisplay(currency, displayCurrency);
  const active = expenses.filter(e => !e.is_deleted);
  const people = expensePeople(members, active);
  const name = id => people.find(person => person.id === String(id))?.name || 'Former member';
  const selected = selectedUserId != null && selectedUserId !== '';
  const own = selected && String(selectedUserId) === String(currentUserId);
  const notInvolved = id => String(id) === String(currentUserId) ? "You weren't involved in this expense." : `${name(id)} wasn't involved in this expense.`;
  return <section className="expense-breakdown" aria-label={title}>
    <h3>{title}</h3>
    {!active.length ? <p>No transactions for this member.</p> : <ul>{active.map((expense, index) => {
      const share = expenseParticipation(expense, selectedUserId);
      const where = expense.merchant || expense.location_name || expense.location;
      return <li key={expense.id || expense.expense_id || index}><details>
        <summary><div className="expense-breakdown-description"><strong>{expense.description || 'Expense'}</strong>
          <small>{expense.category || 'Other'}{expense.expense_date ? ` · ${String(expense.expense_date).slice(0, 10)}` : ''}{typeof where === 'string' && where ? ` · ${where}` : ''}</small>
          <small>{expense.split_type === 'reimbursement' ? 'Refund received by' : 'Paid by'} {name(expense.paid_by)}</small>
          {selected && !share.involved && <small className="expense-not-involved">{notInvolved(selectedUserId)}</small>}
        </div><div className="expense-breakdown-amount"><strong>{money(selected ? share.amount : expense.amount)}</strong>
          {selected && <small>{Number(share.percent.toFixed(2))}% · {own ? 'Your share' : `${name(selectedUserId)}'s share`}</small>}
          <small>{selected ? `Expense total: ${money(expense.amount)}` : 'View everyone’s shares'}</small></div><ChevronDown className="expense-breakdown-chevron" size={16} aria-hidden="true" /></summary>
        <dl aria-label={`Shares for ${expense.description || 'expense'}`}>{people.map(person => {
          const participation = expenseParticipation(expense, person.id);
          return <div key={person.id}><dt>{person.name}{String(person.id) === String(currentUserId) ? ' (You)' : ''}
            {!participation.involved && <small>{notInvolved(person.id)}</small>}
            {participation.involved && participation.amount === 0 && <small>No amount assigned.</small>}
          </dt><dd>{money(participation.amount)} <small>{Number(participation.percent.toFixed(2))}%</small></dd></div>;
        })}</dl>
      </details></li>;
    })}</ul>}
  </section>;
}
