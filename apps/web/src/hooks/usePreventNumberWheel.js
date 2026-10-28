// Purpose: Prevents focused numeric inputs from stepping on a wheel while retaining keyboard editing.
import {useEffect} from 'react';

export default function usePreventNumberWheel(surface) {
  useEffect(() => {
    const element = surface.current;
    if (!element) return;
    const stop = event => {
      if (event.target instanceof HTMLInputElement && event.target.type === 'number' && event.target === document.activeElement) event.preventDefault();
    };
    element.addEventListener('wheel', stop, {passive: false});
    return () => element.removeEventListener('wheel', stop);
  }, [surface]);
}
