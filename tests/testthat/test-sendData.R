context("sendData-SQLite")

test_that("sendData", {

  # prepare data
  data(mtcars)
  mtcars <- mtcars %>%
    tibble::rownames_to_column("model") %>%
    dplyr::select(model, mpg, cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb)

  # set up connection
  cred <- Credentials(drv = SQLite, dbname = "test.db")

  # create table
  sendQuery(cred, "DROP TABLE IF EXISTS mtcars;")

  sendQuery(cred, "CREATE TABLE `mtcars` (
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
  sendData(cred, mtcars)

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM mtcars;")

  # objects should be equal
  expect_identical(res, mtcars %>% tibble::as_data_frame())

  # delete database
  unlink("test.db")
})

test_that("sendData can operate on CredentialsList", {

  # prepare data
  data(mtcars)
  mtcars <- mtcars %>%
    tibble::rownames_to_column("model") %>%
    dplyr::select(model, mpg, cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb)

  # set up connection
  cred <- CredentialsList(
    drv = list(SQLite, SQLite),
    dbname = c("db1.db", "db2.db")
  )

  # create table
  sendQuery(cred, "DROP TABLE IF EXISTS `mtcars`;")

  sendQuery(cred, "CREATE TABLE `mtcars` (
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
  sendData(cred, mtcars)

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM mtcars;", simplify = FALSE)

  # there should be two identical instances of mtcars in the result set
  expect_identical(res[[2]][[1]], res[[1]][[1]])
  expect_identical(res[[1]][[1]], mtcars %>% tibble::as_data_frame())

  # delete database
  unlink(c("db1.db", "db2.db"))
})

context("sendData-RMySQL")
test_that("sendData for RMySQL DB", {

  tmp <- system(
    paste0('docker run --name test-mysql-db -p 127.0.0.1:3306:3306 ',
           '-e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=test -d mysql'),
    intern = TRUE
  )

  Sys.sleep(15) # Takes some time to fire up db:

  # prepare data
  data(mtcars)
  mtcars <- mtcars %>%
    tibble::rownames_to_column("model") %>%
    dplyr::select(model, mpg, cyl, disp, hp, drat, wt, qsec, vs, am, gear, carb)

  cred <- Credentials(
    drv = MySQL,
    user = "root",
    password = "root",
    dbname = "test",
    host = "127.0.0.1",
    port = 3306
  )

  # create table
  sendQuery(cred, "CREATE TABLE `mtcars` (
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
  sendData(cred, mtcars)

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM mtcars;")

  # objects should be equal
  expect_identical (
    res,
    mtcars %>% tibble::as_data_frame() %>% dplyr::arrange(model)
  )

  # duplicates in case of insert
  expect_warning (
    sendData(cred, mtcars, mode = "insert"),
    regexp = "Duplicate entry"
  )

  # duplicates in case of replace
  expect_null(sendData(cred, mtcars, mode = "replace"))

  # truncate
  sendData(cred, mtcars %>% dplyr::slice(1:5), table = "mtcars", mode = "truncate")

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM mtcars;")
  expect_identical(nrow(res), 5L)

  # End the temp db:
  tmp <- system(
    'docker kill test-mysql-db; docker rm test-mysql-db',
    intern = TRUE
  )

})
