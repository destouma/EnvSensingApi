# Base image (pinned major version)
FROM nginx:1.29

# Static files served directly by nginx (error pages, robots.txt, icons)
COPY public /var/www/public

# Templates are rendered into /etc/nginx/conf.d at container start (envsubst, see nginx.conf).
# The TLS certificate is mounted at /etc/nginx/certs, see docker-compose.yml.
COPY docker/web/nginx.conf /etc/nginx/templates/default.conf.template
COPY docker/web/proxy_headers.inc /etc/nginx/templates/proxy_headers.inc.template

EXPOSE 80 443
# Use the "exec" form of CMD so Nginx shuts down gracefully on SIGTERM (i.e. `docker stop`)
CMD ["nginx", "-g", "daemon off;"]
