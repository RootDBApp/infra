#!/usr/bin/env bash
set -Euo pipefail

declare api_dir="/var/www/api"
declare api_env_file="${api_dir}/.env"

#
# API log files
#
echo "RootDB setup - initialize log files..."
mkdir -p "${api_dir}/storage/logs"
touch "${api_dir}/storage/logs/laravel.log"
touch "${api_dir}/storage/logs/websocket.log"
touch "${api_dir}/storage/logs/worker.log"

#
# RootDB database initialization / update
#
echo "RootDB setup - check database availability..."

cd "${api_dir}" || exit 1

declare db_initialization_tries=1
declare test_migration_tables

#######################################
# Test if database is up and running.
# If the database is not running, exit 1.
# Globals:
#   db_initialization_tries
#   test_migration_tables
# Arguments:
#   None
#######################################
function testDatabaseInitialization() {

  test_migration_tables=$(php "${api_dir}/artisan" migrate:status)
  if [[ "${test_migration_tables}" =~ "Connection refused" ]]; then

    if [[ ${db_initialization_tries} -le 3 ]]; then

      echo "RootDB setup - database seems not yet initialized, waiting 3s before retrying..."
      sleep 3

      db_initialization_tries=$((db_initialization_tries+1))

      testDatabaseInitialization
    else
      echo "RootDB setup - [error] database seems not available."
      echo "RootDB setup - stopping here."
      exit 1
    fi
  fi
}

testDatabaseInitialization

if [[ "${test_migration_tables}" =~ "ERROR" ]]; then

  echo "RootDB setup - initializing database..."
  declare db_host
  declare db_port
  declare db_database
  declare db_username
  declare db_password

  db_host=$(grep 'DB_HOST' ${api_env_file} | sed "s|DB_HOST=||g")
  db_port=$(grep 'DB_PORT' ${api_env_file} | sed "s|DB_PORT=||g")
  db_database=$(grep 'DB_DATABASE' ${api_env_file} | sed "s|DB_DATABASE=||g")
  db_username=$(grep 'DB_USERNAME' ${api_env_file} | sed "s|DB_USERNAME=||g")
  db_password=$(grep 'DB_PASSWORD' ${api_env_file} | sed "s|DB_PASSWORD=||g")

  php "${api_dir}/artisan" db:wipe -n --force
  mysql -h "${db_host}" -P "${db_port}" -u "${db_username}" -p"${db_password}" "${db_database}" <"${api_dir}/storage/app/seeders/production/seeder_init.sql"
else

  echo "RootDB setup - running SQL migrations if there are any..."
  php artisan migrate --force
fi
