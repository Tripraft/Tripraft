// Purpose: Detects opt-in planner demo routes, preserves the demo query in planner links, and defines demo storage keys.
// Demo mode is opt-in and scoped to the Group Planner route.
export function isPlannerDemo() {
  return (
    typeof window !== 'undefined' &&
    (window.location.pathname === '/group-planner' || window.location.pathname.startsWith('/group-planner/') || /^\/groups\/[^/]+\/planner\/?$/.test(window.location.pathname)) &&
    new URLSearchParams(window.location.search).get('demo') === '1'
  );
}
export function plannerPath(path) {
  return path + (isPlannerDemo() ? '?demo=1' : '');
}
export const DEMO_STORAGE_KEY = 'tripraft_group_planner_demo_v1';
export const DEMO_VIEWER_KEY = 'tripraft_group_planner_demo_viewer';
