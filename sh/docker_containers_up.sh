#!/bin/bash
set -e

# - - - - - - - - - - - - - - - - - - - -

wait_until_ready()
{
  local name="${1}"
  local port="${2}"
  local max_tries=20
  local cmd="curl --silent --fail --data '{}' -X GET http://localhost:${port}/sha"
  cmd+=" > /dev/null 2>&1"

  if [ ! -z ${DOCKER_MACHINE_NAME} ]; then
    cmd="docker-machine ssh ${DOCKER_MACHINE_NAME} ${cmd}"
  fi
  echo -n "Checking ${name} is ready"
  while [ $(( max_tries -= 1 )) -ge 0 ] ; do
    echo -n '.'
    if eval ${cmd} ; then
      echo 'OK'
      return
    else
      sleep 0.1
    fi
  done
  echo 'FAIL'
  echo "${name} not ready after 20 tries"
  docker logs ${name}
  exit 1
}

# - - - - - - - - - - - - - - - - - - -

wait_till_up()
{
  local n=10
  while [ $(( n -= 1 )) -ge 0 ]
  do
    if docker ps --filter status=running --format '{{.Names}}' | grep -q ^${1}$ ; then
      return
    else
      sleep 0.5
    fi
  done
  echo "${1} not up after 5 seconds"
  docker logs "${1}"
  exit 1
}

# - - - - - - - - - - - - - - - - - - - -

exit_unless_started_cleanly()
{
  local name="${1}"
  local docker_logs=$(docker logs "${name}")
  echo -n "Checking ${name} started cleanly..."
  if [[ -z "${docker_logs}" ]]; then
    echo 'OK'
  else
    echo 'FAIL'
    echo "[docker logs ${name}] not empty on startup"
    echo "<docker_logs>"
    echo "${docker_logs}"
    echo "</docker_logs>"
    exit 1
  fi
}

# - - - - - - - - - - - - - - - - - - - -

readonly ROOT_DIR="$( cd "$( dirname "${0}" )" && cd .. && pwd )"

docker-compose \
  --file "${ROOT_DIR}/docker-compose.yml" \
  up \
  -d \
  --force-recreate

readonly MY_NAME=zipper

wait_until_ready "test-${MY_NAME}-server" 4587
exit_unless_started_cleanly "test-${MY_NAME}-server"

wait_till_up "test-${MY_NAME}-client"
wait_till_up "test-${MY_NAME}-storer-server"
