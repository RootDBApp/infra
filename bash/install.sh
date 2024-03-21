#!/usr/bin/env bash

# This file is part of RootDB.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# AUTHORS
# PORQUET Sébastien <sebastien.porquet@ijaz.fr>

###############################################################################################
declare SCRIPT_PATH
pushd . >/dev/null
SCRIPT_PATH="${BASH_SOURCE[0]}"
if ([ -h "${SCRIPT_PATH}" ]); then
  while ([ -h "${SCRIPT_PATH}" ]); do
    cd "$(dirname "$SCRIPT_PATH")" || exit
    SCRIPT_PATH=$(readlink "${SCRIPT_PATH}")
  done
fi
cd "$(dirname ${SCRIPT_PATH})" || exit >/dev/null
SCRIPT_PATH=$(pwd)
popd || exit >/dev/null
###############################################################################################

# Script options.
declare env_file="${SCRIPT_PATH}/env"
declare error=false
declare ignore_software_dependencies=false
declare rdb_asked_version # User defined, or fetched online.

declare log_file="${SCRIPT_PATH}/log"

# Variables from env file.
declare version
declare data_dir
declare session_domain
declare scheme
declare front_host
declare api_host
declare api_memcached_host
declare api_memcached_port
declare api_db_host
declare api_db_port
declare api_db_root_password
declare api_db_user_password
declare api_db_limit_to_ip
declare nginx_user
declare nginx_group
declare pusher_app_key
declare websockets_port
declare websockets_ssl_local_cert
declare websockets_ssl_local_pk
declare websockets_ssl_passphrase

declare rdb_online_archive_url="https://builds.rootdb.fr/rootdb"
declare rdb_online_latest_version_url="${rdb_online_archive_url}/latest"

declare rdb_archive_file
declare rdb_archives_dir="${data_dir}/archives"
declare rdb_current_version          # From API directory (.version file)
declare rdb_latest_version_available # Fetched online.
declare rdb_version_dir              # <rdb_archives_dir>/<x.y.z>

# Directories and configuration files.
declare api_dir
declare front_dir
declare api_frontend_themes_dir  # <rdb_version_dir>/api/frontend-themes
declare api_env_file             # <rdb_version_dir>/api/env
declare front_app_config_js_file # <rdb_version_dir>/frontend/public/app-config.js

# Main configuration file user can tune.
declare root_api_env_file             # /<data_dir>/api_config
declare root_front_app_config_js_file # /<data_dir>/frontend_config

# To know if RootDB is installed and configured.
declare api_init_file
declare front_init_file
declare rdb_init_file

#
# Log functions
#
# Use to add some colors.
declare txtblue="\\033[1;34m"
declare txtgreen="\\033[1;32m"
declare txtnormal="\\033[0;39m"
declare txtred="\\033[1;31m"
declare txtyellow="\\033[1;33m"

#######################################
# Display a log message, with or without carrige return char at the end.
# Arguments:
#   Message to display.
#   Carriage return :
#     * true : Do not add the carriage return char at the end of the string.
#     * false: Add the carriage return at the end of the string.
# Outputs:
#   Writes the message, preceded by "log"
#######################################
function logInfo() {

  if [[ ! $2 ]]; then

    echo -e "${txtyellow}log${txtnormal} | $1"
  else

    echo -en "${txtyellow}log${txtnormal} | $1"
  fi
}

#######################################
# Append [ OK ] to the end of current line
# Outputs:
#   Writes "[ OK ]"
#######################################
function logInfoAddOK() {

  echo -e "[${txtgreen}OK${txtnormal}]" || logInfo "[OK]"
}

#######################################
# Append [ Fail ] to the end of current line
# Arguments:
#   None
# Outputs:
#   Writes "[ Fail ]"
#######################################
function logInfoAddFail() {

  echo -e "[${txtred}Fail${txtnormal}]" || logInfo "[Fail]"
}

#######################################
# Display an error message.
# Arguments:
#   Message to display.
# Outputs:
#   Writes the error message, preceded by "error"
#######################################
function logError() {

  echo -e "${txtred}error${txtnormal} | $1"
}

#######################################
# Display a log message, without return char at the end..
# Arguments:
#   Message to display.
# Outputs:
#   Writes the message, preceded by "log"
#######################################
function logQuestion() {

  echo -en "${txtblue}log${txtnormal} | $1"
}

#
# Utility functions
#
#######################################
# Get username of file.
# Arguments:
#   Path to the file.
# Returns:
#   The group.
#######################################
function getUser() {
  stat -c '%U' "$1"
}

#######################################
# Get user group of a file.
# Arguments:
#   Path to the file.
# Returns:
#   The group.
#######################################
function getGroup() {
  stat -c '%G' "$1"
}

