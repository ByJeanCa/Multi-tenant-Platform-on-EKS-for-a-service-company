FROM nginx:1.27-alpine

RUN apk add --no-cache gettext

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
COPY html/ /usr/share/nginx/html/

RUN chmod +x /entrypoint.sh

EXPOSE 8080
CMD ["/entrypoint.sh"]