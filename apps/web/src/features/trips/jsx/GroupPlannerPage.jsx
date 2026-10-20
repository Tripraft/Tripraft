// Purpose: Wraps the planner in shared site navigation, measures header height for layout, and enables DemoPlannerProvider only for demo=1.
/** Group planner content below the unchanged shared Tripraft navigation. */

import React, { useLayoutEffect, useRef, useState } from 'react';
import Header from '../../../components/layout/jsx/Header';
import { useAuth } from '../../../context/AuthContext';
import GroupPlannerManager from './GroupPlannerManager';
import { useSearchParams } from 'react-router-dom';
import DemoPlannerProvider from '../demo/DemoPlannerProvider';
import '../css/GroupPlannerPage.css';

export default function GroupPlannerPage() {
  const { currentUser, signOut } = useAuth();
  const [searchParams] = useSearchParams();
  const demo = searchParams.get('demo') === '1';
  const headerHost = useRef(null);
  const [headerHeight, setHeaderHeight] = useState(80);
  useLayoutEffect(() => {
    const header = headerHost.current?.querySelector('header');
    if (!header) return;
    const measure = () => setHeaderHeight(Math.ceil(header.getBoundingClientRect().height));
    measure();
    const observer = typeof ResizeObserver === 'undefined' ? null : new ResizeObserver(measure);
    observer?.observe(header);
    window.addEventListener('resize', measure);
    return () => {
      observer?.disconnect();
      window.removeEventListener('resize', measure);
    };
  }, []);
  return (
    <>
      <div ref={headerHost}>
        <Header isAuthenticated={!!currentUser} user={currentUser} onLogout={signOut} />
      </div>
      <div className="gp-page" style={{ '--gp-site-header-height': `${headerHeight}px` }}>
        <main className="gp-main">
          {demo ? (
            <DemoPlannerProvider>
              <GroupPlannerManager />
            </DemoPlannerProvider>
          ) : (
            <GroupPlannerManager />
          )}
        </main>
      </div>
    </>
  );
}
