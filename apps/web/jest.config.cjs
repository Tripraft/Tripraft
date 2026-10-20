// Purpose: Configures jsdom, Babel, test discovery, shared Toast resolution, source aliases, and CSS/SVG mocks.
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/src/setupTests.js'],
  moduleNameMapper: {
    '^@tripraft/ui/Toast$': '<rootDir>/../../packages/ui/src/Toast.jsx',
    '^@/(.*)$': '<rootDir>/src/$1',
    '\\.(css|svg)$': '<rootDir>/tests/styleMock.cjs',
  },
  transform: { '^.+\\.(js|jsx|ts|tsx)$': 'babel-jest' },
  testMatch: ['**/__tests__/**/*.test.[jt]s?(x)'],
  moduleFileExtensions: ['js', 'jsx', 'ts', 'tsx', 'json'],
  clearMocks: true,
};
