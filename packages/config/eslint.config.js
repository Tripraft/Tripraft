// Purpose: Shares the TypeScript-capable parser and four critical error rules across workspaces, ignoring dependency/build output and generated declarations.
import tseslint from 'typescript-eslint';
export default [
  { ignores: ['dist/**', 'node_modules/**', 'src/generated/**'] },
  {
    files: ['**/*.{js,jsx,ts,tsx,cjs,mjs}'],
    languageOptions: { parser: tseslint.parser, parserOptions: { ecmaVersion: 'latest', sourceType: 'module', ecmaFeatures: { jsx: true } } },
    rules: { 'no-unreachable': 'error', 'no-dupe-keys': 'error', 'no-unsafe-finally': 'error', 'valid-typeof': 'error' }
  }
];
