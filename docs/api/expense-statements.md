# Personal and group PDF statements

The existing Export PDF action downloads an A4 statement using the same complete
ledger as the expense screen. Personal export waits for currency conversion and
requires the complete ledger to load. Deleted transactions and payments are
excluded. The statement labels its currency and exported date interval.

Personal statements separate money out, money in and cumulative net activity.
Income is excluded from spending/category totals; refunds reduce net spending.
Net activity starts at zero for the exported records. Group statements show
spending, payer names, current balances, payments and categories. Settlement
dates take priority over creation timestamps. Historical saved participant names
are used when an account is no longer in the active member list.

The bank-style layout uses fixed page margins, repeated table headers, full
wrapped descriptions, compact cell padding and right-aligned money columns.
Large amounts shrink to fit their cells without dropping digits. Currency codes
such as `INR` avoid unsupported currency-symbol glyphs in the built-in PDF font.
Categories, split methods and source receipts appear below descriptions, leaving
space for dates and amounts. Converted receipts preserve original money and any
saved rate/date. Each page includes a statement header and Page X of Y footer.
Section titles stay with the table header; rows stay together when they fit on
one page. Very long rows can continue across pages rather than being truncated.

`buildExpensePDF` constructs the document without downloading;
`generateExpensePDF` preserves the existing filename/download interface.
`expensePdf.test.js` uses real jsPDF/AutoTable output to cover cash flow,
one-cent balances, settlement names/dates and multi-page content. October 26
visual QA rendered six personal and six group pages with long merchant
references and amounts up to `USD 12,000,000,000.00`; bounds, text completeness,
headers and page numbering were also checked programmatically. Samples contain
synthetic data and remain in ignored `.tripraft/pdf-qa/`.
