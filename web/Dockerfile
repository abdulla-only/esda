# Multi-stage build for the web app.
#
#   dev   -> Vite dev server (hot reload), used by docker-compose
#   prod  -> static build served by nginx (default final stage)

# ---- base: install deps once ----
FROM node:22-alpine AS base
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install

# ---- dev: hot-reloading dev server ----
FROM base AS dev
COPY . .
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]

# ---- build: produce static assets ----
FROM base AS build
COPY . .
# VITE_API_URL is baked in at build time; override with --build-arg.
ARG VITE_API_URL=http://localhost:8000
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

# ---- prod: serve with nginx ----
FROM nginx:1.27-alpine AS prod
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
