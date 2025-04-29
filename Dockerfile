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

# 4. Install core dependencies first
RUN npm install --legacy-peer-deps

# 5. Resolve SVG.js compatibility
RUN npm install --legacy-peer-deps \
    @svgdotjs/svg.js@3.0.16 \
    @svgdotjs/svg.select.js@3.0.1 \
    vue-apexcharts@1.6.1

# 6. Force-resolve Webpack dependencies
RUN npm install --legacy-peer-deps \
    webpack@4.46.0 \
    css-loader@5.2.7 \
    vue-loader@15.9.8

# 7. Clean cache and verify
RUN npm cache clean --force
RUN npm list @svgdotjs/svg.js @svgdotjs/svg.select.js vue-apexcharts webpack css-loader

# 8. Copy application code
COPY ./frontend/ .

# 9. Build with detailed logging
RUN quasar build -m pwa --verbose > /tmp/build.log 2>&1 || (cat /tmp/build.log && exit 1)

# Production stage
FROM nginx:stable as production-stage
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d