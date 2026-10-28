# Multiple payers on a group expense

The expense form offers **One person** and **Multiple people**, independently of
the equal, exact, percentage, shares, adjustment, reimbursement and itemized split
methods. Contributions use the expense currency and must add up to its total.
Refunds use the same controls to record who received the money.

Choose one payer using the member radio list, or tick the members who contributed
in **Multiple people**. Unselected members' amount inputs stay disabled. There
are no payer dropdowns or separate add/remove actions. Currency codes occupy a
fixed column beside each amount. Balance previews align money at the top of
each row with the receive/pay status underneath; on phones they become labelled
member cards.

New groups default to INR unless a saved currency preference is supplied.
Existing groups retain their currency. Selecting USD for an INR group shows
USD contributions and estimated INR amounts. Saved details, history and PDFs
retain each source contribution together with the converted ledger contribution.
The preferred group display currency is also respected in previews.
When the entered currency matches the group's selected currency, show a single
amount. Show a second amount only when the entered currency differs. If a saved
receipt already uses the display currency, show that saved amount once, without
converting it back through a different ledger currency.

Focused number fields in expense dialogs ignore mouse-wheel stepping, including
personal expenses, income, group amounts, payments and split inputs.

## API and accounting

Create and update requests accept an optional `payers` list:

```json
{
  "amount": "1200.00",
  "currency": "INR",
  "payers": [
    {"user_id": "<member UUID>", "amount": "900.00"},
    {"user_id": "<another member UUID>", "amount": "300.00"}
  ],
  "split_type": "equal"
}
```

Each payer must be a unique active member with a positive source amount. Payers
need not appear in the split. The server derives the legacy `paid_by` field from
the first contribution; clients must use `payers` for payment amounts and names.
Personal transactions reject this field.

For each person, the balance change is their signed payment minus their signed
cost share. Reimbursements store both allocations as negative amounts. When
currencies differ, split amounts and payments independently allocate the same
converted total in whole cents using largest remainders and stable row order.
This keeps payments, splits and balances reconciled even for small amounts.

An omitted `payers` field preserves existing contributions on metadata updates.
Changing financial fields on a multi-payer expense requires the contribution
list again. A one-entry list switches back to one payer. A payer-only update to
a foreign receipt uses its saved source amount and exchange rate. Metadata edits,
deletion and restoration do not fetch a new rate. Existing expenses without
payment rows continue to credit their original payer for the full signed amount.

## Database release

Revision `c28ed7f80912`, following `b17dc6e7f801`, adds `expense_payments` with
an expense/member uniqueness constraint, ordered contributions, foreign keys
and signed `amount_minor` values in whole cents. It does not rewrite old data.
The companion development manifest uses the existing additive startup bridge;
it requires no update to the owner setup function. The Alembic path revokes
public API access and grants CRUD to the existing restricted development role.

Follow [database releases](database-releases.md) to release this revision with
the matching application code. Do not deploy the new API against the old schema.
The new payment rows load in a single batch for an expense page; the full-group
read budget is nine queries and does not grow per payer or expense.
