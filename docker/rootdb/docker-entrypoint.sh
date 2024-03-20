#!/usr/bin/env bash
set -Euox pipefail

echo "Setup timezone..."
echo "${TIMEZONE}" >/etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# If user rootdb does not exist, create it now.
declare test_rootdb_user
test_rootdb_user=$(grep 'rootdb' /etc/passwd)

if [[ -z "${test_rootdb_user}" ]]; then

  echo "Creating rootdb user, with UID ${UID} & GID ${GID}... "
  addgroup rootdb --gid "${UID}" &&
    adduser \
      --disabled-password \
      --gecos "" \
      --home "/home/rootdb" \
      --ingroup "rootdb" \
      --uid "${GID}" \
      rootdb
fi

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

echo "Test user permissions on directories, log files..."
if [[ $(stat -c '%U' /var/www/api) != "rootdb" ]]; then

  chown -R rootdb:rootdb /var/www
fi

[[ ! -f /var/log/php8.2-fpm.log ]] && touch /var/log/php8.2-fpm.log

chown rootdb:rootdb /var/log/php8.2-fpm.log
chown rootdb:rootdb /usr/local/bin/docker-entrypoint.sh
chmod +x /usr/local/bin/docker-entrypoint.sh
chown rootdb:rootdb /usr/local/bin/setup_rootdb.sh
chmod +x /usr/local/bin/setup_rootdb.sh
chown rootdb:rootdb /var/www/api/.env
chown rootdb:rootdb /var/www/frontend/app-config.js

su -c "/usr/local/bin/setup_rootdb.sh" - rootdb

echo "Starting services with supervisor (background)..."
su -c "/usr/bin/supervisord -c /etc/supervisord.conf" - rootdb

echo "Starting nginx (background)..."
/usr/sbin/nginx

echo "Starting PHP-FPM (foreground)..."
/usr/sbin/php-fpm8.2 -F

exit 0
