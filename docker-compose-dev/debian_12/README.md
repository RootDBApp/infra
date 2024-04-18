Used for bash installer development.

```bash
docker compose up
```

# Run the installation script

```bash
#1 - get a bash prompt inside Debian container
docker container exec -it -u root dev-rootdb-debian-12 bash

#2 - create main RootDB directory
mkdir /var/www/rootdb

#3 - start memcached
memcached -d -u memcache

#4 - start the installation script
./install.shrootdb-ws-api-dev.rootdb.fr
```


# Optional
## Login as root user on the MariaDB database container

```bash
# On you workstation

mysql -u root -p -h 172.30.0.32
```

## Nginx, TLS, custom API & frontend environments files

Update `volumes` section ofr `dev-rootdb-debian-12` service, in `docker-compose.yml`.


## Start all services

```bash
nginx
php-fpm8.2 -D
php /var/www/rootdb/api/artisan reverb:start
```
