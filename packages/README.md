# Shared packages developer guide

Reviewed on 2026-10-20. This directory contains **19 shared-package files**, plus this guide (20 files total), used through the pnpm workspace. Paths in the file table are relative to `packages/`.

## Package responsibilities

| Workspace package | Public entry | Responsibility and current consumers |
|---|---|---|
| `@tripraft/api-client` | `src/index.ts` | Typed cookie/CSRF client and generated API declarations; used by the staff console. |
| `@tripraft/config` | `/eslint`, `/tsconfig`, `/prettier` | Shared lint/compiler/formatting settings for packages and applications. |
| `@tripraft/types` | `src/index.ts` | Handwritten account, response-envelope, partner and private-package contracts; used by web, staff and the typed API client. |
| `@tripraft/ui` | `/Toast` | Shared React notification component and imported styles; used by the traveler app. |

The packages expose source/configuration entries rather than built `dist/` bundles. `workspace:*` dependencies resolve locally through the [workspace definition](../pnpm-workspace.yaml). Each manifest's description explains its package; source files have specific `Purpose:` comments. Strict JSON is explained here without inserting invalid comments. Generated declarations retain their generator-owned header and content.

## File index

| File | What it does |
|---|---|
| [api-client/eslint.config.js](api-client/eslint.config.js) | Re-exports the shared critical JavaScript/TypeScript lint configuration for the typed API client; generated declarations are excluded by that configuration. |
| [api-client/package.json](api-client/package.json) | Declares the typed API-client entry, openapi-fetch/runtime and workspace dependencies, and OpenAPI generation, lint and typecheck commands. |
| [api-client/src/generated/schema.d.ts](api-client/src/generated/schema.d.ts) | Contains generated OpenAPI paths, operations and component types from services/api/openapi.json; regenerate with the package command instead of hand-editing declarations. |
| [api-client/src/index.ts](api-client/src/index.ts) | Creates a typed openapi-fetch client with cookie credentials and mutation CSRF headers, and re-exports generated/shared types without adding retries or session refresh. |
| [api-client/tsconfig.json](api-client/tsconfig.json) | Extends shared TypeScript settings and includes src/**/*.ts for checking the client and generated declarations without emitting JavaScript. |
| [config/eslint.config.js](config/eslint.config.js) | Shares the TypeScript-capable parser and four critical error rules across workspaces, ignoring dependency/build output and generated declarations. |
| [config/package.json](config/package.json) | Exports the shared ESLint, TypeScript and Prettier configuration entry points for workspace packages and applications. |
| [config/prettier.json](config/prettier.json) | Defines shared formatting preferences: single quotes where supported, trailing commas where supported, and a print width of 100. |
| [config/tsconfig.json](config/tsconfig.json) | Defines strict ES2022/browser TypeScript checking with bundler module resolution, React JSX and no emit; JavaScript is allowed but checkJs is disabled. |
| [types/eslint.config.js](types/eslint.config.js) | Re-exports shared critical syntax/error lint rules for the handwritten domain contract package. |
| [types/package.json](types/package.json) | Exports handwritten domain types from src/index.ts and declares shared configuration plus lint/typecheck commands; the package has no runtime dependency list. |
| [types/src/index.ts](types/src/index.ts) | Exports UUID/Money aliases, API envelopes, account/health contracts and partner/package types; these declarations provide compile-time contracts, not runtime validation. |
| [types/src/partners.ts](types/src/partners.ts) | Defines partner application/review states, capability snapshots, agreement document/signature evidence and version/hash-bound signing inputs for web and staff consumers. |
| [types/src/tourDrafts.ts](types/src/tourDrafts.ts) | Defines private package content, itinerary days, exact string minor-unit rate proposals, media, review states and paginated draft/review responses. |
| [types/tsconfig.json](types/tsconfig.json) | Extends shared TypeScript settings and includes handwritten src/**/*.ts domain declarations for no-emit type checking. |
| [ui/eslint.config.js](ui/eslint.config.js) | Re-exports shared critical JavaScript/JSX lint rules for reusable UI components. |
| [ui/package.json](ui/package.json) | Exports @tripraft/ui/Toast, preserves imported CSS as a side effect, and declares React/lucide-react peer dependencies plus the UI lint command. |
| [ui/src/Toast.jsx](ui/src/Toast.jsx) | Renders success/error/info notifications with icons and manual close, schedules onClose for positive durations, and clears the timer when its effect resets or unmounts. |
| [ui/src/styles/Toast.css](ui/src/styles/Toast.css) | Styles fixed-position Toast notifications, slide-in animation, status colors and close controls, with a full-width mobile layout. |

