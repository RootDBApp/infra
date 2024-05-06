<!-- TOC -->
* [Build images](#build-images)
* [Push images on dockerhub](#push-images-on-dockerhub)
<!-- TOC -->

# Build images

```bash
cd docker-dev

docker build --compress --force-rm --no-cache -t rootdb-php-fpm:dev -f ./Dockerfile_php_fpm_8_2 .
```

# Push images on dockerhub

```bash
cd docker-dev

docker tag rootdb-php-fpm:dev rootdbapp/rootdb-php-fpm:dev
docker push rootdbapp/rootdb-php-fpm:dev
```
