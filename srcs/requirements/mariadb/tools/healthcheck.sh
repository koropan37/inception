#!/bin/bash
set -e

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
mysqladmin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" --silent