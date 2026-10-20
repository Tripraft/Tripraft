// Purpose: Runs tests/*.test.jsx in jsdom with Babel transforms and Testing Library DOM assertions.
module.exports = { testEnvironment: 'jsdom', setupFilesAfterEnv: ['@testing-library/jest-dom'], transform: { '^.+\\.[jt]sx?$': 'babel-jest' }, testMatch: ['**/tests/**/*.test.jsx'], clearMocks: true };
