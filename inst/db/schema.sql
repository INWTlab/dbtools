create database `testSchema`;

use `testSchema`;

create table `mtcars` (
  `model` varchar(19) not null,
  `mpg` double default null,
  `cyl` double default null,
  `disp` double default null,
  `hp` double default null,
  `drat` double default null,
  `wt` double default null,
  `qsec` double default null,
  `vs` double default null,
  `am` double default null,
  `gear` double default null,
  `carb` double default null,
  primary key (`model`)
) engine = InnoDB default charset = utf8;

create user 'testUser'@'%' identified by password '*33F7676C1A7AF4D85DAF98885017F9FD7CF31BD5';
grant select, insert, update, delete, drop on `testSchema`.* to 'testUser'@'%';
flush privileges;
