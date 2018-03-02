testthat::context("sendData-SQLite")

noErrorLogging <- function(x, ...) NULL

testthat::test_that("sendData", {

  # prepare data
  data(mtcars, envir = environment())
  mtcars <- tibble::rownames_to_column(mtcars, "model")

  # set up connection
  cred <- dbtools::Credentials(drv = dbtools::SQLite, dbname = "test.db")

  # create table
  dbtools::sendQuery(cred, "DROP TABLE IF EXISTS `mtcars`;")

  dbtools::sendQuery(cred, "CREATE TABLE `mtcars` (
    `model` TEXT PRIMARY KEY,
    `mpg` REAL,
    `cyl` REAL,
    `disp` REAL,
    `hp` REAL,
    `drat` REAL,
    `wt` REAL,
    `qsec` REAL,
    `vs` REAL,
    `am` REAL,
    `gear` REAL,
    `carb` REAL);"
  )

  # send data to database
  dbtools::sendData(cred, mtcars)

  # retrieve data
  res <- dbtools::sendQuery(cred, "SELECT * FROM `mtcars`;")

  # objects should be equal
  testthat::expect_identical(res, tibble::as_data_frame(mtcars))

  # delete database
  unlink("test.db")
})

test_that("sendData can operate on CredentialsList", {

  # prepare data
  data(mtcars, envir = environment())
  mtcars <- tibble::rownames_to_column(mtcars, "model")

  # set up connection
  cred <- dbtools::CredentialsList(
    drv = list(dbtools::SQLite, dbtools::SQLite),
    dbname = c("db1.db", "db2.db")
  )

  # create table
  dbtools::sendQuery(cred, "DROP TABLE IF EXISTS `mtcars`;")

  dbtools::sendQuery(cred, "CREATE TABLE `mtcars` (
    `model` TEXT PRIMARY KEY,
    `mpg` REAL,
    `cyl` REAL,
    `disp` REAL,
    `hp` REAL,
    `drat` REAL,
    `wt` REAL,
    `qsec` REAL,
    `vs` REAL,
    `am` REAL,
    `gear` REAL,
    `carb` REAL);"
  )

  # send data to database
  dbtools::sendData(cred, mtcars)

  # retrieve data
  res <- dbtools::sendQuery(cred, "SELECT * FROM `mtcars`;", simplify = FALSE)

  # there should be two identical instances of mtcars in the result set
  testthat::expect_identical(res[[2]], res[[1]])
  testthat::expect_identical(res[[1]], tibble::as_data_frame(mtcars))

  # delete database
  unlink(c("db1.db", "db2.db"))

})

test_that("Error handling and retry in sendData", {

  data(mtcars, envir = environment())
  cred <- Credentials(drv = MySQL, dbname = "Nirvana")

  expect_error(
    sendData(
      cred,
      mtcars,
      tries = 2,
      intSleep = 1,
      errorLogging = noErrorLogging
    )
  )


  cred <- dbtools::Credentials(
    drv = dbtools::SQLite,
    dbname = "db1.db"
  )

  # Just to make sure, that the arguments are not confused inside sendData:
  expect_true({
    dbtools::sendData(cred, mtcars, mode = "truncate", tries = 2, intSleep = 1)
  })

  unlink("db1.db")

})


testthat::context("sendData-RMySQL")
testthat::test_that("sendData for RMySQL DB", {

  tmp <- system(
    paste0('docker run --name test-mysql-db -p 127.0.0.1:3307:3306 ',
           '-e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=test -d mysql'),
    intern = TRUE
  )

  Sys.sleep(15) # Takes some time to fire up db:

  # prepare data
  data(mtcars, envir = environment())
  mtcars <- tibble::rownames_to_column(mtcars, "model")

  cred <- dbtools::Credentials(
    drv = dbtools::MySQL,
    user = "root",
    password = "root",
    dbname = "test",
    host = "127.0.0.1",
    port = 3307
  )

  # create table
  dbtools::sendQuery(cred, "CREATE TABLE `mtcars` (
    `model` VARCHAR(20) NOT NULL,
    `mpg` DOUBLE NOT NULL,
    `cyl` DOUBLE NOT NULL,
    `disp` DOUBLE NOT NULL,
    `hp` DOUBLE NOT NULL,
    `drat` DOUBLE NOT NULL,
    `wt` DOUBLE NOT NULL,
    `qsec` DOUBLE NOT NULL,
    `vs` DOUBLE NOT NULL,
    `am` DOUBLE NOT NULL,
    `gear` DOUBLE NOT NULL,
    `carb` DOUBLE NOT NULL,
    PRIMARY KEY (`model`));"
  )

  # send data to database
  testthat::expect_true(dbtools::sendData(cred, mtcars))

  # retrieve data
  res <- dbtools::sendQuery(cred, "SELECT * FROM `mtcars`;")

  # objects should be equal
  testthat::expect_identical(
    res,
    dplyr::arrange(tibble::as_data_frame(mtcars), model)
  )

  # duplicates in case of insert
  testthat::expect_warning(
    dbtools::sendData(cred, mtcars, mode = "insert"),
    regexp = "Duplicate entry"
  )

  # duplicates in case of replace
  testthat::expect_true(dbtools::sendData(cred, mtcars, mode = "replace"))

  # truncate
  dbtools::sendData(cred, dplyr::slice(mtcars, 1:5), table = "mtcars", mode = "truncate")

  # retrieve data
  res <- dbtools::sendQuery(cred, "SELECT * FROM `mtcars`;")
  testthat::expect_identical(nrow(res), 5L)

  # field order
  testthat::expect_true(
    dbtools::sendData(
      cred,
      dplyr::select(mtcars, dplyr::one_of(rev(names(mtcars)))),
      table = "mtcars",
      mode = "truncate"
    )
  )

  # datetime fields
  dbtools::sendQuery(cred, "CREATE TABLE `dtm` (
    `dtm` DATETIME NOT NULL);"
  )

  testthat::expect_silent(
    dbtools::sendData(cred, data.frame(dtm = Sys.time()), table = "dtm")
  )

  # NaN
  dbtools::sendQuery(cred, "CREATE TABLE `nan` (
    `nan` INT NULL);"
  )

  testthat::expect_silent(
    dbtools::sendData(cred, data.frame(nan = NaN), table = "nan")
  )

  # errors
  expect_error(
    sendData(
      cred,
      mtcars,
      mode = "wrong spelling",
      errorLogging = noErrorLogging
    )
  )

  # End the temp db:
  tmp <- system(
    'docker kill test-mysql-db; docker rm -v test-mysql-db',
    intern = TRUE
  )

})

