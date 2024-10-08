FROM mysql:8.0

ENV MYSQL_ROOT_PASSWORD=root
ENV MYSQL_DATABASE=test

ADD *.sql /docker-entrypoint-initdb.d/
# ADD ./*.cnf /etc/mysql/conf.d/

EXPOSE 3306
