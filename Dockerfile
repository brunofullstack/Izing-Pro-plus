# Stage 1: Build Environment
FROM node:16 as buildenv
WORKDIR /app

# Instalar dependências essenciais
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    libvips-dev

# Instalar o Quasar CLI globalmente
RUN npm install -g @quasar/cli@latest

# Copiar e instalar dependências
COPY ./frontend/package*.json .
COPY ./frontend/quasar.conf.js .
RUN npm cache clean --force
RUN npm install --legacy-peer-deps --force --verbose

# Instalar dependências problemáticas explicitamente
RUN npm install @svgdotjs/svg.select.js vue-apexcharts --save

# Copiar o restante dos arquivos
COPY ./frontend/ .

# Verificar arquivos
RUN echo "Verificando arquivos do frontend"
RUN ls -alh /app

# Rodar o build
RUN quasar build -m pwa --verbose > /tmp/build.log 2>&1 || (cat /tmp/build.log && echo "Build failed" && exit 1)

# Stage 2: Produção
FROM nginx:stable as production-stage
RUN mkdir /app
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d