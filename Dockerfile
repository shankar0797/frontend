
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

# Create writable Nginx directories
RUN mkdir -p \
    /tmp/client_temp \
    /tmp/proxy_temp \
    /tmp/fastcgi_temp \
    /tmp/uwsgi_temp \
    /tmp/scgi_temp \
    /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp

# Copy frontend build
COPY --from=builder /app/build /usr/share/nginx/html

# Copy custom Nginx configurations
COPY nginx-main.conf /etc/nginx/nginx.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create non-root user and set permissions
RUN addgroup -S pharma && adduser -S -u 1000 pharma -G pharma \
    && chown -R pharma:pharma \
       /usr/share/nginx/html \
       /var/cache/nginx \
       /var/run \
       /tmp

USER pharma

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
