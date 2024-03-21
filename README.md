
[![RootDB](https://www.rootdb.fr/assets/logo_name_blue_500x250.png)]()

# RootDB - infra repository

You'll find everything related to the installation of RootDB :
* docker images for production and development environments ;
* install bash script ;
* templates for services configuration like Nginx proxy, supervisor...


# Docker
## Remove all RootDB's containers, volumes, network and unused images.

```bash
docker container rm $(docker container ls -f name='rootdb' -aq); docker rmi -f $(docker images -q); docker volume rm $(docker volume ls -f name="rootdb" -q); docker network rm $(docker network ls -f name='rootdb' -q)
```
