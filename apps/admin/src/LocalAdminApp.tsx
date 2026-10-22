import type { ComponentType } from 'react';
import { EmployeeAccessApp } from './EmployeeAccessApp';

export function LocalAdminApp({ StaffApp }: { StaffApp: ComponentType }) {
  const employee = /^\/employee-access(?:\/|$)/.test(window.location.pathname);
  const administration = /^\/access-administration(?:\/|$)/.test(window.location.pathname);
  return employee || administration ? <EmployeeAccessApp administration={administration} /> : <StaffApp />;
}
