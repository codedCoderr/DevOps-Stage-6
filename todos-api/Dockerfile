# Use official small base image with multi-arch support (amd64 + arm64)
FROM node:20-alpine AS base
WORKDIR /app

# Only copy package files first (better layer caching)
COPY package*.json ./

# Install ONLY production dependencies (smaller image)
RUN npm install --production

# Now copy the rest of the app
COPY . .

# Expose the port used by server.js
EXPOSE 3000

# Run the server
CMD ["node", "server.js"]
