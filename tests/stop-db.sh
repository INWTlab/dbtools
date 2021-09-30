#!/bin/bash

docker stop mysql-test-database || :
docker rm mysql-test-database || :
docker stop mariadb-test-database || :
docker rm mariadb-test-database || :
