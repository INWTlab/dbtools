#!/bin/bash

docker build -t mysql-test-database -f ../inst/db/mysql/Dockerfile .. \
    && docker run \
        --name mysql-test-database \
        -p 33001:3306 \
        -d mysql-test-database \
        --default-authentication-plugin=mysql_native_password \
        --local-infile \
    && docker build -t mariadb-test-database -f ../inst/db/mariadb/Dockerfile .. \
    && docker run \
        --name mariadb-test-database \
        -p 33002:3306 \
        -d mariadb-test-database \
    && sleep 15s \
    && docker logs mysql-test-database \
    && docker logs mariadb-test-database
