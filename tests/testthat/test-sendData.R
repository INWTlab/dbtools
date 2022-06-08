context("sendData-SQLite")

noErrorLogging <- function(x, ...) NULL

test_that("sendData", {

  # prepare data
  data(mtcars, envir = environment())
  mtcars$model <- row.names(mtcars)
  mtcars <- mtcars[c(length(mtcars), 1:(length(mtcars) - 1))]
  row.names(mtcars) <- NULL

  # set up connection
  cred <- Credentials(drv = SQLite, dbname = "test.db")

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
    `carb` REAL);")

  # send data to database
  sendData(cred, mtcars)

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")

  # objects should be equal
  expect_identical(res, data.table::as.data.table(mtcars))

  # delete database
  unlink("test.db")
})

test_that("chunkSize works for send data", {

  # prepare data
  data(mtcars, envir = environment())
  mtcars$model <- row.names(mtcars)
  mtcars <- mtcars[c(length(mtcars), 1:(length(mtcars) - 1))]
  row.names(mtcars) <- NULL

  # set up connection
  cred <- Credentials(drv = SQLite, dbname = "test.db")

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
    `carb` REAL);")

  # send data to database
  sendData(cred, mtcars, chunkSize = 1)

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")

  # objects should be equal
  expect_identical(res, data.table::as.data.table(mtcars))

  # delete database
  unlink("test.db")
})

test_that("send empty dataframe see #48", {
  # set up connection - we will never actually open it
  cred <- Credentials(drv = MySQL)
  # create table
  expect_true(sendData(cred, data.frame(someCol = numeric())))
})

test_that("sendData can operate on CredentialsList", {

  # prepare data
  data(mtcars, envir = environment())
  mtcars$model <- row.names(mtcars)
  mtcars <- mtcars[c(length(mtcars), 1:(length(mtcars) - 1))]
  row.names(mtcars) <- NULL

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
    `carb` REAL);")

  # send data to database
  sendData(cred, mtcars)

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;", simplify = FALSE)

  # there should be two identical instances of mtcars in the result set
  expect_identical(res[[2]], res[[1]])
  expect_identical(res[[1]], data.table::as.data.table(mtcars))

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


  cred <- Credentials(
    drv = SQLite,
    dbname = "db1.db"
  )

  # Just to make sure, that the arguments are not confused inside sendData:
  expect_true({
    sendData(cred, mtcars, mode = "truncate", tries = 2, intSleep = 1)
  })

  unlink("db1.db")
})