testthat::context("sendData-RMariaDB")
testthat::test_that("sendData for MariaDB", {

  tmp <- system(
    paste('docker run --name mariadbtest -p 127.0.0.1:3307:3306',
          '-e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=test',
          '-d mariadb:latest'),
    intern = TRUE
  )

  Sys.sleep(15)

  # prepare data
  data(mtcars, envir = environment())
  mtcars <- tibble::rownames_to_column(mtcars, "model")

  cred <- dbtools::Credentials(
    drv = MariaDB,
    user = "root",
    password = "root",
    dbname = "test",
    host = "127.0.0.1",
    port = 3307
  )

  # create table
  dbtools::sendQuery(cred, "CREATE TABLE `mtcars` (
                     `model` VARCHAR(20) NOT NULL,
                     `mpg` DOUBLE NOT NULL,
                     `cyl` DOUBLE NOT NULL,
                     `disp` DOUBLE NOT NULL,
                     `hp` DOUBLE NOT NULL,
                     `drat` DOUBLE NOT NULL,
                     `wt` DOUBLE NOT NULL,
                     `qsec` DOUBLE NOT NULL,
                     `vs` DOUBLE NOT NULL,
                     `am` DOUBLE NOT NULL,
                     `gear` DOUBLE NOT NULL,
                     `carb` DOUBLE NOT NULL,
                     PRIMARY KEY (`model`));"
)

  # send data to database
  testthat::expect_true(dbtools::sendData(cred, mtcars))

  # retrieve data
  res <- dbtools::sendQuery(cred, "SELECT * FROM `mtcars`;")

  # objects should be equal
  testthat::expect_identical(
    res,
    dplyr::arrange(tibble::as_data_frame(mtcars), model)
  )

  # duplicates in case of insert
  testthat::expect_warning(
    dbtools::sendData(cred, mtcars, mode = "insert"),
    regexp = "Duplicate entry"
  )

  # duplicates in case of replace
  testthat::expect_true(dbtools::sendData(cred, mtcars, mode = "replace"))

  # truncate
  dbtools::sendData(cred, dplyr::slice(mtcars, 1:5), table = "mtcars", mode = "truncate")

  # retrieve data
  res <- dbtools::sendQuery(cred, "SELECT * FROM `mtcars`;")
  testthat::expect_identical(nrow(res), 5L)

  # field order
  testthat::expect_true(
    dbtools::sendData(
      cred,
      dplyr::select(mtcars, dplyr::one_of(rev(names(mtcars)))),
      table = "mtcars",
      mode = "truncate"
    )
  )

  # datetime fields
  dbtools::sendQuery(cred, "CREATE TABLE `dtm` (
    `dtm` DATETIME NOT NULL);"
  )

  testthat::expect_silent(
    dbtools::sendData(cred, data.frame(dtm = Sys.time()), table = "dtm")
  )

  # NaN
  dbtools::sendQuery(cred, "CREATE TABLE `nan` (
    `nan` INT NULL);"
  )

  testthat::expect_silent(
    dbtools::sendData(cred, data.frame(nan = NaN), table = "nan")
  )

  # errors
  expect_error(
    sendData(
      cred,
      mtcars,
      mode = "wrong spelling",
      errorLogging = noErrorLogging
    )
  )

  # End the temp db:
  tmp <- system(
    'docker kill mariadbtest; docker rm -v mariadbtest',
    intern = TRUE
  )

})