#
# Pre-installation functions
#
#######################################
# Display the welcome message
# Outputs:
#   Writes the welcome message
#######################################
function welcome() {

  echo -e "############################################################"
  echo -e "#                                                          #"
  echo -e "#             Welcome to ${txtyellow}RootDB${txtnormal} install script             #"
  echo -e "#                                                          #"
  echo -e "############################################################"
  echo
  echo -e "This script will install or update RootDB code with, by default, the latest version available."
  echo
  echo -e "${txtred}This script does not handle the configuration of these services${txtnormal}"
  echo -e "* nginx      : https://documentation.rootdb.fr/install/install_without_docker.html#nginx"
  echo -e "* memcached"
  echo -e "* php-fpm    : https://documentation.rootdb.fr/install/install_without_docker.html#php-fpm"
  echo -e "* mariadb    : https://documentation.rootdb.fr/install/install_without_docker.html#mariadb"
  echo -e "* supervisor : https://documentation.rootdb.fr/install/install_without_docker.html#supervisor"
  echo
  echo
  echo -e "${txtgreen}Steps${txtnormal}"
  echo -e "\t1 - check if software dependencies & PHP modules are available."
  echo -e "\t2 - check directories, certificates files (if you want to use TSL), memcached, mariadb connexion are OK."
  echo -e "\t3 - download RootDB code from git repositories."
  echo -e "\t4 - setup the API and frontend environments if RootDB is not yet installed."
  echo -e "\t5 - bootstrap RootDB."
  echo
  echo -e "${txtgreen}Note${txtnormal}"
  echo -e "\tUse argument ${txtyellow}-v${txtnormal} to display all available options."
  echo
  echo
}

#######################################
# Check if user of this script is the root system user.
# If not, stop the execution of the script, return code 1
# Arguments:
#   None
#######################################
function isRootUser() {

  if [[ "$(whoami)" != "root" ]]; then
    echo
    logError "you have to be \`root\` user in order to run this script."
    echo
    exit 1
  fi
}

#######################################
# Ask the user if he setup his "env" file correctly.
# If not, stop the execution of the script.
# Arguments:
#   None
#######################################
function warningEnvFile() {

  logQuestion "Did you think to create and configure your ${txtyellow}env${txtnormal} file ? [Y/n]"
  read -r env_ok
  echo
  [[ -z "${env_ok}" ]] && env_ok="y"

  if [[ "${env_ok}" != "y" ]]; then
    logInfo "Stopping here."
    exit 0
  fi

}

#######################################
# Check if the env file is available. If not, stop the script execution.
# Globals:
#   env_file
# Arguments:
#   None
#######################################
function checkEnvFile() {

  if [[ ! -f "${env_file}" ]]; then
    logError "env file \"${env_file}\" does not exists."
    logError "you need to provide a env file with \"-e\" option"
    logInfo "get a default one here : https://document.rootdb.fr/.env"
    exit 1
  fi

}

