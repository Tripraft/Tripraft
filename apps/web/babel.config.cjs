// Purpose: Compiles JSX and TypeScript for Jest and applies tests/viteEnvTransform.cjs to Vite environment expressions.
module.exports = {
  env: { test: { plugins: [require('./tests/viteEnvTransform.cjs')] } },
  presets: [
    ['@babel/preset-env', { targets: { node: 'current' } }],
    ['@babel/preset-react', { runtime: 'automatic' }],
    ['@babel/preset-typescript', { allExtensions: true, isTSX: true }],
  ],
};
