FROM node:18 as buildenv  # Using Node 18 for better compatibility
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

# 4. Clean installation with exact dependency versions
RUN rm -rf node_modules package-lock.json && \
    npm install --legacy-peer-deps --force && \
    npm install @svgdotjs/svg.js@3.1.2 @svgdotjs/svg.select.js@3.0.3 vue-apexcharts@1.6.2 --legacy-peer-deps --save-exact

# 5. Force compatible Webpack 4 versions
RUN npm install webpack@4.46.0 css-loader@5.2.7 vue-loader@15.9.8 --legacy-peer-deps

# 6. Verify installations
RUN npm list @svgdotjs/svg.js @svgdotjs/svg.select.js vue-apexcharts webpack css-loader

# 7. Copy application code
COPY ./frontend/ .

# 8. Build with detailed logging
RUN quasar build -m pwa --verbose > /tmp/build.log 2>&1 || (cat /tmp/build.log && exit 1)

# Production stage
FROM nginx:stable as production-stage
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d