// Purpose: Checks invitation chips, friend lookup and background sending in real desktop/mobile browser layouts.
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {mkdir} from 'node:fs/promises';
import {dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';

const testsRoot = dirname(fileURLToPath(import.meta.url));
const webRoot = dirname(testsRoot);
const require = createRequire(import.meta.url);
const {build} = createRequire(require.resolve('vite'))('esbuild');
const {chromium} = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const bundle = await build({
  stdin: {resolveDir: testsRoot, loader: 'jsx', contents: `
    import React, {useState} from 'react';
    import {createRoot} from 'react-dom/client';
    import {QueryClient, QueryClientProvider} from '@tanstack/react-query';
    import NewGroup from '../src/features/expenses/jsx/NewExpenseGroupModal';
    import Progress from '../src/features/expenses/jsx/ExpenseInvitationDelivery';
    import '../src/styles/global.css';
    import '../src/features/expenses/css/ExpenseManager.css';
    import '../src/features/expenses/css/ExpenseGroups.css';
    import '../src/features/expenses/css/ExpenseResponsive.css';
    const client = new QueryClient({defaultOptions: {queries: {retry: false}}});
    window.invitationRequests = [];
    window.finishInvitations = [];
    function Preview() {
      const [open, setOpen] = useState(true), [batch, setBatch] = useState(null), [group, setGroup] = useState(false);
      return <QueryClientProvider client={client}><main className="expense-manager" style={{maxWidth:900,margin:'24px auto',padding:16}}>
        <h1>{group ? 'Weekend trip' : 'Group expenses'}</h1>
        {batch && <Progress batch={batch} onDismiss={() => setBatch(null)} />}
        {group && <p>Your group is ready. Invitees join after accepting.</p>}
        {open && <NewGroup userId="owner" onCreate={async () => {setGroup(true);return {group:{id:'preview-group'}}}} onInvitationsReady={setBatch} onClose={() => setOpen(false)} />}
      </main></QueryClientProvider>;
    }
    createRoot(document.getElementById('root')).render(<Preview />);
  `},
  bundle: true, write: false, outfile: join(webRoot, 'invitation-flow.js'), jsx: 'automatic',
  define: {'process.env.NODE_ENV': '"production"', 'import.meta.env': '{}'},
  plugins: [{name: 'fixture-services', setup(builder) {
    builder.onLoad({filter: /services[\\/]currencyApi\.js$/}, () => ({loader: 'js', contents: `
      export async function getCurrencies(){return {currencies:[{code:'INR',name:'Indian Rupee'}]}};
    `}));
    builder.onLoad({filter: /services[\\/]expenseApi\.js$/}, () => ({loader: 'js', contents: `
      export default {
        async getFriends(){return {data:{friends:[{id:'jane',email:'jane@example.test',label:'JP',display_name:'Jane Patel',nickname:'JP',is_registered:true}],has_more:false}}},
        sendInvitation(data){window.invitationRequests.push(data);return new Promise(resolve=>window.finishInvitations.push(()=>resolve({data:{email_status:'sent',invitation:{id:data.invitee_email}}})))},
      };
    `}));
  }}],
});
const browser = await chromium.launch({headless: true, ...(process.env.EXPENSE_LAYOUT_BROWSER_CHANNEL && {channel: process.env.EXPENSE_LAYOUT_BROWSER_CHANNEL})});
try {
  for (const width of [1100, 390, 320]) {
    const page = await browser.newPage({viewport: {width, height: 900}});
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.route('**/*', route => route.abort());
    await page.setContent('<html><body><div id="root"></div></body></html>');
    await page.addStyleTag({content: bundle.outputFiles.find(file => file.path.endsWith('.css')).text});
    await page.addScriptTag({content: bundle.outputFiles.find(file => file.path.endsWith('.js')).text});
    await page.getByLabel('Group name', {exact: true}).fill('Weekend trip');
    const recipient = page.getByLabel('Invite by email (optional)', {exact: true});
    await recipient.fill('FIRST@example.test'); await recipient.press('Enter');
    await recipient.fill('first@example.test'); await recipient.press('Tab');
    assert.equal(await page.getByRole('list', {name: 'Selected invitees'}).getByRole('listitem').count(), 1);
    await recipient.fill('JP');
    await page.getByRole('button', {name: /JP Jane Patel/}).click();
    assert.equal(await page.getByRole('button', {name: 'Remove JP'}).count(), 1);
    const overflow = await page.getByRole('dialog').evaluate(element => element.scrollWidth - element.clientWidth);
    assert.ok(overflow <= 2, `Dialog overflow at ${width}: ${overflow}`);
    if (process.env.EXPENSE_INVITATION_EVIDENCE_DIR) {
      await mkdir(process.env.EXPENSE_INVITATION_EVIDENCE_DIR, {recursive: true});
      await page.screenshot({path: join(process.env.EXPENSE_INVITATION_EVIDENCE_DIR, `invitation-chips-${width}.png`)});
    }
    await page.getByRole('button', {name: 'Create group and invite'}).click();
    await page.getByRole('heading', {name: 'Sending invitations'}).waitFor();
    assert.equal(await page.getByRole('dialog').count(), 0);
    const requests = await page.evaluate(() => window.invitationRequests);
    assert.deepEqual(requests.map(row => row.invitee_email).sort(), ['first@example.test', 'jane@example.test']);
    assert.ok(await page.locator('.spinning').evaluate(element => getComputedStyle(element).animationName !== 'none'));
    assert.equal(await page.getByRole('button', {name: 'Show invitation details'}).getAttribute('aria-expanded'), 'false');
    assert.ok(await page.getByRole('heading', {name: 'Weekend trip'}).isVisible());
    const statusBox = await page.getByRole('region', {name: 'Invitation delivery'}).boundingBox();
    assert.ok(statusBox.height < 140 && statusBox.width <= Math.min(360, width - 32), 'Sending status must stay compact and leave the group usable');
    if (process.env.EXPENSE_INVITATION_EVIDENCE_DIR) await page.screenshot({path: join(process.env.EXPENSE_INVITATION_EVIDENCE_DIR, `invitation-sending-${width}.png`)});
    await page.emulateMedia({reducedMotion: 'reduce'});
    assert.equal(await page.locator('.spinning').evaluate(element => getComputedStyle(element).animationName), 'none');
    await page.evaluate(() => window.finishInvitations.forEach(finish => finish()));
    await page.getByRole('heading', {name: 'Invitation results'}).waitFor();
    await page.getByRole('button', {name: 'Show invitation details'}).click();
    assert.equal(await page.getByText('Invitation email sent.', {exact: true}).count(), 2);
    assert.deepEqual(errors, []);
    await page.close();
  }
  console.log('Invitation flow passed at 1100px, 390px and 320px: friend chips, deduplication, immediate group page, animation and reduced motion.');
} finally { await browser.close(); }
