# Stage 1: Build environment
FROM node:14 AS buildenv
WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y \
    python3 make g++ \
    libcairo2-dev libpango1.0-dev \
    libjpeg-dev libgif-dev librsvg2-dev

# Install Quasar CLI
RUN npm install -g @quasar/cli

# Copy package files
COPY package*.json .
COPY quasar.conf.js .

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy application code
COPY . .

# Build the application
RUN quasar build -m pwa

# Stage 2: Production environment
FROM nginx:stable
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf