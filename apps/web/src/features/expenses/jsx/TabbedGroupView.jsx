// Purpose: Composes balances, settlements, member spending, transaction history and analysis into the group expense tabs.
/**
 * TabbedGroupView Component
 * Displays Group Balances, Settle Up, Member Spending, Transaction History, and Analytics as tabs
 */

import React, { useState } from 'react';
import { Scale, TrendingUp, Receipt, Handshake, BarChart3, Users } from 'lucide-react';
import GroupBalances from './GroupBalances';
import MemberSpending from './MemberSpending';
import TransactionList from './TransactionList';
import ExpenseAnalytics from './ExpenseAnalytics';
import SettlementView from './SettlementView';

const TabbedGroupView = ({
  group,
  balances,
  members,
  allMembersMap,
  onBalanceUpdate,
  settlementHistory,
  onSettlementSuccess,
  onSettlementDelete,
  transactions,
  filter,
  onFilterChange,
  activeGroupMembers,
  currentUserId,
  onEdit,
  onDelete,
  onRestore,
  onExportPDF,
  membersContent,
  activeTab: selectedTab,
  onTabChange
}) => {
  const [localTab, setLocalTab] = useState('balances');
  const activeTab = selectedTab ?? localTab;
  const setActiveTab = onTabChange || setLocalTab;

  const tabs = [
    {
      id: 'balances',
      label: 'Balances',
      icon: Scale,
      color: '#667eea'
    },
    {
      id: 'settleup',
      label: 'Settle Up',
      icon: Handshake,
      color: '#10b981'
    },
    {
      id: 'spending',
      label: 'Member Spending',
      icon: TrendingUp,
      color: '#f59e0b'
    },
    {
      id: 'transactions',
      label: 'Activity & history',
      icon: Receipt,
      color: '#3b82f6'
    },
    {
      id: 'analytics',
      label: 'Analytics',
      icon: BarChart3,
      color: '#8b5cf6'
    },
    ...(membersContent ? [{ id: 'members', label: 'Members', icon: Users, color: '#7c3aed' }] : [])
  ];

  return (
    <div className="expense-group-tabs" style={{
      background: 'white',
      borderRadius: '12px',
      border: '1px solid #e5e7eb',
      overflow: 'hidden',
      boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
      marginBottom: '1.5rem'
    }}>
      {/* Tab Headers */}
      <div className="expense-group-tablist" role="tablist" aria-label="Group details" style={{
        display: 'flex',
        borderBottom: '1px solid #e5e7eb',
        background: '#f9fafb'
      }}>
        {tabs.map(tab => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          
          return (
            <button
              key={tab.id}
              role="tab"
              id={`group-tab-${tab.id}`}
              aria-selected={isActive}
              aria-controls="group-detail-panel"
              tabIndex={isActive ? 0 : -1}
              onKeyDown={event => {
                if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
                event.preventDefault();
                const index = tabs.findIndex(item => item.id === activeTab);
                const next = event.key === 'Home' ? 0 : event.key === 'End' ? tabs.length - 1
                  : (index + (event.key === 'ArrowRight' ? 1 : -1) + tabs.length) % tabs.length;
                setActiveTab(tabs[next].id);
                document.getElementById(`group-tab-${tabs[next].id}`)?.focus();
              }}
              onClick={() => setActiveTab(tab.id)}
              style={{
                flex: 1,
                padding: '1rem',
                border: 'none',
                background: isActive ? 'white' : 'transparent',
                color: isActive ? '#111827' : '#6b7280',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '0.75rem',
                fontSize: '0.95rem',
                fontWeight: isActive ? '600' : '500',
                transition: 'all 0.2s ease',
                borderBottom: isActive ? `3px solid ${tab.color}` : 'none',
                position: 'relative',
                top: isActive ? '1px' : '0'
              }}
            >
              <Icon size={18} style={{ color: tab.color }} />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* Tab Content */}
      <div className="expense-group-tabpanel" id="group-detail-panel" role="tabpanel" aria-labelledby={`group-tab-${activeTab}`} tabIndex={0} style={{ padding: '1.5rem' }}>
        {activeTab === 'members' && membersContent}
        {/* Group Balances Tab */}
        {activeTab === 'balances' && (
          <div style={{ animation: 'fadeIn 0.3s ease' }}>
            <GroupBalances
              group={group}
              balances={balances}
              members={members}
              allMembersMap={allMembersMap}
              onBalanceUpdate={onBalanceUpdate}
              settlementHistory={settlementHistory}
              onSettlementSuccess={onSettlementSuccess}
              onSettlementDelete={onSettlementDelete}
              currentUserId={currentUserId}
              showSettleUp={false}
            />
          </div>
        )}

        {/* Settle Up Tab - Shows suggested settlements with action buttons */}
        {activeTab === 'settleup' && (
          <div style={{ animation: 'fadeIn 0.3s ease' }}>
            <SettlementView
              group={group}
              balances={balances}
              members={members}
              allMembersMap={allMembersMap}
              settlementHistory={settlementHistory}
              onSettlementSuccess={onSettlementSuccess}
              onSettlementDelete={onSettlementDelete}
              currentUserId={currentUserId}
              currency={group?.currency || 'USD'}
              displayCurrency={group?.display_currency || group?.currency || 'USD'}
            />
          </div>
        )}

        {/* Member Spending Tab */}
        {activeTab === 'spending' && (
          <div style={{ animation: 'fadeIn 0.3s ease' }}>
            <MemberSpending
              expenses={transactions || []}
              members={activeGroupMembers || []}
              currency={group?.currency || 'USD'}
              displayCurrency={group?.display_currency || group?.currency || 'USD'}
              currentUserId={currentUserId}
            />
          </div>
        )}

        {/* Transaction History Tab */}
        {activeTab === 'transactions' && (
          <div className="expense-activity-tab">
            <div className="expense-activity-filters">
              <div style={{ 
                display: 'flex', 
                gap: '1rem',
                marginBottom: '1rem',
                flexWrap: 'wrap'
              }}>
                <select 
                  value={filter.category || 'all'}
                  onChange={(e) => onFilterChange('category', e.target.value)}
                  style={{
                    padding: '0.5rem 1rem',
                    borderRadius: '8px',
                    border: '1px solid #e5e7eb',
                    background: 'white',
                    fontSize: '0.875rem',
                    color: '#374151',
                    cursor: 'pointer'
                  }}
                >
                  <option value="all">All Categories</option>
                  <option value="Food">Food</option>
                  <option value="Transport">Transport</option>
                  <option value="Shopping">Shopping</option>
                  <option value="Entertainment">Entertainment</option>
                  <option value="Utilities">Utilities</option>
                  <option value="Healthcare">Healthcare</option>
                  <option value="Education">Education</option>
                  <option value="Accommodation">Accommodation</option>
                  <option value="Travel">Travel</option>
                  <option value="Salary">Salary</option>
                  <option value="Income">Income</option>
                  <option value="Other">Other</option>
                </select>
                <select 
                  value={filter.sortBy}
                  onChange={(e) => onFilterChange('sortBy', e.target.value)}
                  style={{
                    padding: '0.5rem 1rem',
                    borderRadius: '8px',
                    border: '1px solid #e5e7eb',
                    background: 'white',
                    fontSize: '0.875rem',
                    color: '#374151',
                    cursor: 'pointer'
                  }}
                >
                  <option value="date-desc">Date (Newest)</option>
                  <option value="date-asc">Date (Oldest)</option>
                  <option value="amount-desc">Amount (High-Low)</option>
                  <option value="amount-asc">Amount (Low-High)</option>
                </select>
              </div>
            </div>
            <TransactionList
              transactions={transactions}
              filter={filter}
              mode="group"
              activeGroup={group}
              members={activeGroupMembers || []}
              allMembersMap={allMembersMap}
              currentUserId={currentUserId}
              onEdit={onEdit}
              onDelete={onDelete}
              onRestore={onRestore}
              onFilterChange={onFilterChange}
              currency={group?.currency || 'USD'}
              displayCurrency={group?.display_currency || group?.currency || 'USD'}
              isInTab={true}
            />
          </div>
        )}

        {/* Analytics Tab */}
        {activeTab === 'analytics' && (
          <div style={{ animation: 'fadeIn 0.3s ease' }}>
            <ExpenseAnalytics
              expenses={transactions || []}
              members={activeGroupMembers || []}
              currency={group?.currency || 'USD'}
              displayCurrency={group?.display_currency || group?.currency || 'USD'}
              mode="group"
              currentUserId={currentUserId}
              groupName={group?.name}
              settlements={settlementHistory || []}
              onExportPDF={onExportPDF}
            />
          </div>
        )}
      </div>

      <style>{`
        @keyframes fadeIn {
          from {
            opacity: 0;
            transform: translateY(4px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
      `}</style>
    </div>
  );
};

export default TabbedGroupView;
