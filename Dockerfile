# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY public ./public
COPY src ./src
COPY .env.production ./
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:1.25-alpine
RUN mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN addgroup -S pharma && adduser -S -u 1000 pharma -G pharma \
    && mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/scgi_temp \
    && chown -R pharma:pharma /usr/share/nginx/html /var/cache/nginx /var/run /tmp

USER pharma
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]