## Typed API client

Import `createApiClient` from `@tripraft/api-client`. Its generated route keys already include `/api`, so the default empty base works with the local proxy; a separate-host deployment supplies an API origin. Do not append another `/api` to the base for these route keys.

```ts
import { createApiClient } from '@tripraft/api-client';

const api = createApiClient('');
const { data, error, response } = await api.GET('/api/v1/auth/me');
```

The wrapper sets `credentials: 'include'` and adds the readable `csrf_token` cookie value to `X-CSRF-Token` for unsafe HTTP methods when `document` exists. It does not add automatic retries or refresh a session. Callers must handle failed responses, and the server remains responsible for authentication and authorization.

The generated file exports `paths`, `webhooks`, `components`, `$defs` and `operations`; the package entry re-exports `paths` and `components`. The declaration file comes from [the API schema](../services/api/openapi.json), not from inferred frontend behavior. Payloads that are unspecified in that schema remain unknown.

When API contracts intentionally change, regenerate from the repository root:

```powershell
python infra/tools/export_openapi.py
pnpm --filter @tripraft/api-client generate
```

The exporter writes the API schema using a disposable migrated SQLite database; the package generator rewrites `src/generated/schema.d.ts`. Review both generated changes together. Do not add handwritten descriptions or type patches inside the generated file.

## Shared domain types

`@tripraft/types` contains handwritten contracts in addition to the generated API declarations. Update consumers and backend contracts together when changing their shape. TypeScript checks these definitions during development; they do not validate network payloads at runtime.

- `UUID` is a string alias; it does not perform UUID validation.
- `Money` is a number alias without an attached currency or precision guarantee.
- Supplier proposal amounts use `supplier_rate_minor: string` with a separate currency exponent so exact values are not coerced into floating-point numbers.
- Partner application versions, agreement hashes, signature state and package revision fields carry workflow context. UI capability fields do not replace server authorization.

## Shared configuration

The ESLint preset uses `typescript-eslint` to parse JavaScript, JSX and TypeScript. Its current enforced rules are `no-unreachable`, `no-dupe-keys`, `no-unsafe-finally` and `valid-typeof`. It is not a full formatting or React Hooks rule set. Dependency/build output and generated declarations are ignored.

The TypeScript preset targets ES2022 and browser libraries, uses bundler resolution and React JSX, enables strict checking, and emits no output. `allowJs: true` permits JavaScript imports while `checkJs: false` leaves those JavaScript files unchecked; `skipLibCheck: true` skips declaration-file checking. Each consumer's `include`/`exclude` settings determine its actual source coverage.

The Prettier preset sets single quotes, trailing commas where supported and a print width of 100. The [root Prettier entry](../prettier.config.cjs) loads it. These settings apply when the formatter is run; importing the ESLint preset does not automatically format code.

## Shared Toast component

```jsx
import Toast from '@tripraft/ui/Toast';

<Toast message="Changes saved" type="success" duration={3000} onClose={dismiss} />
```

`message` supplies content; `type` selects `success`, `error` or `info` styling/icons. `onClose` handles manual and automatic dismissal. A positive `duration` starts the timer; zero or a negative duration disables automatic dismissal. The effect clears its timer when unmounting or when `duration`/`onClose` changes. Changing only `message` does not restart that timer, so consumers should choose callback identity and remounting behavior deliberately.

React and `lucide-react` are peer dependencies supplied by the consuming app. Toast imports its CSS directly, and the manifest preserves CSS imports as side effects. Mobile positioning is defined in the stylesheet. Keep additional components and package exports intentional; the current public UI entry is `/Toast`.

## Validation and commits

Run from the repository root with workspace dependencies installed:

```powershell
pnpm --filter @tripraft/api-client lint
pnpm --filter @tripraft/api-client typecheck
pnpm --filter @tripraft/types lint
pnpm --filter @tripraft/types typecheck
pnpm --filter @tripraft/ui lint
```

The config package has no package-level scripts, and UI currently has lint only. Check affected application type/build behavior when runtime contracts or UI behavior change. For comment/description changes, verify source equivalence, unchanged dependency/export/script values, JSON validity, guide links and generated-file preservation.

Use a separate commit with a specific description for each updated file, matching the owning package. GitHub's file-list column shows that commit's subject; the guide above explains all files, including JSON settings and generated output that may not need a content change. Do not create meaningless edits to generated/configuration files solely to change their displayed history.
