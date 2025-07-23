FROM nginx:alpine

RUN apk add --no-cache curl

RUN rm /etc/nginx/conf.d/default.conf

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.old.conf /etc/nginx/nginx.conf
COPY laravel.conf /etc/nginx/conf.d/laravel.conf

RUN usermod -u 1000 www-data

RUN mkdir -p /var/cache/nginx

RUN mkdir -p /usr/share/nginx/html && \
    echo "OK" > /usr/share/nginx/html/health

RUN chown -R www-data:www-data /var/cache/nginx

RUN chown -R www-data:www-data /usr/share/nginx/html

HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD curl -f http://localhost/health || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]




COPY nginx.old.conf /etc/nginx/nginx.conf


CMD ["nginx", "-g", "daemon off;"]