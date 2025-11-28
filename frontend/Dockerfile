# ============================
# Stage 1 — Build
# ============================
# Use Node 12 (compatible with webpack 2, node-sass 4.14, babel 6, etc.)
FROM node:12-alpine AS build

WORKDIR /app

# Install OS dependencies required for node-sass
RUN apk add --no-cache python2 make g++

COPY package*.json ./
RUN npm install

COPY . .

# This project builds static files into /dist
RUN npm run build


# ============================
# Stage 2 — Production Server
# ============================
FROM nginx:stable-alpine

# Copy frontend build artifacts to Nginx root
COPY --from=build /app/dist /usr/share/nginx/html

# Optional: Remove default Nginx config & use your own
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
