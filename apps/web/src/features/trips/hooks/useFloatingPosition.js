import {useEffect, useRef, useState} from 'react';

const gap = 8;
const viewport = () => ({
  x: window.visualViewport?.offsetLeft || 0,
  y: window.visualViewport?.offsetTop || 0,
  width: window.visualViewport?.width || window.innerWidth,
  height: window.visualViewport?.height || window.innerHeight,
});

export default function useFloatingPosition(storageKey, visible = true) {
  const ref = useRef(null), drag = useRef(null), suppressClick = useRef(false);
  const [bounds, setBounds] = useState(viewport);
  const [moving, setMoving] = useState(false);
  const [position, setPosition] = useState(() => {
    try {
      const value = JSON.parse(localStorage.getItem(storageKey));
      return Number.isFinite(value?.x) && Number.isFinite(value?.y) ? value : null;
    } catch {return null;}
  });
  const positionRef = useRef(position);
  const clamp = point => {
    const box = ref.current?.getBoundingClientRect(), view = viewport();
    return {
      x: Math.max(view.x + gap, Math.min(point.x, view.x + view.width - (box?.width || 0) - gap)),
      y: Math.max(view.y + gap, Math.min(point.y, view.y + view.height - Math.min(box?.height || 0, view.height - gap * 2) - gap)),
    };
  };
  const move = point => {
    const next = clamp(point);
    positionRef.current = next;
    setPosition(next);
    return next;
  };
  const persist = () => {
    try {localStorage.setItem(storageKey, JSON.stringify(positionRef.current));} catch { /* Optional preference storage. */ }
  };
  useEffect(() => {
    if (!visible) return;
    const fit = () => {
      setBounds(viewport());
      if (positionRef.current) {
        const next = clamp(positionRef.current);
        positionRef.current = next;
        setPosition(next);
      }
    };
    fit();
    window.addEventListener('resize', fit);
    window.visualViewport?.addEventListener('resize', fit);
    window.visualViewport?.addEventListener('scroll', fit);
    const observer = typeof ResizeObserver !== 'undefined' ? new ResizeObserver(fit) : null;
    if (ref.current) observer?.observe(ref.current);
    return () => {
      window.removeEventListener('resize', fit);
      window.visualViewport?.removeEventListener('resize', fit);
      window.visualViewport?.removeEventListener('scroll', fit);
      observer?.disconnect();
    };
  }, [visible]);

  const finish = event => {
    if (drag.current?.id !== event.pointerId) return;
    drag.current = null;
    setMoving(false);
    persist();
    if (event.currentTarget.hasPointerCapture?.(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId);
  };
  return {
    ref,
    moving,
    style: {
      maxHeight: Math.max(80, bounds.height - gap * 2),
      ...(position ? {left: position.x, top: position.y, right: 'auto', bottom: 'auto'} : {}),
    },
    reset: () => {
      positionRef.current = null;
      setPosition(null);
      try {localStorage.removeItem(storageKey);} catch { /* Optional preference storage. */ }
    },
    handle: {
      onPointerDown: event => {
        if (event.button !== 0 || event.isPrimary === false) return;
        const box = ref.current?.getBoundingClientRect();
        if (!box) return;
        suppressClick.current = false;
        drag.current = {id: event.pointerId, x: event.clientX, y: event.clientY, left: box.left, top: box.top};
        event.currentTarget.setPointerCapture?.(event.pointerId);
      },
      onPointerMove: event => {
        const origin = drag.current;
        if (!origin || origin.id !== event.pointerId) return;
        const dx = event.clientX - origin.x, dy = event.clientY - origin.y;
        if (!suppressClick.current && Math.hypot(dx, dy) < 4) return;
        suppressClick.current = true;
        setMoving(true);
        move({x: origin.left + dx, y: origin.top + dy});
      },
      onPointerUp: finish,
      onPointerCancel: finish,
      onLostPointerCapture: finish,
      onClickCapture: event => {
        if (suppressClick.current) {
          event.preventDefault();
          event.stopPropagation();
          suppressClick.current = false;
        }
      },
      onKeyDown: event => {
        const direction = {ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1]}[event.key];
        if (!direction) return;
        event.preventDefault();
        const box = ref.current?.getBoundingClientRect();
        if (!box) return;
        const step = event.shiftKey ? 40 : 10;
        move({x: box.left + direction[0] * step, y: box.top + direction[1] * step});
        persist();
      },
    },
  };
}
