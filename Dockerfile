FROM node:16 as buildenv
WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y \
    python3 make g++ \
    libcairo2-dev libpango1.0-dev \
    libjpeg-dev libgif-dev librsvg2-dev libvips-dev

# Install Quasar CLI
RUN npm install -g @quasar/cli@latest

# Copy package files first for better caching
COPY ./frontend/package*.json .
COPY ./frontend/quasar.conf.js .

# Install all dependencies at once with legacy-peer-deps
RUN npm install --legacy-peer-deps \
    @svgdotjs/svg.js@3.1.2 \
    @svgdotjs/svg.select.js@3.0.3 \
    vue-apexcharts@1.6.2

# Clean cache
RUN npm cache clean --force

# Copy the rest of the application
COPY ./frontend/ .

# Build with detailed logging
RUN quasar build -m pwa --verbose > /tmp/build.log 2>&1 || (cat /tmp/build.log && exit 1)

# Production stage
FROM nginx:stable as production-stage
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d