#######################################
# Everything start here
# Globals:
#   env_file
#   version
#   data_dir
#   scheme
#   front_host
#   api_host
#   session_domain
#   api_memcached_host
#   api_memcached_port
#   api_db_host
#   api_db_port
#   api_db_root_password
#   api_db_user_password
#   api_db_limit_to_ip
#   nginx_user
#   nginx_group
#   pusher_app_key
#   websockets_port
#   websockets_ssl_local_cert
#   websockets_ssl_local_pk
#   websockets_ssl_passphrase
#   rdb_archives_dir
#   api_dir
#   front_dir
#   api_frontend_themes_dir
#   api_env_file
#   front_app_config_js_file
#   root_api_env_file
#   root_front_app_config_js_file
#   api_init_file
#   front_init_file
#   rdb_init_file
#   rdb_asked_version
# Arguments:
#   None
#######################################
function setEnvVariables() {

  logInfo "Check ${env_file} contents..."
  version=$(grep "^VERSION" "${env_file}" | sed "s/VERSION=//")
  data_dir=$(grep "^DATA_DIR" "${env_file}" | sed "s/DATA_DIR=//")
  scheme=$(grep "^SCHEME" "${env_file}" | sed "s/SCHEME=//")
  front_host=$(grep "^FRONT_HOST" "${env_file}" | sed "s/FRONT_HOST=//")
  api_host=$(grep "^API_HOST" "${env_file}" | sed "s/API_HOST=//")
  session_domain=$(awk -F/ '{n=split($3, a, "."); printf("%s.%s", a[n-1], a[n])}' <<<"${scheme}://$front_host")
  api_memcached_host=$(grep "^API_MEMCACHED_HOST" "${env_file}" | sed "s/API_MEMCACHED_HOST=//")
  api_memcached_port=$(grep "^API_MEMCACHED_PORT" "${env_file}" | sed "s/API_MEMCACHED_PORT=//")
  api_db_host=$(grep "^API_DB_HOST" "${env_file}" | sed "s/API_DB_HOST=//")
  api_db_port=$(grep "^API_DB_PORT" "${env_file}" | sed "s/API_DB_PORT=//")
  api_db_root_password=$(grep "^API_DB_ROOT_PASSWORD" "${env_file}" | sed "s/API_DB_ROOT_PASSWORD=//")
  api_db_user_password=$(grep "^API_DB_USER_PASSWORD" "${env_file}" | sed "s/API_DB_USER_PASSWORD=//")
  api_db_limit_to_ip=$(grep "^API_DB_LIMIT_TO_IP" "${env_file}" | sed "s/API_DB_LIMIT_TO_IP=//")
  nginx_user=$(grep "^NGINX_USER" "${env_file}" | sed "s/NGINX_USER=//")
  nginx_group=$(grep "^NGINX_GROUP" "${env_file}" | sed "s/NGINX_GROUP=//")
  pusher_app_key=$(grep "^PUSHER_APP_KEY" "${env_file}" | sed "s/PUSHER_APP_KEY=//")
  #websockets_port=$(grep "WEBSOCKETS_PORT" "${env_file}" | sed "s/WEBSOCKETS_PORT=//")
  websockets_port=6001

  websockets_ssl_local_cert=$(grep "WEBSOCKETS_SSL_LOCAL_CERT" "${env_file}" | sed "s/WEBSOCKETS_SSL_LOCAL_CERT=//")
  websockets_ssl_local_pk=$(grep "WEBSOCKETS_SSL_LOCAL_PK" "${env_file}" | sed "s/WEBSOCKETS_SSL_LOCAL_PK=//")
  websockets_ssl_passphrase=$(grep "WEBSOCKETS_SSL_PASSPHRASE" "${env_file}" | sed "s/WEBSOCKETS_SSL_PASSPHRASE=//")

  if [[ -z "${rdb_asked_version}" && "${version}" != "latest" ]]; then

    rdb_asked_version="${version}"
  fi

  if [[ -n "${rdb_asked_version}" ]]; then
    version="${rdb_asked_version}"
  fi

  logInfo "Extracted from the ${env_file} file :"
  logInfo
  logInfo "version                   : ${version}"
  logInfo "data dir                  : ${data_dir}"
  logInfo "scheme                    : ${scheme}"
  logInfo "api host                  : ${api_host}"
  logInfo "front host                : ${front_host}"
  logInfo "session domain            : ${session_domain}"
  logInfo "api_memcached_host        : ${api_memcached_host}"
  logInfo "api_memcached_port        : ${api_memcached_port}"
  logInfo "api db host               : ${api_db_host}"
  logInfo "api db port               : ${api_db_port}"
  logInfo "api db root password      : ****"
  logInfo "api db user password      : ****"
  logInfo "api db limit to ip        : ${api_db_limit_to_ip}"
  logInfo "nginx user                : ${nginx_user}"
  logInfo "nginx group               : ${nginx_group}"
  logInfo "pusher app key            : ${pusher_app_key}"
  logInfo "websockets port           : ${websockets_port}"

  if [[ "$scheme" == "https" ]]; then
    logInfo "websockets ssl local_cert : ${websockets_ssl_local_cert}"
    logInfo "websockets ssl local pk   : ${websockets_ssl_local_pk}"
    logInfo "websockets ssl passphrase : ${websockets_ssl_passphrase}"
  fi

  rdb_archives_dir="${data_dir}/archives"

  api_dir="${data_dir}/api"
  front_dir="${data_dir}/frontend"
  api_frontend_themes_dir="${api_dir}/frontend-themes"
  api_env_file="${api_dir}/.env"
  front_app_config_js_file="${front_dir}/app-config.js"

  root_api_env_file="${data_dir}/api_config"
  root_front_app_config_js_file="${data_dir}/front_config.js"

  api_init_file="${data_dir}/.api_initialized"
  front_init_file="${data_dir}/.front_initialized"
  rdb_init_file="${data_dir}/.rdb_initialized"

  echo
  logQuestion "Is it OK ? [Y/n] "
  read -r env_ok
  echo

  [[ -z "${env_ok}" ]] && env_ok="y"

  if [[ "${env_ok}" != "y" ]]; then
    logInfo "Stopping here."
    exit 0
  fi
}

#######################################
# Check mandatory executable and PHP modules.
# Stop the execution of the script if there are missing stuff.
# Globals:
#   error
#   ignore_software_dependencies
# Arguments:
#   None
#######################################
function checkDependencies() {

  # software dependencies & php modules
  if [[ ${ignore_software_dependencies} == false ]]; then

    declare software_checks_failed=false
    logInfo "Check software dependencies..." true
    declare commands="awk bunzip2 col curl memcached mysql mysqldump pgrep php sed semver supervisorctl tar"
    for command_looped in ${commands}; do
      type -P "${command_looped}" &>/dev/null && continue || {
        error=true
        [[ ${software_checks_failed} == false ]] && logInfoAddFail
        software_checks_failed=true
        logError "missing software : ${command_looped}"
      }
    done

    [[ ${software_checks_failed} == false ]] && logInfoAddOK

    declare php_modules_checks_failed=false
    logInfo "Check PHP modules..." true
    declare php_modules="bcmath curl ctype dom gd gettext iconv mbstring memcached pcntl pdo zip"

    for php_module_looped in ${php_modules}; do
      if [[ -z $(php -r "echo extension_loaded('${php_module_looped}') ? 'ok' : 'ko';" | grep 'ok') ]]; then
        error=true
        [[ ${php_modules_checks_failed} == false ]] && logInfoAddFail
        php_modules_checks_failed=true
        logError "missing PHP module : ${php_module_looped}"
      fi
    done

    [[ ${php_modules_checks_failed} == false ]] && logInfoAddOK

    if [[ ${error} == true || ${software_checks_failed} == true || ${php_modules_checks_failed} == true ]]; then
      logError "There are errors, stopping here."
      exit 1
    fi
  fi
}

