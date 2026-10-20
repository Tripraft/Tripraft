// Purpose: Mounts App in React StrictMode, loads staff-console styles, and fails explicitly if the HTML root is missing.
import React from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App';
import './styles.css';
const root = document.getElementById('root');
if (!root) throw new Error('Missing application root');
createRoot(root).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
