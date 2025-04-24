FROM node:16 as buildenv
WORKDIR /app

# Dependências do sistema
RUN apt-get update && apt-get install -y \
    python3 make g++ \
    libcairo2-dev libpango1.0-dev \
    libjpeg-dev libgif-dev librsvg2-dev libvips-dev

# Instalar Quasar CLI (versão compatível)
RUN npm install -g @quasar/cli@1.3.2

# Copiar arquivos de configuração
COPY ./frontend/package*.json .
COPY ./frontend/quasar.conf.js .

# Instalar dependências com versões específicas
RUN npm install \
    @svgdotjs/svg.js@3.1.2 \
    @svgdotjs/svg.select.js@3.0.2 \
    vue-apexcharts@3.6.2 \
    css-loader@5.2.7 \
    --legacy-peer-deps --force

# Instalar outras dependências
RUN npm cache clean --force
RUN npm install --legacy-peer-deps --force --verbose

# Copiar código fonte
COPY ./frontend/ .

# Build do Quasar
RUN quasar build -m pwa --verbose

# Stage de produção
FROM nginx:stable as production-stage
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d