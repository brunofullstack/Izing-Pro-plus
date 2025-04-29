FROM node:16 as buildenv
WORKDIR /app

# 1. Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 make g++ \
    libcairo2-dev libpango1.0-dev \
    libjpeg-dev libgif-dev librsvg2-dev

# 2. Install Quasar CLI
RUN npm install -g @quasar/cli@latest

# 3. Copy package files
COPY ./frontend/package*.json .
COPY ./frontend/quasar.conf.js .

# 4. Clean install with forced legacy dependencies
RUN rm -rf node_modules package-lock.json
RUN npm install --legacy-peer-deps --force

# 5. Verify installed versions of problematic packages
RUN npm list @svgdotjs/svg.js @svgdotjs/svg.select.js vue-apexcharts webpack css-loader

# 6. Copy application code
COPY ./frontend/ .

# 7. Build with detailed logging
RUN quasar build -m pwa --verbose > /tmp/build.log 2>&1 || (cat /tmp/build.log && exit 1)

# Production stage
FROM nginx:stable as production-stage
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d