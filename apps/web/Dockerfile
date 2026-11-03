# HB Trade web app (Vite dev server; proxies /api to the API service).
FROM node:20-slim
WORKDIR /app

COPY package.json package-lock.json* ./
COPY apps/web/package.json apps/web/package.json
COPY apps/api/package.json apps/api/package.json
RUN npm install --workspace @hb/web --include-workspace-root

COPY tsconfig.base.json ./
COPY apps/web apps/web

WORKDIR /app/apps/web
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
