# frontend/Dockerfile
# Stage 1: Build
FROM node:20 as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve with Nginx/Caddy or simply use a minimal Node image
FROM nginx:stable-alpine as final
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]