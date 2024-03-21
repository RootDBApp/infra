<!-- TOC -->
* [Build images](#build-images)
* [Push images on dockerhub](#push-images-on-dockerhub)
<!-- TOC -->

# Build images

```bash
cd docker

docker build --compress --force-rm --no-cache -t rootdb-memcached:latest -f ./Dockerfile_memcached .
docker build --compress --force-rm --no-cache -t rootdb-nginx-php-fpm:8.2.17 -f ./Dockerfile_nginx_php_fpm_8_2 .


# Manual release of a new version of RootDB 
docker build --compress --force-rm --no-cache --build-arg VERSION="1.0.5" --build-arg UID=1000 --build-arg GID=1000 -t "rootdb:1.0.5" -f ./Dockerfile_rootdb .
```

# Push images on dockerhub

```bash
cd docker

docker tag rootdb-memcached:latest rootdbapp/rootdb-memcached:latest
docker push rootdbapp/rootdb-memcached:latest

docker tag rootdb-nginx-php-fpm:8.2.17 rootdbapp/rootdb-nginx-php-fpm:8.2.17
docker tag rootdb-nginx-php-fpm:8.2.17 rootdbapp/rootdb-nginx-php-fpm:latest
docker push rootdbapp/rootdb-nginx-php-fpm:8.2.17
docker push rootdbapp/rootdb-nginx-php-fpm:latest

# Manual release of a new version of RootDB 
docker tag rootdb:1.0.5 rootdbapp/rootdb:1.0.5
docker tag rootdb:1.0.5 rootdbapp/rootdb:latest
docker push rootdbapp/rootdb:1.0.5
docker push rootdbapp/rootdb:latest

```
