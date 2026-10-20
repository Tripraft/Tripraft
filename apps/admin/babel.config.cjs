// Purpose: Compiles JavaScript, React JSX and TypeScript for Jest, replacing import.meta.env through tests/viteEnvTransform.cjs.
module.exports = {
  env: { test: { plugins: [require('./tests/viteEnvTransform.cjs')] } },
  presets: [ ['@babel/preset-env', { targets: { node: 'current' } }], ['@babel/preset-react', { runtime: 'automatic' }], '@babel/preset-typescript' ],
};
