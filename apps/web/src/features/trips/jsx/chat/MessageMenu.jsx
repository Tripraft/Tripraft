// Purpose: Provides an inline message action menu for permitted edit/delete operations, with outside-click and Escape dismissal.
import React, { useEffect, useRef, useState } from 'react';
import { MoreHorizontal, Pencil, Trash2 } from 'lucide-react';

export default function MessageMenu({ canEdit, onEdit, onDelete, disabled }) {
  const [open, setOpen] = useState(false);
  const [below, setBelow] = useState(false);
  const root = useRef(null);
  const trigger = useRef(null);
  useEffect(() => {
    if (!open) return;
    const close = event => {
      if (event.type === 'keydown' && event.key === 'Escape') {
        setOpen(false);
        trigger.current?.focus();
      } else if (event.type === 'pointerdown' && !root.current?.contains(event.target)) setOpen(false);
    };
    document.addEventListener('pointerdown', close);
    document.addEventListener('keydown', close);
    root.current?.querySelector('[role="menuitem"]')?.focus();
    return () => { document.removeEventListener('pointerdown', close); document.removeEventListener('keydown', close); };
  }, [open]);
  return <div className="gp-message-menu" ref={root}>
    <button className="gp-icon-button" ref={trigger} aria-label="Message options" aria-haspopup="menu" aria-expanded={open} disabled={disabled} onClick={() => {
      const feed = root.current?.closest('.gp-chat-feed');
      setBelow(Boolean(feed && root.current.getBoundingClientRect().top - feed.getBoundingClientRect().top < 100));
      setOpen(value => !value);
    }}><MoreHorizontal size={17}/></button>
    {open && <div role="menu" aria-label="Message actions" className={below ? 'gp-menu-below' : ''} onKeyDown={event => {
      const buttons = [...event.currentTarget.querySelectorAll('[role="menuitem"]')];
      const current = buttons.indexOf(document.activeElement);
      if (['ArrowDown', 'ArrowUp', 'Home', 'End'].includes(event.key)) {
        event.preventDefault();
        const next = event.key === 'Home' ? 0 : event.key === 'End' ? buttons.length - 1 : (current + (event.key === 'ArrowDown' ? 1 : -1) + buttons.length) % buttons.length;
        buttons[next]?.focus();
      }
      if (event.key === 'Tab') setOpen(false);
    }}>
      {canEdit && <button role="menuitem" onClick={() => { setOpen(false); onEdit(); }}><Pencil size={14}/>Edit</button>}
      <button role="menuitem" onClick={() => { setOpen(false); onDelete(); }}><Trash2 size={14}/>Delete</button>
    </div>}
  </div>;
}
