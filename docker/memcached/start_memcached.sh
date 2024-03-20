#!/bin/sh

/usr/bin/memcached \
  --user=${MEMCACHED_USER:-memcached} \
  --listen=${MEMCACHED_HOST:-0.0.0.0} \
  --port=${MEMCACHED_PORT:-11211} \
  --memory-limit=${MEMCACHED_MEMUSAGE:-256} \
  --max-item-size=${MEMCACHED_MAX_ITEM_SIZE:-128M} \
  --conn-limit=${MEMCACHED_MAXCONN:-1024} \
  --threads=${MEMCACHED_THREADS:-4} \
  --max-reqs-per-event=${MEMCACHED_REQUESTS_PER_EVENT:-20} \
