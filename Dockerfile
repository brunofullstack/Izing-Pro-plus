# develop stage
FROM node:16 as buildenv
WORKDIR /app

RUN npm install -g @quasar/cli

COPY ./frontend/package*.json .
COPY ./frontend/quasar.conf.js .
RUN npm install
COPY ./frontend/ .

RUN quasar build -m pwa

# production stage
FROM nginx:stable as production-stage
RUN mkdir /app
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d# Build stage (using Node 16+)
FROM node:16 as buildenv
WORKDIR /app

# Install Quasar CLI globally (use a specific version if needed)
RUN npm install -g @quasar/cli

# Copy package files first for better caching
COPY ./frontend/package*.json .
COPY ./frontend/quasar.conf.js .
COPY ./frontend/.browserslistrc .  # If exists, required for PWA builds

# Install dependencies (clean install for production)
RUN npm ci --legacy-peer-deps  # Use --legacy-peer-deps if needed

# Copy the rest of the frontend files
COPY ./frontend .

# Build Quasar PWA (add --debug for troubleshooting)
RUN quasar build -m pwa --debug

# Production stage (nginx)
FROM nginx:stable as production-stage
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/conf.d/default.conf  # Override default config

# Optional: Set correct permissions for nginx
RUN chown -R nginx:nginx /usr/share/nginx/html