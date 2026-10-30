// Purpose: Checks real browser geometry of the split card through amount edits, payer modes and every split method.
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {mkdir} from 'node:fs/promises';
import {dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';

const testsRoot = dirname(fileURLToPath(import.meta.url));
const webRoot = dirname(testsRoot);
const require = createRequire(import.meta.url);
const {build} = createRequire(require.resolve('vite'))('esbuild');
// Playwright may be supplied by a test environment without becoming an app dependency.
const {chromium} = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fixture = `
import React from 'react';
import {createRoot} from 'react-dom/client';
import TransactionModal from '../src/features/expenses/jsx/TransactionModal';
import '../src/styles/global.css';
import '../src/features/expenses/css/ExpenseManager.css';
import '../src/features/expenses/css/ExpenseGroups.css';
import '../src/features/expenses/css/ExpenseResponsive.css';
const members = [{user_id:'a',display_name:'Alexandra Montgomery'}, {user_id:'b',display_name:'Jordan Richardson'}, {user_id:'c',display_name:'Taylor Henderson'}];
createRoot(document.getElementById('root')).render(<TransactionModal mode="group" activeGroup={{id:'g',currency:'INR'}} currentUser={{uid:'b'}} members={members} onClose={()=>{}} onSave={async()=>{}} />);
`;
const bundle = await build({
  stdin: {contents: fixture, resolveDir: testsRoot, loader: 'jsx'},
  bundle: true, write: false, outfile: join(webRoot, 'expense-layout.js'), jsx: 'automatic',
  define: {'process.env.NODE_ENV': '"production"', 'import.meta.env': '{}'},
  plugins: [{name: 'fixture-currencies', setup(builder) {
    builder.onLoad({filter: /services[\\/]currencyApi\.js$/}, () => ({loader: 'js', contents: `
      export async function getCurrencies(){return {currencies:['INR','USD','EUR'].map(code=>({code,name:code}))}};
      export async function getExchangeRate(base,quote){return {base,quote,rate:base===quote?1:90}};
    `}));
  }}],
});
const browser = await chromium.launch({headless: true, ...(process.env.EXPENSE_LAYOUT_BROWSER_CHANNEL && {channel: process.env.EXPENSE_LAYOUT_BROWSER_CHANNEL})});
try {
  const page = await browser.newPage({viewport: {width: 1100, height: 900}});
  await page.route('**/*', route => route.abort());
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.setContent('<html><body><div id="root"></div></body></html>');
  await page.addStyleTag({content: bundle.outputFiles.find(file => file.path.endsWith('.css')).text});
  await page.addScriptTag({content: bundle.outputFiles.find(file => file.path.endsWith('.js')).text});
  await page.getByLabel('Description', {exact: true}).fill('Group dinner');
  const card = page.locator('.expense-split-editor');
  let states = 0;
  for (const width of [1100, 700, 390, 320]) {
    await page.setViewportSize({width, height: 900});
    for (const mode of ['One person', 'Multiple people']) {
      await page.getByRole('button', {name: mode, exact: true}).click();
      for (const method of ['equal', 'exact', 'percentage', 'shares', 'adjustment', 'reimbursement', 'itemized']) {
        await page.getByLabel('Split method', {exact: true}).selectOption(method);
        for (const amount of ['5000', '', '5', '5000']) {
          await page.getByLabel('Amount', {exact: true}).fill(amount);
          if (mode === 'Multiple people') await page.locator('.payer-amount input:not(:disabled)').fill(amount);
          const geometry = await card.evaluate(element => ({
            height: element.getBoundingClientRect().height, scroll: element.scrollHeight, client: element.clientHeight,
            methodHeight: element.querySelector('#split-method').getBoundingClientRect().height,
            overflow: element.scrollWidth - element.clientWidth,
          }));
          const context = JSON.stringify({width, mode, method, amount, ...geometry});
          assert.ok(geometry.height >= 200 && geometry.methodHeight >= 20, context);
          assert.ok(geometry.scroll <= geometry.client + 2 && geometry.overflow <= 2, context);
          assert.ok(await page.getByRole('group', {name: 'Split with', exact: true}).isVisible(), context);
          states++;
        }
        if (process.env.EXPENSE_LAYOUT_EVIDENCE_DIR && ['equal', 'adjustment'].includes(method)) {
          await mkdir(process.env.EXPENSE_LAYOUT_EVIDENCE_DIR, {recursive: true});
          await card.screenshot({path: join(process.env.EXPENSE_LAYOUT_EVIDENCE_DIR, `split-${width}-${mode.replaceAll(' ', '-')}-${method}.png`)});
        }
      }
    }
  }
  assert.deepEqual(errors, []);
  console.log(`Split layout passed: ${states} rendered states, four viewport widths, both payer modes and all seven methods.`);
} finally {
  await browser.close();
}
