// Purpose: Covers complete workspace lists and catalog-to-planner place contracts.
jest.mock('../config/globalConfig', () => ({__esModule: true, default: {ENDPOINTS: {GROUP_PLANNER: '/v1/group-planner'}}}));
jest.mock('../utils/apiClient', () => ({__esModule: true, default: {get: jest.fn(), post: jest.fn()}}));
import api from '../utils/apiClient';
import planner from '../services/groupPlannerApi';

beforeEach(() => jest.clearAllMocks());

it.each(['getUserGroups', 'getGroupPlaces', 'getGroupPolls', 'getGroupChecklist'])('loads every page for %s', async method => {
  api.get.mockResolvedValueOnce({success: true, data: [{id: 'first'}], meta: {pagination: {total_pages: 2}}})
    .mockResolvedValueOnce({success: true, data: [{id: 'last'}], meta: {pagination: {total_pages: 2}}});
  const result = await planner[method]('group');
  expect(result.data).toEqual([{id: 'first'}, {id: 'last'}]);
  expect(api.get.mock.calls[1][0]).toContain('page=2&per_page=100');
});

it('does not hide a failed later page behind a partial list', async () => {
  api.get.mockResolvedValueOnce({success: true, data: [{id: 'first'}], meta: {pagination: {total_pages: 2}}})
    .mockRejectedValueOnce(new Error('Offline'));
  await expect(planner.getGroupPlaces('group')).rejects.toThrow('Offline');
});

it('adds a catalog place with supported fields and preserves zero coordinates and rating', async () => {
  await planner.addPlace('group', {id: 123, place_name: 'Museum', latitude: 0, longitude: 0,
    rating: 0, rating_tourist_priority: 4, photos: [{photo_url: 'https://example.test/museum.jpg'}],
    official_website: 'https://example.test'});
  const data = api.post.mock.calls[0][1];
  expect(data).toMatchObject({name: 'Museum', latitude: 0, longitude: 0, rating: 0,
    photo_url: 'https://example.test/museum.jpg', website: 'https://example.test'});
  expect(data).not.toHaveProperty('place_id');
});
