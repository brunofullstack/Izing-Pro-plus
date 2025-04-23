# Stage 1: Build Environment
FROM node:16 as buildenv
WORKDIR /app

# Instalar dependências essenciais para compilação de pacotes nativos
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
RUN npm install -g @quasar/cli

# Copiar os arquivos do frontend
COPY ./frontend/package*.json .
COPY ./frontend/quasar.conf.js .
RUN npm install --legacy-peer-deps --verbose

# Copiar o restante dos arquivos
COPY ./frontend/ .

# Verificar se os arquivos estão presentes
RUN echo "Verificando arquivos do frontend"
RUN ls -alh /app

# Rodar o build com verbose
RUN quasar build -m pwa --verbose || (echo "Build failed" && exit 1)

# Stage 2: Produção
FROM nginx:stable as production-stage
RUN mkdir /app
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html

# Configurar o Nginx
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d
