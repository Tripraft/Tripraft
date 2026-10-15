import React, { useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { Plus, Receipt, Wallet, ArrowRight, Link2, Check, ArrowLeftRight } from 'lucide-react';
import { isPlannerDemo } from '../../demo/demoMode';
import { useAuth } from '../../../../context/AuthContext';
import { useExpenseSummary, gpKeys } from '../../../../hooks/useGroupPlannerQuery';
import { queryKeys } from '../../../../hooks/useExpenseQuery';
import expenseApi from '../../../../services/expenseApi';
import groupPlannerApi from '../../../../services/groupPlannerApi';
import { toObject } from '../../utils/groupPlannerUtils';
import { formatDate } from '../../utils/formatters';
import { formatMoney } from '../../../../utils/money';
import { suggestedSettlements } from '../../utils/plannerMoney';
import { canRecordSettlement } from '../../../expenses/utils/groupPermissions';
import SettlementModal from '../../../expenses/jsx/SettlementModal';
import PlannerExpenseModal from '../shared/PlannerExpenseModal';
export default function TreasuryTab({
  groupId,
  group,
  budgetCurrency,
  showToast,
  canEdit = true,
  canManage = false,
}) {
  const client = useQueryClient(),
    navigate = useNavigate(),
    { currentUser } = useAuth();
  const { data: summaryRaw, isLoading, error } = useExpenseSummary(groupId),
    summary = toObject(summaryRaw);
  const ledgerId = group?.expense_group_id || summary?.expense_group_id;
  const key = ['group-planner', 'ledger', groupId, ledgerId];
  const {
    data: ledgerRaw,
    isLoading: ledgerLoading,
    error: ledgerError,
  } = useQuery({
    queryKey: key,
    queryFn: () => expenseApi.getGroupFull(ledgerId),
    enabled: !!ledgerId,
    staleTime: 15000,
  });
  const ledger = ledgerRaw?.data?.group || ledgerRaw?.group || null,
    currency = ledger?.currency || budgetCurrency || 'USD',
    expenses = (ledger?.expenses || summary?.expenses || []).filter((e) => !e.is_deleted),
    members = (ledger?.members || []).filter((m) => m.is_active !== false);
  const total = ledger
      ? expenses.reduce((sum, e) => sum + Number(e.amount || 0), 0)
      : Number(summary?.total_spent || 0),
    budget =
      currency === (group?.budget_currency || currency)
        ? Number(group?.estimated_budget || summary?.estimated_budget || 0)
        : 0,
    percent = budget ? Math.round((total / budget) * 100) : 0;
  const [modal, setModal] = useState(null),
    [settlement, setSettlement] = useState(null),
    [linking, setLinking] = useState(false),
    [showAll, setShowAll] = useState(false),
    [conversion, setConversion] = useState(false),
    [displayCurrency, setDisplayCurrency] = useState(''),
    [rate, setRate] = useState(1);
  const displayRate = displayCurrency && displayCurrency !== currency ? Number(rate) || 1 : 1;
  const display = (value) => formatMoney(value * displayRate, displayCurrency || currency);
  const name = (id) => {
    const m = members.find((m) => String(m.user_id || m.id) === String(id));
    return m?.display_name || m?.user?.display_name || m?.email || 'Member';
  };
  const debts = useMemo(() => suggestedSettlements(ledger?.balances || []), [ledger?.balances]);
  const refresh = () => {
    for (const queryKey of [
      key,
      gpKeys.expenses(groupId),
      gpKeys.activities(groupId),
      queryKeys.group(ledgerId),
      queryKeys.expenses(ledgerId),
      queryKeys.groups,
      queryKeys.megaBootstrap(ledgerId),
      queryKeys.settlements(ledgerId),
    ])
      client.invalidateQueries({ queryKey });
  };
  const saveExpense = async (data) => {
    await expenseApi.createExpense({ ...data, group_id: ledgerId, currency });
    refresh();
    showToast?.('Expense saved');
  };
  const link = async () => {
    if (linking) return;
    setLinking(true);
    try {
      await groupPlannerApi.linkExpenseGroup(groupId);
      client.invalidateQueries({ queryKey: gpKeys.group(groupId) });
      client.invalidateQueries({ queryKey: gpKeys.expenses(groupId) });
      showToast?.('Trip treasury connected');
    } catch (e) {
      showToast?.(e.message || 'Could not connect treasury', 'error');
    } finally {
      setLinking(false);
    }
  };
  if (isLoading) return <p role="status">Loading treasury...</p>;
  if (error || summary?.error) return <p role="alert">{error?.message || summary.error}</p>;
  return (
    <div className="gp-view">
      <div className="gp-tab-heading">
        <div>
          <span className="gp-eyebrow">LESS MATH. MORE MEMORIES.</span>
          <h1>Trip Treasury</h1>
          <p>Keep shared costs clear and settle up with your travel crew.</p>
        </div>
        {ledgerId && canEdit && (
          <div className="gp-hub-hero-actions">
            <button
              className="gp-hub-button"
              disabled={!ledger}
              onClick={() => setModal('receipt')}
            >
              <Receipt size={15} />
              Receipt Split
            </button>
            <button
              className="gp-btn-create"
              disabled={!ledger}
              onClick={() => setModal('expense')}
            >
              <Plus size={15} />
              Log Expense
            </button>
          </div>
        )}
      </div>
      <div className="gp-treasury-overview">
        <div
          className="gp-budget-ring"
          style={{
            background: `conic-gradient(${percent > 100 ? '#ff6b4a' : '#087ea4'} ${Math.min(percent, 100)}%,#e6f4f9 0)`,
          }}
        >
          <span>
            <strong>{budget ? percent + '%' : '--'}</strong>
            <small>{budget ? 'of budget' : 'Set budget'}</small>
          </span>
        </div>
        <div className="gp-treasury-headline">
          <span>Total Trip Spend</span>
          <h2>{display(total)}</h2>
          <p>
            {budget ? <>of {display(budget)} budget · </> : null}
            {display(
              total /
                Math.max(1, members.length || summary?.member_count || group?.member_count || 1),
            )}{' '}
            / person
          </p>
          {percent > 100 && (
            <span className="gp-over-budget">{display(total - budget)} over budget</span>
          )}
          {displayCurrency && displayCurrency !== currency && (
            <p className="gp-form-hint">
              Display estimate at your entered rate: 1 {currency} = {rate} {displayCurrency}
            </p>
          )}
        </div>
        <button className="gp-hub-button" onClick={() => setConversion(true)}>
          <ArrowLeftRight size={14} />
          {displayCurrency || currency}
        </button>
      </div>
      {!ledgerId ? (
        <div className="gp-feature-card gp-treasury-connect">
          <Wallet size={33} />
          <h2>Bring your shared costs into this trip</h2>
          <p>Connect a treasury for this group to log expenses and view balances.</p>
          {canManage ? (
            <button className="gp-modal-btn-primary" disabled={linking} onClick={link}>
              <Link2 size={14} />
              {linking ? 'Connecting...' : 'Connect Trip Treasury'}
            </button>
          ) : (
            <p className="gp-form-hint">An owner or admin can connect your trip treasury.</p>
          )}
        </div>
      ) : ledgerLoading ? (
        <p role="status">Loading expenses and balances...</p>
      ) : ledgerError ? (
        <p role="alert">{ledgerError.message}</p>
      ) : (
        <div className="gp-treasury-columns">
          <section className="gp-feature-card">
            <div className="gp-feature-heading">
              <div className="gp-feature-icon">
                <ArrowLeftRight size={21} />
              </div>
              <div>
                <h2>Who Owes Whom</h2>
                <p>Simplified settlements from current group balances</p>
              </div>
            </div>
            {debts.length === 0 ? (
              <div className="gp-empty-agenda">
                <Check size={25} />
                <h3>All settled up</h3>
                <p>No outstanding balances.</p>
              </div>
            ) : (
              debts.map((debt, i) => (
                <div className="gp-debt-row" key={debt.from + debt.to}>
                  <div className="gp-debt-people">
                    <strong>{name(debt.from)}</strong>
                    <span>
                      pays <ArrowRight size={12} />
                      {name(debt.to)}
                    </span>
                  </div>
                  <strong>{display(debt.amount)}</strong>
                  {canEdit && canRecordSettlement(ledger, currentUser?.uid, debt.from, debt.to) && (
                    <button
                      onClick={() =>
                        setSettlement({ ...debt, fromName: name(debt.from), toName: name(debt.to) })
                      }
                    >
                      Settle
                    </button>
                  )}
                </div>
              ))
            )}
            <p className="gp-form-hint gp-settlement-hint">
              Settlements record payments you have made. They do not transfer money.
            </p>
          </section>
          <section className="gp-feature-card">
            <div className="gp-feature-heading">
              <div className="gp-feature-icon">
                <Receipt size={21} />
              </div>
              <div>
                <h2>Recent Expenses</h2>
                <p>
                  {expenses.length} shared expense{expenses.length === 1 ? '' : 's'} in this trip
                </p>
              </div>
            </div>
            {expenses.length === 0 ? (
              <div className="gp-empty-agenda">
                No shared costs yet. Log the first expense when you are ready.
              </div>
            ) : (
              [...expenses]
                .sort((a, b) =>
                  String(b.expense_date || b.created_at || '').localeCompare(
                    String(a.expense_date || a.created_at || ''),
                  ),
                )
                .slice(0, showAll ? undefined : 12)
                .map((e) => (
                  <article className="gp-treasury-expense" key={e.id || e.expense_id}>
                    <span className="gp-expense-category">
                      <Receipt size={16} />
                    </span>
                    <div>
                      <h3>{e.description}</h3>
                      <p>
                        {name(e.paid_by)} paid · {formatDate(e.expense_date || e.created_at)} ·{' '}
                        {e.category || 'Other'}
                      </p>
                    </div>
                    <strong>{display(e.amount)}</strong>
                  </article>
                ))
            )}
          </section>
        </div>
      )}
      {ledgerId && (
        <button
          className="gp-treasury-ledger-link"
          onClick={() =>
            isPlannerDemo()
              ? setShowAll(true)
              : navigate('/expenses?view=group&groupId=' + encodeURIComponent(ledgerId))
          }
        >
          {isPlannerDemo() ? 'Show all demo expenses' : 'Open full expense ledger'}
          <ArrowRight size={14} />
        </button>
      )}
      {modal && ledger && (
        <PlannerExpenseModal
          members={members}
          currency={currency}
          currentUserId={currentUser?.uid}
          itemized={modal === 'receipt'}
          onSave={saveExpense}
          onClose={() => setModal(null)}
        />
      )}
      <SettlementModal
        isOpen={!!settlement}
        settlement={settlement}
        onClose={() => setSettlement(null)}
        groupId={ledgerId}
        group={ledger}
        members={members}
        balances={ledger?.balances || []}
        currency={currency}
        currentUserId={currentUser?.uid}
        onSuccess={async (data) => {
          await expenseApi.createSettlement(data);
          refresh();
          showToast?.('Settlement recorded');
        }}
      />
      {conversion && (
        <div className="gp-modal-overlay" onClick={() => setConversion(false)}>
          <form
            className="gp-modal"
            role="dialog"
            aria-modal="true"
            aria-label="Display Currency"
            onClick={(e) => e.stopPropagation()}
            onSubmit={(e) => {
              e.preventDefault();
              setConversion(false);
            }}
          >
            <h2 className="gp-modal-title">Display Currency</h2>
            <p className="gp-form-hint">
              Amounts are stored in {currency}. Enter a rate to preview another currency.
            </p>
            <label className="gp-field">
              Display currency
              <select
                className="gp-modal-input"
                value={displayCurrency || currency}
                onChange={(e) => {
                  setDisplayCurrency(e.target.value);
                  if (e.target.value === currency) setRate(1);
                }}
              >
                {[...new Set([currency, 'USD', 'EUR', 'JPY', 'GBP', 'INR', 'CHF'])].map((c) => (
                  <option key={c}>{c}</option>
                ))}
              </select>
            </label>
            <label className="gp-field">
              Units per 1 {currency}
              <input
                className="gp-modal-input"
                type="number"
                min="0.000001"
                step="any"
                required
                value={rate}
                onChange={(e) => setRate(e.target.value)}
              />
            </label>
            <div className="gp-modal-actions">
              <button className="gp-modal-btn-primary">Apply Display Rate</button>
              <button
                className="gp-modal-btn-secondary"
                type="button"
                onClick={() => {
                  setDisplayCurrency('');
                  setRate(1);
                  setConversion(false);
                }}
              >
                Use {currency}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
