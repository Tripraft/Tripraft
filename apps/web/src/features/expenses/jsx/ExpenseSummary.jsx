// Purpose: Calculates visible personal balance/income/spending or group expense totals while excluding deleted transactions.
import React from 'react';
import { Wallet, ArrowUpCircle, ArrowDownCircle } from 'lucide-react';
import {formatMoney} from '../../../utils/money';
import { isPersonalIncome } from '../utils/personalTransactions';

const ExpenseSummary = ({ transactions, mode = 'personal', currency = 'USD' }) => {
  const formatCurrency = amount => formatMoney(amount, currency);

  // Filter out deleted transactions for calculations
  const activeTransactions = transactions.filter(t => !t.is_deleted && (t.currency || currency) === currency);
  
  // For group mode: only show total expenses
  if (mode === 'group') {
    const totalExpenses = activeTransactions.reduce((sum, t) => sum + parseFloat(t.amount || 0), 0);
    
    return (
      <div className="summary-cards">
        <div className="summary-card expense-card-modern">
          <div className="expense-icon-wrapper">
            <ArrowDownCircle size={32} />
          </div>
          <div className="expense-details">
            <span className="expense-label">Total Expenses</span>
            <span className="expense-amount">{formatCurrency(totalExpenses)}</span>
            <span className="expense-count">{activeTransactions.length} transaction{activeTransactions.length !== 1 ? 's' : ''}</span>
          </div>
        </div>
      </div>
    );
  }
  
  // For personal mode: show all three cards
  const income = activeTransactions
    .filter(isPersonalIncome)
    .reduce((sum, t) => sum + parseFloat(t.amount || 0), 0);
  
  const expense = activeTransactions
    .filter(t => !isPersonalIncome(t))
    .reduce((sum, t) => sum + parseFloat(t.amount || 0), 0);
  
  const balance = income - expense;

  return (
    <div className="summary-cards">
      <div className="summary-card">
        <div className="card-header">
          <h2>Total Balance</h2>
          <Wallet className="icon-green" size={24} />
        </div>
        <p className="amount">{formatCurrency(balance)}</p>
      </div>
      <div className="summary-card">
        <div className="card-header">
          <h2>Total Income</h2>
          <ArrowUpCircle className="icon-blue" size={24} />
        </div>
        <p className="amount income-green">{formatCurrency(income)}</p>
      </div>
      <div className="summary-card">
        <div className="card-header">
          <h2>Total Expenses</h2>
          <ArrowDownCircle className="icon-red" size={24} />
        </div>
        <p className="amount expense-red">{formatCurrency(expense)}</p>
      </div>
    </div>
  );
};

export default ExpenseSummary;
