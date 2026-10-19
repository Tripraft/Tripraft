# Purpose: Build the existing web app and serve it with Flask at one HTTPS origin.
FROM node:22-bookworm-slim AS web
WORKDIR /src
RUN npm install --global pnpm@10.34.6
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json ./
COPY packages ./packages
COPY apps/web ./apps/web
COPY apps/admin/package.json ./apps/admin/package.json
COPY services/api/package.json ./services/api/package.json
ENV VITE_API_BASE_URL=/api
RUN pnpm install --frozen-lockfile && pnpm --filter @tripraft/web build

FROM python:3.11-slim-bookworm
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 FLASK_ENV=production \
    FRONTEND_DIST_DIR=/opt/tripraft/apps/web/dist TRIPRAFT_ROOT=/opt/tripraft
WORKDIR /opt/tripraft
COPY services/api/requirements.txt ./services/api/requirements.txt
RUN pip install --no-cache-dir -r services/api/requirements.txt
COPY services/api ./services/api
COPY data/catalog/tripraft-canonical.db data/catalog/tripraft_places.db ./data/catalog/
COPY infra/remote-beta/start_beta.py ./infra/remote-beta/start_beta.py
COPY --from=web /src/apps/web/dist ./apps/web/dist
RUN groupadd --system tripraft && useradd --system --gid tripraft tripraft \
    && mkdir -p /opt/tripraft/data/runtime /opt/tripraft/services/api/uploads \
    && chown -R tripraft:tripraft /opt/tripraft
USER tripraft
CMD ["python", "infra/remote-beta/start_beta.py"]
