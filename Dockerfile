# develop stage
FROM node:20-bookworm AS buildenv
WORKDIR /app

RUN npm install -g @quasar/cli@1.4.0

COPY ./frontend/package*.json .
COPY ./frontend/quasar.conf.js .
RUN npm install --legacy-peer-deps
COPY ./frontend/ .

ENV NODE_OPTIONS=--openssl-legacy-provider
RUN quasar build -m pwa

FROM nginx:stable AS production-stage
RUN mkdir /app
COPY --from=buildenv /app/dist/pwa /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/conf.d