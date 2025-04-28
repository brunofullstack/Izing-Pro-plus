FROM node:16 as buildenv
WORKDIR /app

# Dependências do sistema
RUN apt-get update && apt-get install -y \
    python3 make g++ \
    libcairo2-dev libpango1.0-dev \
    libjpeg-dev libgif-dev librsvg2-dev libvips-dev

# Instalar Quasar CLI
RUN npm install -g @quasar/cli@latest

# Copiar arquivos de configuração e dependências
COPY ./frontend/package*.json .
COPY ./frontend/quasar.conf.js .

# Instalar dependências com flags para resolver conflitos
RUN npm install --legacy-peer-deps --force
RUN npm install @svgdotjs/svg.js@latest @svgdotjs/svg.select.js@latest --legacy-peer-deps
RUN npm install vue-apexcharts@latest --legacy-peer-deps

# Limpar cache (opcional, pode ajudar em alguns casos)
RUN npm cache clean --force

# Copiar resto do código
COPY ./frontend/ .

# Build com log detalhado
RUN quasar build -m pwa --verbose > /tmp/build.log 2>&1 || (cat /tmp/build.log && exit 1)

# Stage de produção
FROM nginx:stable as production-stage
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d