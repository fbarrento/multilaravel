FROM nginx:alpine

RUN apk add --no-cache curl

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/nginx.conf
COPY laravel.conf /etc/nginx/conf.d/default.conf

RUN addgroup -g 1000 -S www-data || true && \
    adduser -u 1000 -D -S -G www-data www-data || \
    (deluser www-data && adduser -u 1000 -D -S -G www-data www-data)

RUN mkdir -p /var/cache/nginx


RUN chown -R www-data:www-data /var/cache/nginx

RUN chown -R www-data:www-data /usr/share/nginx/html


HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD curl -f http://localhost/up || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
