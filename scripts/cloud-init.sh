#!/bin/bash
set -euo pipefail
exec > >(tee -a /var/log/cloud-init-custom.log) 2>&1
echo "[bootstrap] starting $(date -u)"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx openssl

# Self-signed TLS certificate
install -d /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out    /etc/nginx/ssl/selfsigned.crt \
  -subj   "/C=IN/ST=Dev/L=Dev/O=intuitiveAI/CN=intuitiveai-dev"

# nginx site: HTTPS on 443, redirect 80 -> 443, plus a /health endpoint
cat > /etc/nginx/sites-available/default <<'NGINX'
server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    server_name _;

    ssl_certificate     /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /health {
        access_log off;
        add_header Content-Type text/plain;
        return 200 "ok\n";
    }
}
NGINX

cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html><head><title>intuitiveAI web-app</title></head>
<body><h1>intuitiveAI dev web-app</h1>
<p>HTTPS service provisioned by Terraform + cloud-init.</p></body></html>
HTML

nginx -t
systemctl enable nginx
systemctl restart nginx
echo "[bootstrap] complete $(date -u)"