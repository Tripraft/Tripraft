import React from 'react';
import { cleanup, render, screen } from '@testing-library/react';
import { LocalAdminApp } from '../src/LocalAdminApp';

jest.mock('../src/EmployeeAccessApp', () => ({ EmployeeAccessApp: () => <p>Employee dashboard view</p> }));
jest.mock('../src/adminWorkspace.css', () => ({}));
const StaffApp = () => <p>Original staff view</p>;
afterEach(() => { cleanup(); window.history.replaceState({}, '', '/'); });

test('staff console includes a link to the employee portal on the same origin', () => {
  render(<LocalAdminApp StaffApp={StaffApp} />);
  expect(screen.getByText('Original staff view')).toBeInTheDocument();
  expect(screen.queryByText('Employee dashboard view')).not.toBeInTheDocument();
});

test('employee route shows the portal with a link back to the original staff console', () => {
  window.history.replaceState({}, '', '/employee-access');
  render(<LocalAdminApp StaffApp={StaffApp} />);
  expect(screen.getByText('Employee dashboard view')).toBeInTheDocument();
  expect(screen.queryByText('Original staff view')).not.toBeInTheDocument();
});