#######################################
# Check if the installation directory exists and display a warning if not exists.
# Globals:
#   error
# Arguments:
#   None
#######################################
function checkInstallDirectory() {

  logInfo "Check install directory..." true
  if [[ ! -d "${data_dir}" ]]; then
    error=true
    logInfoAddFail
    logError "install directory \"${data_dir}\" does not exists."
  else
    logInfoAddOK
  fi
}

#######################################
# Check if we have write access to installation directory and display a warning if not.
# Globals:
#   error
# Arguments:
#   None
#######################################
function checkDirectoriesPermissions() {

  logInfo "Check permissions..." true
  if [[ ! -w "${data_dir}" ]]; then
    error=true
    logInfoAddFail
    logError "no write access to : ${data_dir}"
  else
    logInfoAddOK
  fi
}

#######################################
# Check MariaDB connexion with the root db user. If we cannot connect, display a warning.
# Globals:
#   error
# Arguments:
#   None
#######################################
function checkMariadbConnexion() {

  logInfo "Check mariadb connexion..." true
  mysql -h "${api_db_host}" -u root -p${api_db_root_password} -e ";" &>/dev/null
  if [[ $? == 1 ]]; then
    error=true
    logInfoAddFail
    logError "Unable to connect to MariaDB server."
  else
    logInfoAddOK
  fi
}

#######################################
# Check if API database use has all the needed privileges to run SQL migrations.
# If we cannot connect, display a warning.
# Globals:
#   error
# Arguments:
#   None
#######################################
function checkApiUserGrants() {

  logInfo "Check API user grants..." true
  mysql -h "${api_db_host}" -u rootdb_api_user -p${api_db_user_password} -e "SHOW GRANTS FOR rootdb_api_user@'${api_db_limit_to_ip}';" &>/tmp/grants
  if [[ $? == 1 ]]; then

    logInfoAddFail
    logError "Unable to connect to MariaDB server."
    error=true
  else

    if ! grep -q "ALL PRIVILEGES" /tmp/grants; then

      declare grants
      grants=("CREATE" "INSERT" "UPDATE" "DELETE" "DROP" "ALTER")

      for grant in "${grants[@]}"; do

        if ! grep -q "${grant}" /tmp/grants; then

          error=true
          logInfoAddFail
          logError "Missing grant: ${grant}"
        fi
      done
    fi

  fi

  rm -f /tmp/grants
  if [[ ${error} == true ]]; then

    logError "There was an issue fetching rootdb_api_user@${api_db_limit_to_ip} grants."
  else
    logInfoAddOK
  fi
}

#######################################
# Check if Memcached is working correctly. If not, display a warning.
# Globals:
#   error
# Arguments:
#   None
#######################################
function checkMemcached() {

  logInfo "Check memcached connexion..." true
  declare -i test_res
  test_res=$(php -r "\$c = new Memcached(); \$c->addServer(\"${api_memcached_host}\", ${api_memcached_port}); var_dump(\$c->getStats());" | grep 'array' | wc -l)
  if [[ ${test_res} -eq 0 ]]; then
    error=true
    logInfoAddFail
    logError "Unable to connect to memcached server."
  else
    logInfoAddOK
  fi
}

#######################################
# Check if SSL certificat and private key are available.
# Globals:
#   error
# Arguments:
#   None
#######################################
function checkCertAndPK() {

  logInfo "Check if ${websockets_ssl_local_cert} exists..." true
  if [[ ! -f "${websockets_ssl_local_cert}" ]]; then
    error=true
    logInfoAddFail
    logError "File ${websockets_ssl_local_cert} does not exist."
  else
    logInfoAddOK
  fi

  logInfo "Check if ${websockets_ssl_local_pk} exists..." true
  if [[ ! -f "${websockets_ssl_local_pk}" ]]; then
    error=true
    logInfoAddFail
    logError "File ${websockets_ssl_local_pk} does not exist."
  else
    logInfoAddOK
  fi

  if [[ ${error} == true ]]; then
    logInfo "There are errors, stopping here."
    exit 1
  fi
}

#
#
# RooDB installation and boostrap
#
#
#######################################
# Check if SSL certificate and private key are available.
# Stop the script if there's an issue while fetching the version online.
# Globals:
#   rdb_latest_version_available
# Arguments:
#   None
#######################################
function fetchLatestRootDBVersion() {

  logInfo "Check latest version of RootDB available..." true

  rdb_latest_version_available=$(curl --silent "${rdb_online_latest_version_url}" /dev/null 2>&1 | head -1)
  if [[ -z "${rdb_latest_version_available}" ]]; then
    logInfoAddFail
    logError "unable to fetch the latest version of RootDB online :/"
    exit 1
  else
    logInfoAddOK
    logInfo "Latest RootDB version available : ${rdb_latest_version_available}"
  fi
}

#######################################
# Check RootDB version from API directory, if already installed installed.
# Globals:
#   rdb_current_version
# Arguments:
#   None
#######################################
function getCurrentRootDBVersion() {

  logInfo "Check installed version of RootDB..." true

  if [[ -f "${rdb_init_file}" && -d "${api_dir}" ]]; then
    rdb_current_version=$(cat "${api_dir}/.version")
    logInfoAddOK
    logInfo "Detected version of RootDB currently in use: ${rdb_current_version}"
  else
    logInfoAddOK
    logInfo "RootDB in not yet installed."
  fi
}

