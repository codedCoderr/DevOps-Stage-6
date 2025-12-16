# Use official small base image with multi-arch support
FROM node:20-alpine AS base

# Set working directory
WORKDIR /app

# Copy package files separately for caching
COPY package*.json ./

# Install ONLY production dependencies (smaller image)
RUN npm install --production

# Copy the rest of the app
COPY . .

# Expose the port your app listens on
EXPOSE 3000

# Default command to run the server
CMD ["node", "server.js"]
