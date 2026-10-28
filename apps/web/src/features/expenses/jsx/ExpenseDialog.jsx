// Purpose: Provides a portalled expense dialog with focus containment, Escape handling, scroll locking and focus restoration.
import React, { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import '../css/ExpenseDialog.css';
import usePreventNumberWheel from '../../../hooks/usePreventNumberWheel';

let openDialogs = 0;
let previousOverflow = '';

export default function ExpenseDialog({ children, label, onClose, busy = false, className = '' }) {
  const surface = useRef(null);
  usePreventNumberWheel(surface);
  const closeRef = useRef(onClose);
  const busyRef = useRef(busy);
  closeRef.current = onClose;
  busyRef.current = busy;
  useEffect(() => {
    const previousFocus = document.activeElement;
    if (openDialogs++ === 0) { previousOverflow = document.body.style.overflow; document.body.style.overflow = 'hidden'; }
    const controls = () => [...surface.current.querySelectorAll('button:not(:disabled), input:not(:disabled), select:not(:disabled), textarea:not(:disabled), [tabindex="0"]')]
      .filter(element => !element.hidden && element.getAttribute('aria-hidden') !== 'true');
    (surface.current.querySelector('input:not(:disabled)') || controls()[0] || surface.current).focus();
    const onKey = event => {
      const layers = document.querySelectorAll('.expense-dialog-layer');
      if (layers[layers.length - 1] !== surface.current?.parentElement) return;
      if (event.key === 'Escape' && !busyRef.current) { event.preventDefault(); event.stopPropagation(); closeRef.current?.(); }
      if (event.key !== 'Tab') return;
      const focusable = controls(), first = focusable[0], last = focusable[focusable.length - 1];
      if (!first) { event.preventDefault(); surface.current.focus(); }
      else if (event.shiftKey && (document.activeElement === first || document.activeElement === surface.current)) { event.preventDefault(); last.focus(); }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
    };
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('keydown', onKey);
      if (--openDialogs === 0) document.body.style.overflow = previousOverflow;
      if (previousFocus?.isConnected) previousFocus.focus();
    };
  }, []);
  return createPortal(<div className="expense-dialog-layer" onClick={event => {
    if (event.target === event.currentTarget && !busy) onClose?.();
  }}><section ref={surface} role="dialog" aria-modal="true" aria-label={label} tabIndex={-1}
    className={`expense-dialog-surface ${className}`}>{children}</section></div>, document.body);
}
