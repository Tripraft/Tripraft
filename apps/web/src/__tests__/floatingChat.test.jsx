import React, {useState} from 'react';
import {act, fireEvent, render, screen} from '@testing-library/react';
import useFloatingPosition from '../features/trips/hooks/useFloatingPosition';

function FloatingChat() {
  const floating = useFloatingPosition('test-chat-position');
  const [open, setOpen] = useState(false);
  return <div ref={floating.ref} style={floating.style} data-testid="panel">
    <button {...floating.handle} onClick={() => setOpen(!open)}>Move chat</button>
    <input aria-label="Message" />
    <button onClick={floating.reset}>Reset</button>
    <output>{open ? 'Open' : 'Closed'}</output>
  </div>;
}

beforeEach(() => {
  localStorage.clear();
  Object.defineProperty(window, 'innerWidth', {configurable:true, value:1000});
  Object.defineProperty(window, 'innerHeight', {configurable:true, value:800});
  jest.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockImplementation(function () {
    return {left:parseFloat(this.style.left) || 500, top:parseFloat(this.style.top) || 100, width:300, height:400};
  });
  // jsdom has no native PointerEvent; retain mouse coordinates for pointer tests.
  window.PointerEvent = MouseEvent;
});
afterEach(() => jest.restoreAllMocks());

it('drags the panel, clamps it inside the screen and suppresses the launcher click after a drag', () => {
  render(<FloatingChat/>);
  const handle = screen.getByRole('button', {name:'Move chat'});
  fireEvent.pointerDown(handle, {button:0, clientX:520, clientY:110});
  fireEvent.pointerMove(handle, {clientX:-100, clientY:1000});
  fireEvent.pointerUp(handle);
  fireEvent.click(handle);
  expect(screen.getByTestId('panel')).toHaveStyle({left:'8px', top:'392px'});
  expect(screen.getByText('Closed')).toBeInTheDocument();
  expect(JSON.parse(localStorage.getItem('test-chat-position'))).toEqual({x:8,y:392});
});

it('supports normal clicks, keyboard movement, saved positions, resize and reset', () => {
  localStorage.setItem('test-chat-position', JSON.stringify({x:600,y:300}));
  render(<FloatingChat/>);
  const handle = screen.getByRole('button', {name:'Move chat'});
  fireEvent.click(handle);
  expect(screen.getByText('Open')).toBeInTheDocument();
  fireEvent.keyDown(handle, {key:'ArrowLeft', shiftKey:true});
  expect(screen.getByTestId('panel')).toHaveStyle({left:'560px'});
  Object.defineProperty(window, 'innerWidth', {configurable:true, value:400});
  act(() => window.dispatchEvent(new Event('resize')));
  expect(screen.getByTestId('panel')).toHaveStyle({left:'92px'});
  fireEvent.click(screen.getByRole('button', {name:'Reset'}));
  expect(screen.getByTestId('panel').style.left).toBe('');
  expect(localStorage.getItem('test-chat-position')).toBeNull();
});

it('keeps message input interactions separate from dragging and tolerates broken saved preferences', () => {
  localStorage.setItem('test-chat-position', '{broken');
  render(<FloatingChat/>);
  fireEvent.change(screen.getByLabelText('Message'), {target:{value:'Hello'}});
  expect(screen.getByLabelText('Message')).toHaveValue('Hello');
  expect(screen.getByTestId('panel').style.left).toBe('');
});
