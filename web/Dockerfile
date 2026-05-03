FROM node:lts-alpine as build

WORKDIR /app

ARG VITE_API_ENDPOINT
ARG VITE_DISABLE_STATISTICS=true
ARG VITE_BASE_PATH
ENV VITE_API_ENDPOINT=$VITE_API_ENDPOINT
ENV VITE_DISABLE_STATISTICS=$VITE_DISABLE_STATISTICS
ENV VITE_BASE_PATH=$VITE_BASE_PATH

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html
