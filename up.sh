#!/bin/bash
set -e

my_dir="$( cd "$( dirname "${0}" )" && pwd )"
docker-compose --file ${my_dir}/docker-compose.yml down -v
docker-compose --file ${my_dir}/docker-compose.yml up -d