#######################################
# Check if we can upgrade if the version of RootDB asked is superior to the one currently installed.
# Stop the script if there's an issue while fetching the archive online...
# Globals:
#   rdb_asked_version
#   rdb_current_version
#   rdb_asked_version
# Arguments:
#   None
#######################################
function checkIfWeCanUpgradeOrInstall() {

  declare semver_compare_res=0
  if [[ -f "${rdb_init_file}" ]]; then

    logQuestion "Do you want to rollback to a previous version of RootDB  ? [y/N]"
    read -r rollback
    echo
    [[ -z "${rollback}" ]] && rollback="n"

    if [[ "${rollback}" == "y" ]]; then
      rollbackRootDB
      exit 0
    fi

    logInfo "Check if we can update..."
    semver_compare_res=$(semver compare "${rdb_asked_version}" "${rdb_current_version}")
    if [[ ${semver_compare_res} == 0 ]]; then
      logInfo "Nothing to do."
      echo
      exit 0
    fi
  fi
}

#######################################
# Download RootDB archive.
# Stop the script if there's an issue while fetching the archive online..
# Globals:
#   rdb_archive_file
#   rdb_archives_dir
#   rdb_version_dir
#   log_file
# Arguments:
#   rootdb_version
#######################################
function extractRootDBArchive() {

  logInfo "Extracting code from downloaded archive... ( in ${rdb_archives_dir} ) " true

  [[ -d "${rdb_version_dir}" ]] && rm -Rf "${rdb_version_dir}"

  tar -xjf "${rdb_archive_file}" -C "${rdb_archives_dir}" &>"${log_file}"
  if [[ $? != 0 ]]; then

    logInfoAddFail
    logError "There was an issue while extracting the code from archive."
    exit 1
  else

    logInfoAddOK
  fi
}

#######################################
# Download RootDB archive.
# Stop the script if there's an issue while fetching the archive online..
# Globals:
#   archive_file
# Arguments:
#   rootdb_version
#######################################
function downloadAndExtractRootDB() {

  rdb_archive_file="rootdb-$1.tar.bz2"

  logInfo "Downloading ${rdb_archive_file}..." true
  [[ -f ${rdb_archive_file} ]] && rm -f ${rdb_archive_file}
  curl --silent -O "https://builds.rootdb.fr/rootdb/${rdb_archive_file}" "${log_file}" 2>&1

  if [[ ! -f "${rdb_archive_file}" ]]; then
    logInfoAddFail
    logError "Unable to download the archive."
    exit 1
  fi

  logInfoAddOK

  [[ ! -d "${rdb_archives_dir}" ]] && mkdir "${rdb_archives_dir}"
  extractRootDBArchive

  logInfo "Deleting downloaded archive..."
  rm -f "${rdb_archive_file}"
}

#######################################
# Configure API env file, when we install for the first time RootDB.
# Globals:
#   api_init_file
#   root_api_env_file
#   rdb_version_dir
#   api_db_host
#   api_db_port
#   api_db_user_password
#   api_db_host
#   api_memcached_host
#   api_memcached_port
#   api_host
#   scheme
#   session_domain
#   pusher_app_key
#  websockets_ssl_local_cert
#   websockets_ssl_local_pk
#   websockets_ssl_passphrase
# Arguments:
#   None
#######################################
function configureAPIEnv() {

  if [[ ! -f "${api_init_file}" ]]; then
    logInfo "Configuring API env file..." true

    [[ -f "${root_api_env_file}" ]] && rm -f "${root_api_env_file}"
    cp "${rdb_version_dir}/api/.env" "${root_api_env_file}"

    declare -A env_var_to_api_vars=()
    env_var_to_api_vars[DB_HOST]="${api_db_host}"
    env_var_to_api_vars[DB_PORT]="${api_db_port}"
    env_var_to_api_vars[DB_PASSWORD]="${api_db_user_password}"
    env_var_to_api_vars[DB_HOST]="${api_db_host}"
    env_var_to_api_vars[MEMCACHED_HOST]="${api_memcached_host}"
    env_var_to_api_vars[MEMCACHED_PORT]="${api_memcached_port}"
    env_var_to_api_vars[APP_URL]="${scheme}://${api_host}"
    env_var_to_api_vars[SESSION_DOMAIN]="${session_domain}"
    env_var_to_api_vars[SANCTUM_STATEFUL_DOMAINS]="${session_domain}"
    env_var_to_api_vars[PUSHER_APP_KEY]="${pusher_app_key}"
    env_var_to_api_vars[PUSHER_APP_SCHEME]="${scheme}"
    env_var_to_api_vars[PUSHER_APP_HOST]="${api_host}"
    env_var_to_api_vars[PUSHER_APP_ALLOWED_ORIGINS]="${api_host},${front_host},${session_domain}"
    env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_LOCAL_CERT]=""
    env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_LOCAL_PK]=""
    env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_PASSPHRASE]=""

    if [[ "${scheme}" == "https" ]]; then
      env_var_to_api_vars[PUSHER_APP_USE_TLS]="true"
      env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_LOCAL_CERT]="${websockets_ssl_local_cert}"
      env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_LOCAL_PK]="${websockets_ssl_local_pk}"
      env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_PASSPHRASE]="${websockets_ssl_passphrase}"
    fi

    declare env_var_idx
    for env_var_idx in "${!env_var_to_api_vars[@]}"; do

      declare var_name="${env_var_idx}"
      declare var_value="${env_var_to_api_vars[$env_var_idx]}"

      if [[ ! -z "${var_value}" ]]; then

        sed -i "s|${var_name}=\(.*\)|${var_name}=${var_value}|g" "${root_api_env_file}"
      fi
    done

    logInfoAddOK
    touch "${api_init_file}"

  else
    logInfo "API env file is already configured."
  fi
}

