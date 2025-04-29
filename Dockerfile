# Build stage
FROM node:16 as build-stage
WORKDIR /app

# Install Quasar CLI
RUN npm install -g @quasar/cli

# Copy package files first for better caching
COPY ./frontend/package*.json .
RUN npm install

# Copy app files
COPY ./frontend .

# Build Quasar PWA (remove .browserslistrc copy if file doesn't exist)
RUN quasar build -m pwa

# Production stage
FROM nginx:stable as production-stage
COPY --from=build-stage /app/dist/pwa /usr/share/nginx/html

# Use default nginx config if you don't have custom one
# COPY ./nginx.conf /etc/nginx/conf.d/default.conf