Used for bash installer development.

# **TL.DR** - Up and running in 20 seconds


```bash
docker compose up
```


# Log inside container

```bash
docker container exec -it -u root dev-rootdb-debian-12 bash
```

# Start memcached

```bash
memcached -d -u memcache
```