#######################################
# Configure frontend env file, when we install for the first time RootDB.
# Globals:
#   front_init_file
#   root_front_app_config_js_file
#   rdb_version_dir
#   scheme
#   api_host
#   pusher_app_key
#   root_api_env_file
#   websockets_port
#   api_host
# Arguments:
#   None
#######################################
function configureFrontendEnv() {

  if [[ ! -f "${front_init_file}" ]]; then
    logInfo "Configuring frontend env file..." true

    [[ -f "${root_front_app_config_js_file}" ]] && rm -f "${root_front_app_config_js_file}"
    cp "${rdb_version_dir}/frontend/app-config.js" "${root_front_app_config_js_file}"

    declare -A env_var_to_front_vars=()
    env_var_to_front_vars[REACT_APP_API_URL]="${scheme}://${api_host}"
    env_var_to_front_vars[REACT_APP_ECHO_CLIENT_KEY]="${pusher_app_key}"
    env_var_to_front_vars[REACT_APP_ECHO_CLIENT_CLUSTER]="$(grep "^PUSHER_APP_CLUSTER" "${root_api_env_file}" | sed "s/PUSHER_APP_CLUSTER=//")"
    env_var_to_front_vars[REACT_APP_ECHO_CLIENT_WS_HOST]="${api_host}"
    env_var_to_front_vars[REACT_APP_ECHO_CLIENT_WS_PORT]="${websockets_port}"
    env_var_to_front_vars[REACT_APP_ECHO_CLIENT_WSS_HOST]="${api_host}"
    env_var_to_front_vars[REACT_APP_ECHO_CLIENT_WSS_PORT]="${websockets_port}"
    if [[ "${scheme}" == "https" ]]; then
      env_var_to_front_vars[REACT_APP_ECHO_CLIENT_FORCE_TLS]="true"
    fi

    declare env_var_idx
    for env_var_idx in "${!env_var_to_front_vars[@]}"; do

      declare var_name="${env_var_idx}"
      declare var_value="${env_var_to_front_vars[$env_var_idx]}"

      if [[ ! -z "${var_value}" ]]; then

        sed -i "s|\(.*${var_name}.*\)|'${var_name}': '${var_value}',|g" "${root_front_app_config_js_file}"
      fi
    done

    sed -i "s|\(.*REACT_APP_ECHO_CLIENT_AUTHENDPOINT.*\)|'REACT_APP_ECHO_CLIENT_AUTHENDPOINT'\: '${scheme}://${api_host}\/broadcasting\/auth',|g" "${root_front_app_config_js_file}"

    logInfoAddOK
    touch "${front_init_file}"

  else
    logInfo "Frontend env file is already configured."
  fi
}

#######################################
# Bootstrap RootDB database, when we install for the first time RootDB.
# Stop the script if there's an issue.
# Globals:
#   api_db_host
#   api_db_root_password
#   rdb_version_dir
#   log_file
# Arguments:
#   None
#######################################
function bootstrapDatabase() {

  echo
  logQuestion "\`root-db\` schema will be wiped, is it OK ? [Y/n] (n: ignore this step) "
  read -r env_ok
  echo
  [[ -z "${env_ok}" ]] && env_ok="y"

  if [[ "${env_ok}" == "y" ]]; then

    logInfo "Database initialization..." true
    mysql -h "${api_db_host}" -u root -p"${api_db_root_password}" "rootdb-api" <"${rdb_version_dir}/api/storage/app/seeders/production/seeder_init.sql" &>"${log_file}"
    if [[ $? != 0 ]]; then

      logInfoAddFail
      logError "There was an issue while initializing RootDB."
      exit 1
    else
      logInfoAddOK
    fi
  else
    logInfo "Skipping database initialization."
  fi
}

