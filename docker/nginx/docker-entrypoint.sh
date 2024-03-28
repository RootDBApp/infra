#!/usr/bin/env bash
set -Euox pipefail

echo "Nginx - cleaning /etc/nginx/conf.d"
rm -f /etc/nginx/sites-available/default.conf
rm -f /etc/nginx/sites-enabled/default.conf
rm -f /etc/nginx/conf.d/default.conf

rm -f /etc/nginx/conf.d/rootdb-api.conf
rm -f /etc/nginx/conf.d/rootdb-frontend.conf

echo "Nginx - updating configurations.."

# Copy TLS certificat because websocket can use it.
if [[ -f "/etc/nginx/ssl/${NGINX_SSL_CERTIFICATE}" ]]; then

  cp "/etc/nginx/ssl/${NGINX_SSL_CERTIFICATE}" /var/www
  cp "/etc/nginx/ssl/${NGINX_SSL_CERTIFICATE_KEY}" /var/www
  chown rootdb:rootdb "/var/www/${NGINX_SSL_CERTIFICATE}" "/var/www/${NGINX_SSL_CERTIFICATE_KEY}"
  chmod 644 "/var/www/${NGINX_SSL_CERTIFICATE}"
  chmod 600 "/var/www/${NGINX_SSL_CERTIFICATE_KEY}"
fi

if [[ $NGINX_USE_SSL == 1 ]]; then

  echo "Nginx - using ssl"

  cp /etc/nginx/conf.d.tpl/rootdb-api_ssl.conf /etc/nginx/conf.d/rootdb-api.conf
  cp /etc/nginx/conf.d.tpl/rootdb-frontend_ssl.conf /etc/nginx/conf.d/rootdb-frontend.conf

  # Certificats
  sed -i "s|_NGINX_SSL_CERTIFICATE_KEY_|${NGINX_SSL_CERTIFICATE_KEY}|g" /etc/nginx/conf.d/rootdb-frontend.conf
  sed -i "s|_NGINX_SSL_CERTIFICATE_|${NGINX_SSL_CERTIFICATE}|g" /etc/nginx/conf.d/rootdb-frontend.conf

  sed -i "s|_NGINX_SSL_CERTIFICATE_KEY_|${NGINX_SSL_CERTIFICATE_KEY}|g" /etc/nginx/conf.d/rootdb-api.conf
  sed -i "s|_NGINX_SSL_CERTIFICATE_|${NGINX_SSL_CERTIFICATE}|g" /etc/nginx/conf.d/rootdb-api.conf
else

  echo "Nginx - not using ssl"
  cp /etc/nginx/conf.d.tpl/rootdb-api.conf /etc/nginx/conf.d/rootdb-api.conf
  cp /etc/nginx/conf.d.tpl/rootdb-frontend.conf /etc/nginx/conf.d/rootdb-frontend.conf

fi

# Ports
sed -i "s|_NGINX_FRONTEND_PORT_|${NGINX_FRONTEND_PORT}|g" /etc/nginx/conf.d/rootdb-frontend.conf
sed -i "s|_NGINX_API_PORT_|${NGINX_API_PORT}|g" /etc/nginx/conf.d/rootdb-frontend.conf
sed -i "s|_NGINX_API_PORT_|${NGINX_API_PORT}|g" /etc/nginx/conf.d/rootdb-api.conf

# Hostnames
sed -i "s|_NGINX_FRONTEND_HOST_|${NGINX_FRONTEND_HOST}|g" /etc/nginx/conf.d/rootdb-frontend.conf
sed -i "s|_NGINX_API_HOST_|${NGINX_API_HOST}|g" /etc/nginx/conf.d/rootdb-frontend.conf
sed -i "s|_NGINX_API_HOST_|${NGINX_API_HOST}|g" /etc/nginx/conf.d/rootdb-api.conf
