# develop stage
FROM node:16 as buildenv
WORKDIR /app

# 🛠 Instalação de dependências essenciais
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
    
RUN npm install -g @quasar/cli

COPY ./frontend/package*.json .
COPY ./frontend/quasar.conf.js .
RUN npm install --legacy-peer-deps
COPY ./frontend/ .

RUN quasar build -m pwa

FROM nginx:stable as production-stage
RUN mkdir /app
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d