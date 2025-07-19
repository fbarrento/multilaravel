FROM nginx:1-bookworm

RUN usermod -u 1000 www-data

COPY ./nginx.conf /etc/nginx/nginx.conf


CMD ["nginx", "-g", "daemon off;"]