import { APIClient } from '../utils/apiClient';
import { demoRequest, resetDemo } from '../features/trips/demo/demoApi';
import { DEMO_VIEWER_KEY } from '../features/trips/demo/demoMode';
jest.mock('../config/globalConfig', () => ({ __esModule:true, default:{API_BASE_URL:'/api',API_TIMEOUT:1000,API_MAX_RETRIES:0} }));
jest.mock('../services/sqlAuthService', () => ({ __esModule:true, default:{getIdToken:jest.fn()} }));
jest.mock('../utils/apiLogger', () => ({ __esModule:true, default:{logError:jest.fn()} }));

beforeEach(() => { localStorage.clear(); window.history.replaceState({},'', '/group-planner/demo-kyoto?demo=1'); resetDemo(); global.fetch=jest.fn(); Object.defineProperty(global.crypto,'randomUUID',{configurable:true,value:()=>Math.random().toString(36).slice(2)}); });
afterEach(() => { window.history.replaceState({},'', '/'); });
it('returns populated demo data without making a real HTTP request, including for unsupported actions', async () => {
  const client=new APIClient();
  const groups=await client.get('/v1/group-planner/user/groups');
  expect(groups.data).toHaveLength(3);
  await expect(client.post('/v1/expenses/unknown-live-group',{amount:100})).rejects.toThrow('Demo ledger not found');
  expect(global.fetch).not.toHaveBeenCalled();
});
it('allows public catalog GET routes through demo isolation while blocking mutations', async () => {
  fetch.mockResolvedValue({ ok: true, status: 200, headers: { get: () => 'application/json' },
    text: async () => JSON.stringify({ success: true, data: [] }) });
  const client = new APIClient();
  await client.get('/v1/group-planner/catalog/destinations?q=Japan');
  expect(fetch).toHaveBeenCalledWith('/api/v1/group-planner/catalog/destinations?q=Japan', expect.objectContaining({ method: 'GET' }));
  await client.get('/v1/group-planner/catalog/viewport?destination_type=country&destination_id=1');
  await client.get('/v1/currencies');
  await client.get('/v1/exchange-rates?base=USD&quote=INR');
  await expect(client.post('/v1/exchange-rates', {rate: 100})).rejects.toThrow();
  await expect(client.get('/v1/currencies-extra')).rejects.toThrow();
  await expect(client.post('/v1/group-planner/catalog/viewport', { destination: 'Forbidden' })).rejects.toThrow();
  await expect(client.post('/v1/group-planner/catalog/destinations', { name: 'Forbidden' })).rejects.toThrow();
  await expect(client.get('/v1/group-planner/catalog/places-extra')).rejects.toThrow();
  expect(fetch).toHaveBeenCalledTimes(4);
});
it('enforces viewer and member restrictions in the demo service itself', async () => {
  localStorage.setItem(DEMO_VIEWER_KEY,'demo-elena');
  await expect(demoRequest('POST','/v1/group-planner/groups/demo-kyoto/places',{body:{name:'Forbidden'}})).rejects.toMatchObject({status:403});
  localStorage.setItem(DEMO_VIEWER_KEY,'demo-marcus');
  await expect(demoRequest('PUT','/v1/group-planner/groups/demo-kyoto',{body:{name:'Forbidden'}})).rejects.toMatchObject({status:403});
  expect((await demoRequest('GET','/v1/group-planner/groups/demo-kyoto')).data.name).toBe('Kyoto Autumn Crew');
});
it('keeps sample settings, stop creation and reset isolated in demo storage', async () => {
  await demoRequest('PUT','/v1/group-planner/groups/demo-kyoto',{body:{name:'My demo trip'}});
  await demoRequest('POST','/v1/group-planner/groups/demo-kyoto/places',{body:{name:'New stop',visit_date:'2026-10-16'}});
  expect((await demoRequest('GET','/v1/group-planner/groups/demo-kyoto/places')).data).toHaveLength(8);
  expect((await demoRequest('GET','/v1/group-planner/groups/demo-kyoto')).data.name).toBe('My demo trip');
  resetDemo();
  expect((await demoRequest('GET','/v1/group-planner/groups/demo-kyoto')).data.name).toBe('Kyoto Autumn Crew');
  expect((await demoRequest('GET','/v1/group-planner/groups/demo-kyoto/places')).data).toHaveLength(7);
});
it('uses real poll response shapes and supports switching and removing a demo vote', async () => {
  const endpoint='/v1/group-planner/groups/demo-kyoto/polls/demo-poll-food/vote';
  const vote=await demoRequest('POST',endpoint,{body:{option_index:1}});
  expect(vote.data.options).toEqual(['Kichi Kichi Omurice','Nishiki Market']);
  expect(vote.data.votes_detail['Kichi Kichi Omurice']).not.toContain('demo-alex');
  expect(vote.data.votes_detail['Nishiki Market']).toContain('demo-alex');
  const removed=await demoRequest('POST',endpoint,{body:{option_index:1}});
  expect(removed.data.voted_by).not.toContain('demo-alex');
});
it('lets owners and admins assign and clear responsibilities without promoting access', async () => {
  const path='/v1/group-planner/groups/demo-kyoto/members/demo-marcus/crew-role';
  const assigned=await demoRequest('PATCH',path,{body:{crew_role:'treasurer'}});
  expect(assigned.data).toMatchObject({role:'member',crew_role:'treasurer'});
  localStorage.setItem(DEMO_VIEWER_KEY,'demo-sarah');
  const cleared=await demoRequest('PATCH',path,{body:{crew_role:null}});
  expect(cleared.data).toMatchObject({role:'member',crew_role:null});
  const owner=await demoRequest('PATCH','/v1/group-planner/groups/demo-kyoto/members/demo-alex/crew-role',{body:{crew_role:'navigator'}});
  expect(owner.data).toMatchObject({role:'creator',crew_role:'navigator'});
  localStorage.setItem(DEMO_VIEWER_KEY,'demo-marcus');
  await expect(demoRequest('PATCH',path,{body:{crew_role:'treasurer'}})).rejects.toMatchObject({status:403});
});
