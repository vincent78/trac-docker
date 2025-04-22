#!/bin/bash

# Runs on every start of the Trac Docker container

# Stop when an error occures
set -e

# Allows Trac to be run as non-root users
umask 0002

# Prerare environment
project_path="${TRAC_BASE_DIR}/default"


# Try to connect to the external DB
if [ -n "${TRAC_DB_STRING}" ]; then
  DB_WAIT_TIMEOUT=${DB_WAIT_TIMEOUT-3}
  MAX_DB_WAIT_TIME=${MAX_DB_WAIT_TIME-60}
  CUR_DB_WAIT_TIME=0
  while ! manage.py --dbexists > /dev/null && [ "${CUR_DB_WAIT_TIME}" -lt "${MAX_DB_WAIT_TIME}" ]; do
    echo "⏳ Waiting on DB... (${CUR_DB_WAIT_TIME}s / ${MAX_DB_WAIT_TIME}s)"
    sleep "${DB_WAIT_TIMEOUT}"
    CUR_DB_WAIT_TIME=$((CUR_DB_WAIT_TIME + DB_WAIT_TIMEOUT))
  done
  if [ "${CUR_DB_WAIT_TIME}" -ge "${MAX_DB_WAIT_TIME}" ]; then
    echo "❌ Waited ${MAX_DB_WAIT_TIME}s or more for the DB to become ready."
    exit 1
  fi

  # Init trac env only if DB is empty and project folder is absent
  if manage.py --dbempty > /dev/null ; then
    echo "🐾 Initialising Trac project with name '${TRAC_PROJECT_NAME}' in '${project_path}'"
    trac-admin ${project_path} convert_db ${TRAC_DB_STRING}
    echo "✅ Initialisation is done"
  else
    echo "🔄 Database is not empty, setting DB string to trac.ini"
    trac-admin ${project_path} config set trac database ${TRAC_DB_STRING}
    echo "✅ Succesful set DB string"
  fi
fi

# Set new project name
if [ -n "${TRAC_PROJECT_NAME}" ] && [ "${TRAC_PROJECT_NAME}" != "default" ]; then
  echo "🔧 Setting new project name '${TRAC_PROJECT_NAME}' to trac.ini"
  trac-admin ${project_path} config set project name ${TRAC_PROJECT_NAME}
fi

# Set admin user password
if [ -n "${TRAC_ADMIN_PASSWORD}" ]; then
  echo "🛂 Setting up Digest auth for '${TRAC_PROJECT_NAME}'"
  user=admin
  realm=${TRAC_PROJECT_NAME}
  password=${TRAC_ADMIN_PASSWORD}
  path_to_file="${project_path}/conf/users.htdigest"
  echo ${user}:${realm}:$(printf "${user}:${realm}:${password}" | md5sum - | sed -e 's/\s\+-//') > ${path_to_file}
  extra_args="--auth="default,${path_to_file},${TRAC_PROJECT_NAME}""
  trac-admin ${project_path} permission add ${user} TRAC_ADMIN
fi

# Set values into ini file with defined environment variables
env_prefix="TRAC_CONFIG_"
separator="__"
for VAR_NAME in $(env | grep '^TRAC_CONFIG_[^=]\+=.\+' | sed -r "s/([^=]*)=.*/\1/g"); do
  # Drops prefix
  parameter=$(echo ${VAR_NAME} | sed -e "s/^${env_prefix}//")

  # Parses section and parameter names from env variable
  ini_section_name=$(echo ${parameter} | sed "s/${separator}.*//")
  dash_separator_env="TRAC_SECTION_DASH_SEPARATOR_${ini_section_name}"
  if [ ! -z "${!dash_separator_env}" ]; then
    ini_section_name=$(echo "${ini_section_name}" | tr "_" "-")
  fi
  ini_parameter_name=$(echo ${parameter} | sed "s/.*${separator}//")

  # Sets parsed values to trac.ini file
  echo "➕ Setting parameter name '${ini_parameter_name,,}' in section '${ini_section_name,,}' with value '${!VAR_NAME}'"
  trac-admin ${project_path} config set ${ini_section_name,,} ${ini_parameter_name,,} ${!VAR_NAME}
done

# Copy custom config if ${TRAC_BASE_DIR}/default/conf.d present
# project_path="${TRAC_BASE_DIR}/default"
if [ -d "${project_path}/conf.d" ]; then
  echo "📥 Copying custom config files for project '${TRAC_PROJECT_NAME}'"
  cp -R "${project_path}/conf.d/." "${project_path}/conf"
fi

echo "🎯 Starting TRAC"

# Start TRAC standalone server
exec tracd         \
  --single-env     \
  --port 8000      \
  --protocol http  \
  --http11         \
  ${project_path}  \
  --group trac     \
  --user trac ${extra_args}
