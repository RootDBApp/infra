<!-- TOC -->
* [Build images](#build-images)
* [Push images on dockerhub](#push-images-on-dockerhub)
<!-- TOC -->

# Build images

```bash
cd docker

docker build --compress --force-rm --no-cache -t rootdb-memcached:latest -f ./Dockerfile_memcached .
docker build --compress --force-rm --no-cache -t rootdb-nginx-php-fpm-supervisor:8.2.18 -f ./Dockerfile_nginx_php_fpm_supervisor_8_2 .
docker build --compress --force-rm --no-cache -t rootdb-nginx-php-fpm-supervisor:8.3.7 -f ./Dockerfile_nginx_php_fpm_supervisor_8_3 .

# Manual release of a new version of RootDB 
docker build --compress --force-rm --no-cache --build-arg VERSION="1.1.1" --build-arg UID=1000 --build-arg GID=1000 -t "rootdb:1.1.1" -f ./Dockerfile_rootdb .
```

# Push images on dockerhub

```bash
cd docker

docker tag rootdb-memcached:latest rootdbapp/rootdb-memcached:latest
docker push rootdbapp/rootdb-memcached:latest

docker tag rootdb-nginx-php-fpm-supervisor:8.2.18 rootdbapp/rootdb-nginx-php-fpm-supervisor:8.2.18
docker tag rootdb-nginx-php-fpm-supervisor:8.2.18 rootdbapp/rootdb-nginx-php-fpm-supervisor:latest
docker push rootdbapp/rootdb-nginx-php-fpm-supervisor:8.2.18
docker push rootdbapp/rootdb-nginx-php-fpm-supervisor:latest


docker tag rootdb-nginx-php-fpm-supervisor:8.3.7 rootdbapp/rootdb-nginx-php-fpm-supervisor:8.3.7
docker push rootdbapp/rootdb-nginx-php-fpm-supervisor:8.3.7

# Manual release of a new version of RootDB 
docker tag rootdb:1.1.1 rootdbapp/rootdb:1.1.1
docker tag rootdb:1.1.1 rootdbapp/rootdb:latest
docker push rootdbapp/rootdb:1.1.1
docker push rootdbapp/rootdb:latest

```
