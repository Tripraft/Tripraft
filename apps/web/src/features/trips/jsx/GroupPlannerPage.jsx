// Purpose: Renders the Group Planner Page interface within apps\web\src\features\trips\jsx.
/** Full-screen group travel workspace with its own compact navigation. */

import React from 'react';
import GroupPlannerManager from './GroupPlannerManager';
import '../css/GroupPlannerPage.css';

export default function GroupPlannerPage() {
  return (
    <div className="gp-page">
      <main className="gp-main">
        <GroupPlannerManager />
      </main>
    </div>
  );
}
