FROM node:24.15.0-alpine3.23@sha256:d1b3b4da11eefd5941e7f0b9cf17783fc99d9c6fc34884a665f40a06dbdfc94f

WORKDIR /workspace/apps/web
COPY apps/web/package.json apps/web/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY apps/web/index.html apps/web/tsconfig.json apps/web/vite.config.ts apps/web/vitest.config.ts ./
COPY apps/web/src ./src
COPY packages/api-contracts /workspace/packages/api-contracts
RUN npm run build
RUN mkdir -p node_modules/.vite-temp && chown node:node node_modules/.vite-temp

USER node
EXPOSE 8080
CMD ["npm", "run", "preview"]
