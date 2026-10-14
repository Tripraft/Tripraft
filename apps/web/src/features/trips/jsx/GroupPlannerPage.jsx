// Purpose: Renders the Group Planner Page interface within apps\web\src\features\trips\jsx.
/** Group planner content below the unchanged shared Tripraft navigation. */

import React, { useLayoutEffect, useRef, useState } from 'react';
import Header from '../../../components/layout/jsx/Header';
import { useAuth } from '../../../context/AuthContext';
import GroupPlannerManager from './GroupPlannerManager';
import '../css/GroupPlannerPage.css';

export default function GroupPlannerPage() {
  const { currentUser, signOut } = useAuth();
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
          <GroupPlannerManager />
        </main>
      </div>
    </>
  );
}
