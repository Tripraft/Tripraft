import React, { useMemo, useState, useEffect } from 'react';
import { Link, useParams } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import AuthContext, { useAuth } from '../../../context/AuthContext';
import { demoPeople } from './demoData';
import { getDemoViewer, resetDemo, getDemoState } from './demoApi';
import { DEMO_VIEWER_KEY } from './demoMode';

export default function DemoPlannerProvider({ children }) {
  const auth = useAuth();
  const { groupId } = useParams();
  const [, updateDemoLabels] = useState(0);
  useEffect(() => {
    const update = () => updateDemoLabels((n) => n + 1);
    window.addEventListener('tripraft-demo-updated', update);
    return () => window.removeEventListener('tripraft-demo-updated', update);
  }, []);
  const selectedMembers = getDemoState().trips[groupId]?.members || demoPeople;
  const [viewer, setViewer] = useState(getDemoViewer);
  const [revision, setRevision] = useState(0);
  const client = useMemo(
    () =>
      new QueryClient({
        defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
      }),
    [viewer.id, revision],
  );
  const value = useMemo(
    () => ({
      ...auth,
      currentUser: {
        uid: viewer.id,
        displayName: viewer.display_name,
        email: viewer.email,
        photoURL: viewer.photo_url,
      },
      loading: false,
      isAuthenticated: true,
    }),
    [auth, viewer],
  );
  return (
    <AuthContext.Provider value={value}>
      <QueryClientProvider client={client}>
        <div className="gp-demo-toolbar">
          <div>
            <strong>Demo workspace</strong>
            <span>Sample trips and people. Demo trip changes stay in this browser.</span>
          </div>
          <label>
            View as{' '}
            <select
              aria-label="Demo role"
              value={viewer.id}
              onChange={(event) => {
                const person = demoPeople.find((p) => p.id === event.target.value);
                localStorage.setItem(DEMO_VIEWER_KEY, person.id);
                setViewer(person);
              }}
            >
              {demoPeople.map((person) => {
                const role = selectedMembers.find((member) => member.user_id === person.id)?.role;
                return (
                  <option key={person.id} value={person.id}>
                    {person.display_name.split(' ')[0]} ·{' '}
                    {{ creator: 'Owner', admin: 'Admin', member: 'Member', viewer: 'Viewer' }[
                      role
                    ] || 'Not a member'}
                  </option>
                );
              })}
            </select>
          </label>
          <button
            onClick={() => {
              resetDemo();
              setRevision((r) => r + 1);
            }}
          >
            Reset demo
          </button>
          <Link to="/group-planner">Exit demo</Link>
        </div>
        <div key={`${viewer.id}:${revision}`}>{children}</div>
      </QueryClientProvider>
    </AuthContext.Provider>
  );
}
