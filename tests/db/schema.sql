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
) engine = InnoDB default charset = utf8mb4;

create table `dtm` (
  `dtm` datetime not null
) engine = InnoDB default charset = utf8mb4;

create table `nan` (
  `nan` int null
) engine = InnoDB default charset = utf8mb4;

create user 'testUser' identified by '3WBUT7My996BLVoTZHo3';
grant select, insert, update, delete, drop, create temporary tables, create on `testSchema`.* to 'testUser'@'%';
flush privileges;