#######################################
# Create all symlinks for api,frontend directories and env files.
# Stop the script if there's an issue.
# Globals:
#   rdb_version_dir
#   data_dir
#   root_api_env_file
#   api_frontend_themes_dir
#   front_app_config_js_file
# Arguments:
#   None
#######################################
function symlinkDirAndEnvFiles() {

  logInfo "Sym-linking api and frontend directories..."

  logInfo "${rdb_version_dir}/api -> ${data_dir}/api " true
  [[ -L "${data_dir}/api" ]] && rm -f "${data_dir}/api"
  ln -s "${rdb_version_dir}/api" "${data_dir}/"

  if [[ ! -L "${data_dir}/api" ]]; then
    logInfoAddFail
    logInfo "Unable to create the symlink."
    exit 1
  else
    logInfoAddOK
  fi

  logInfo "${rdb_version_dir}/frontend -> ${data_dir}/frontend " true
  [[ -L "${data_dir}/frontend" ]] && rm -f "${data_dir}/frontend"
  ln -s "${rdb_version_dir}/frontend" "${data_dir}/"
  if [[ ! -L "${data_dir}/frontend" ]]; then
    logInfoAddFail
    logInfo "Unable to create the symlink."
    exit 1
  else
    logInfoAddOK
  fi

  logInfo "Sym-linking env files..."

  logInfo "${root_api_env_file} -> ${api_env_file} " true
  [[ -f "${api_env_file}" ]] && rm -f "${api_env_file}"
  ln -s "${root_api_env_file}" "${api_env_file}"
  if [[ ! -f "${api_env_file}" ]]; then
    logInfoAddFail
    logInfo "Unable to create the symlink."
    exit 1
  else
    logInfoAddOK
  fi

  logInfo "${rdb_version_dir}/frontend/themes -> ${api_frontend_themes_dir} " true
  [[ -L "${api_frontend_themes_dir}" ]] && rm -f "${api_frontend_themes_dir}"
  ln -s "${rdb_version_dir}/frontend/themes" "${api_frontend_themes_dir}"
  if [[ ! -L "${api_frontend_themes_dir}" ]]; then
    logInfoAddFail
    logInfo "Unable to create the symlink."
    exit 1
  else
    logInfoAddOK
  fi

  logInfo "${root_front_app_config_js_file} -> ${front_app_config_js_file} " true
  [[ -f "${front_app_config_js_file}" ]] && rm -f "${front_app_config_js_file}"
  ln -s "${root_front_app_config_js_file}" "${front_app_config_js_file}"
  if [[ ! -f "${front_app_config_js_file}" ]]; then
    logInfoAddFail
    logInfo "Unable to create the symlink."
    exit 1
  else
    logInfoAddOK
  fi

}

#######################################
# Make sure directories and TLS associated files have the rights permissions.
# Globals:
#   nginx_user
#   nginx_group
#   data_dir
#   scheme
#   websockets_ssl_local_cert
#   websockets_ssl_local_pk
# Arguments:
#   None
#######################################
function setupFilesPermissions() {

  logInfo "Setup permissions..." true

  chown -R ${nginx_user}:${nginx_group} "${data_dir}"
  if [[ "${scheme}" == "https" ]]; then
    chown ${nginx_user}:${nginx_group} "${websockets_ssl_local_cert}"
    chmod 644 "${websockets_ssl_local_cert}"
    chown ${nginx_user}:${nginx_group} "${websockets_ssl_local_pk}"
    chmod 600 "${websockets_ssl_local_pk}"
  fi

  logInfoAddOK
}

#######################################
# Run the SQL migration if needed.
# Stop the script if there's any issue.
# Globals:
#   log_file
#   api_dir
# Arguments:
#   None
#######################################
function runSQLMigration() {

  echo "[API] SQL migrations..." true
  php "${api_dir}/artisan" migrate -n --force >>"${log_file}" 2>&1
  if [[ $? != 0 ]]; then

    logInfoAddFail
    logError "There was an issue while running the SQL migration :/"
    logInfo "Logs: less ${api_dir}/storage/logs/laravel.log"
    exit 1
  else

    logInfoAddOK
  fi
}

function displayServicesToRestart() {

  echo
  logInfo "You should now start (or restart) supervisor, php-fpm, nginx"
  logInfo "For instance :"
  logInfo "systemctl restart php8.2-fpm"
  logInfo "systemctl restart supervisor"
  logInfo "systemctl restart nginx"
}

#######################################
# Install RootDB, code, configure API & frontend env file and bootstrap DB is not yet done.
# Globals:
#   rdb_asked_version
#   rdb_init_file
# Arguments:
#   None
#######################################
function installRootDB() {

  downloadAndExtractRootDB "${rdb_asked_version}"

  configureAPIEnv
  configureFrontendEnv
  bootstrapDatabase
  symlinkDirAndEnvFiles
  setupFilesPermissions

  # Since we exit the script when there's something wrong,
  # if we are here, normally, all should be fine.
  # So let's finalize the installation.
  touch "${rdb_init_file}"
}

