# Included by the proxied locations in nginx.conf.
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Port ${HTTPS_PORT};
# Let Rails hand file downloads back to nginx (Rack::Sendfile); same path in both containers.
proxy_set_header X-Sendfile-Type X-Accel-Redirect;
proxy_set_header X-Accel-Mapping /rails/storage/=/rails/storage/;
proxy_redirect off;
proxy_read_timeout 60s;
