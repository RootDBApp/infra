<!-- TOC -->
* [Build images](#build-images)
* [Push images on dockerhub](#push-images-on-dockerhub)
<!-- TOC -->

# Build images

```bash
cd docker-dev

docker build --compress --force-rm --no-cache -t rootdb-php-fpm:8.2.17 -f ./Dockerfile_php_fpm_8_2 .
docker build --compress --force-rm --no-cache -t rootdb-php-fpm:dev -f ./Dockerfile_php_fpm_8_2 .


docker build --compress --force-rm --no-cache -t rootdb-php-fpm:8.3.7 -f ./Dockerfile_php_fpm_8_3 .
```

# Push images on dockerhub

```bash
cd docker-dev

docker tag rootdb-php-fpm:8.2.17 rootdbapp/rootdb-php-fpm:8.2.17 
docker tag rootdb-php-fpm:8.2.17 rootdbapp/rootdb-php-fpm:dev

docker tag rootdb-php-fpm:8.3.7 rootdbapp/rootdb-php-fpm:8.3.7
docker tag rootdb-php-fpm:8.3.7 rootdbapp/rootdb-php-fpm:dev

docker push rootdbapp/rootdb-php-fpm:8.2.17
docker push rootdbapp/rootdb-php-fpm:8.3.7
docker push rootdbapp/rootdb-php-fpm:dev
```