#######################################
# List all RootDB version currently installed, display a choice list, and ask user to which version
# he want to rollback.
# Globals:
#  rdb_archives_dir
#  rdb_asked_version
#  rdb_version_dir
#  api_env_file
#  api_frontend_themes_dir
#  front_app_config_js_file
# Arguments:
#   None
#######################################
function getRootDBVersionToRollbackTo() {

  declare -i choice_num
  declare -A rollback_versions=()

  logInfo "Installed version of RootDB :"
  echo
  while IFS= read -r rollback_version; do

    if [[ "${rdb_current_version}" == "${rollback_version}" ]]; then

      echo -e "${txtyellow}*${txtnormal} - ${rollback_version}"
    else

      choice_num=$((choice_num + 1))
      rollback_versions[${choice_num}]="${rollback_version}"
      echo -e "${txtgreen}${choice_num}${txtnormal} - ${rollback_version} "
    fi
  done <<<"$(ls -1 "${rdb_archives_dir}")"

  echo
  logQuestion "Rollback to which version [1..x] ? "
  read -r selected_choice

  if [[ -z "${selected_choice}" ]]; then
    getRootDBVersionToRollbackTo
  fi

  if [[ -z "${rollback_versions[$selected_choice]}" ]]; then
    getRootDBVersionToRollbackTo
  fi

  rdb_asked_version="${rollback_versions[$selected_choice]}"
  rdb_version_dir="${rdb_archives_dir}/${rdb_asked_version}"
  api_env_file="${rdb_version_dir}/api/.env"
  api_frontend_themes_dir="${rdb_version_dir}/api/frontend-themes"
  front_app_config_js_file="${rdb_version_dir}/frontend/app-config.js"
}

#######################################
# Rollback to a previous version of RootDB.
# Exit if something wrong.
# Globals:
#  rdb_archives_dir
#  rdb_version_dir
# Arguments:
#   None
#######################################
function rollbackRootDB() {

  logInfo "---------------"
  logInfo "Rollback RootDB"
  logInfo "---------------"

  getRootDBVersionToRollbackTo

  if [[ ! -d "${rdb_version_dir}" ]]; then

    logError "${rdb_version_dir} does not exist !"
    exit 1
  fi

  logInfo "Rollback to RootDB version: ${rdb_asked_version}"

  symlinkDirAndEnvFiles
  setupFilesPermissions

  logInfo "RootDB rollback-ed to ${rdb_asked_version}."
}

#######################################
# Update RootDB, code, and run SQL migrations.
# Globals:
#   rdb_asked_version
#   rdb_init_file
# Arguments:
#   None
#######################################
function updateRootDB() {

  downloadAndExtractRootDB "${rdb_asked_version}"

  symlinkDirAndEnvFiles
  setupFilesPermissions
  runSQLMigration

  logInfo "RootDB upgraded to ${rdb_asked_version}."
}

#######################################
# Display all available options for this script.
# Globals:
#   OPTARG
#   ignore_software_dependencies
#   ignore_mariadb_db_and_user_setup
# Arguments:
#   None
#######################################
function help() {

  echo "$0 [OPTIONS]"
  echo
  echo "Options:"
  echo -e "\t-i            - ignore software dependencies checks."
  echo -e "\t-v <version>  - set version of RootDB to download. ( x.y.z )"
  echo
  echo -e "\t-e <env>      - env file (default: ${env_file})"
  echo -e "\t                get a default env file here : https://documentation.rootdb.fr/install/install_without_docker.html#how-to-get-the-code"
  echo
  echo -e "\t-h            - display this help and quit."
  echo
  exit 0
}

while getopts e:iv:h option; do
  case "${option}" in
  e) env_file=${OPTARG} ;;
  i) ignore_software_dependencies=true ;;
  v) rdb_asked_version=${OPTARG} ;;
  h) help ;;
  *) logInfo "Unrecognized option." ;;
  esac
done

#######################################
# Everything start here.
# Globals:
#   scheme
#   api_env_file
#   error
#   rdb_asked_version
#   rdb_latest_version_available
#   api_env_file
#   front_app_config_js_file
#   api_frontend_themes_dir
#   rdb_init_file
# Arguments:
#   None
#######################################
function main() {

  welcome
  isRootUser
  warningEnvFile
  checkEnvFile
  setEnvVariables
  checkDependencies

  checkInstallDirectory
  checkDirectoriesPermissions

  # Check root db user - only in install mode
  if [[ ! -f "${rdb_init_file}" ]]; then

    checkMariadbConnexion
  fi

  checkApiUserGrants

  checkMemcached

  if [[ ${scheme} == "https" ]]; then
    checkCertAndPK
  fi

  if [[ ${error} == true ]]; then
    logInfo "There are errors, stopping here."
    exit 1
  fi

  # If user does not want a specific version.
  if [[ -z ${rdb_asked_version} ]]; then

    fetchLatestRootDBVersion
    rdb_asked_version=${rdb_latest_version_available}
  fi

  getCurrentRootDBVersion
  checkIfWeCanUpgradeOrInstall

  logInfo "RootDB version to install or update to : ${txtblue}${rdb_asked_version}${txtnormal}"
  rdb_version_dir="${rdb_archives_dir}/${rdb_asked_version}"
  api_env_file="${rdb_version_dir}/api/.env"
  api_frontend_themes_dir="${rdb_version_dir}/api/frontend-themes"
  front_app_config_js_file="${rdb_version_dir}/frontend/app-config.js"

  # If we are here it's because current version of RootDB installed is inferior to the one asked
  # or it's a fresh installation.
  if [[ ! -f "${rdb_init_file}" ]]; then

    logInfo "--------------------------"
    logInfo "New installation of RootDB"
    logInfo "--------------------------"

    installRootDB

  else
    logInfo "-------------"
    logInfo "Update RootDB"
    logInfo "------------"

    updateRootDB
  fi

  displayServicesToRestart
  echo
  logInfo "Done."
}

main "$@"
