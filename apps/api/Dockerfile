# HB Trade API. Runs migrations + seed then the API (see docker-compose command).
FROM node:20-slim
WORKDIR /app

# workspace manifests first for layer caching
COPY package.json package-lock.json* ./
COPY apps/api/package.json apps/api/package.json
COPY apps/web/package.json apps/web/package.json
RUN npm install --workspace @hb/api --include-workspace-root

# source
COPY tsconfig.base.json ./
COPY apps/api apps/api

WORKDIR /app/apps/api
EXPOSE 4000
CMD ["npm", "run", "dev:api"]
