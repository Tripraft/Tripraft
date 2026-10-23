import { useEffect, type ReactNode } from 'react';
import './adminWorkspace.css';

type Props = { children: ReactNode; signedIn: boolean; email: string; loading: boolean; view: string };

export function AdminWorkspace({ children, signedIn, email, loading, view }: Props) {
  useEffect(() => {
    if (loading) return;
    if (!signedIn && window.location.pathname === '/') window.history.replaceState(null, '', '/admin/login');
    if (signedIn && window.location.pathname === '/admin/login') window.history.replaceState(null, '', '/');
  }, [loading, signedIn]);
  const navigation = [['overview', '/', 'Website overview', '◫'], ['partners', '/admin/partners', 'Partner applications', '♧'], ['packages', '/admin/packages', 'Tour packages', '▤'], ['activity', '/admin/activity', 'Website activity', '↗']];
  const title = navigation.find(([key]) => key === view)?.[2] || 'Website overview';
  return <div className={'admin-workspace' + (!signedIn ? ' admin-auth-page' : '')}>
    <aside className="admin-sidebar" hidden={!signedIn}><a className="admin-brand" href="/"><span>T</span>TripRaft<small>ADMINISTRATION</small></a>
      <p>CONTROL CENTER</p><nav aria-label="Administration navigation">{navigation.map(([key, target, text, icon]) => <a key={key} className={view === key ? 'active' : undefined} aria-current={view === key ? 'page' : undefined} href={target}>{icon} <span>{text}</span></a>)}<a href="/access-administration">◇ <span>Employee administration</span></a></nav>
      <div className="admin-sidebar-bottom"><p>EMPLOYEE WORKSPACE</p><a href="/employee-access">Employee portal <span>↗</span></a><small>Personal access, permissions, and requests.<br />Separate from website administration.</small></div>
    </aside>
    <header className="admin-auth-header" hidden={signedIn}><a href="/admin/login">TripRaft <small>ADMINISTRATION</small></a><a href="/employee-access/login">Employee sign in ↗</a></header>
    <div className="admin-canvas"><div className="admin-topbar" hidden={!signedIn}><span>Organization <b>/</b> Administration</span><span className="admin-restricted">{import.meta.env.VITE_ADMIN_LOCAL_DEMO ? 'Local demo · ' : ''}{email}</span></div>
      <div className="admin-introduction" hidden={!signedIn}><p>WEBSITE CONTROL CENTER</p><h1>{title}</h1><span>{view === 'overview' ? 'An overview of website services and operational workspaces.' : 'Review and manage this part of website operations.'}</span></div>
      <div className="admin-capabilities" hidden={!signedIn || view !== 'overview'}>{navigation.slice(1).map(([key, target, text, icon]) => <a key={key} href={target}><span className="admin-capability-icon">{icon}</span><div><strong>{text}</strong><small>Open workspace</small></div><span>↗</span></a>)}</div>
      <div className="admin-page-content">{children}</div>
      {signedIn && view === 'activity' && <section className="admin-analytics-status"><span>WEBSITE INSIGHTS</span><h2>Click & visitor analytics</h2><p>Not configured in this build. Page views, clicks, visitor counts, and conversion reports are not currently collected. Ingestion logs describe operational imports, not visitor behavior.</p></section>}
      <footer className="admin-footer">TripRaft Administration <span>{signedIn ? 'Controlled access. Clear accountability.' : 'For explicitly authorized website administrators.'}</span></footer>
    </div>
  </div>;
}
