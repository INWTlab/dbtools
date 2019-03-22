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
    `carb` REAL);"
  )

  # send data to database
  sendData(cred, mtcars)

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")

  # objects should be equal
  expect_identical(res, data.table::as.data.table(mtcars))

  # delete database
  unlink("test.db")
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
    `carb` REAL);"
  )

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

testSendDataDocker <- function(db = "mysql", version = "latest") {

  tmp <- startContainer(db = db, version = version)
  on.exit(tmp <- stopContainer(db = db))

  # prepare data
  data(mtcars, envir = environment())
  mtcars$model <- row.names(mtcars)
  mtcars <- mtcars[c(length(mtcars), 1:(length(mtcars) - 1))]
  row.names(mtcars) <- NULL

  cred <- Credentials(
    drv = MySQL,
    user = "root",
    password = "root",
    dbname = "test",
    host = "127.0.0.1",
    port = 3307
  )

  # create table
  sendQuery(cred, "create table `mtcars` (
                     `model` varchar(19) not null,
                     `mpg` double null default null,
                     `cyl` double null default null,
                     `disp` double null default null,
                     `hp` double null default null,
                     `drat` double null default null,
                     `wt` double null default null,
                     `qsec` double null default null,
                     `vs` double null default null,
                     `am` double null default null,
                     `gear` double null default null,
                     `carb` double null default null,
                     primary key (`model`));"
  )

  # send data to database
  expect_true(sendData(cred, mtcars))

  # retrieve data
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")

  # prepare mtcars for test
  dat <- mtcars[order(mtcars$model), ]
  row.names(dat) <- NULL
  dat <- data.table::as.data.table(dat)

  # objects should be equal
  expect_identical(res, dat)

  # mode: insert
  expect_warning(
    sendData(cred, mtcars, mode = "insert"),
    regexp = "Duplicate entry"
  )

  # mode: replace
  sendData(cred, mtcars[1, ], table = "mtcars", mode = "truncate")
  expect_true(sendData(cred, mtcars, mode = "replace"))
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")
  expect_identical(nrow(res), 32L)

  # mode: update
  sendData(cred, mtcars[1, ], table = "mtcars", mode = "truncate")
  expect_true(sendData(cred, mtcars, table = "mtcars", mode = "update"))
  mtcars2 <- mtcars[1, ]
  mtcars2$mpg <- mtcars2$mpg + 1
  expect_true(
    sendData(
      cred,
      mtcars2[c("model", "mpg")],
      table = "mtcars",
      mode = "update"
    )
  )
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")
  expect_identical(nrow(res), 32L)
  expect_identical(
    as.data.frame(res[res$model == mtcars2$model[1], ]),
    mtcars2[1, ]
  )
  mtcars2[1, "carb"] <- NA_real_
  expect_true(
    sendData(
      cred,
      mtcars2[1, c("model", "mpg", "carb")],
      table = "mtcars",
      mode = "update"
    )
  )
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")
  expect_identical(nrow(res), 32L)
  expect_identical(
    as.data.frame(res[res$model == mtcars2$model[1], ]),
    mtcars2[1, ]
  )

  # mode: truncate
  sendData(cred, mtcars[1:5, ], table = "mtcars", mode = "truncate")
  res <- sendQuery(cred, "SELECT * FROM `mtcars`;")
  expect_identical(nrow(res), 5L)

  # field order
  expect_true(
    sendData(
      cred,
      mtcars[rev(names(mtcars))],
      table = "mtcars",
      mode = "truncate"
    )
  )

  # datetime fields
  sendQuery(cred, "CREATE TABLE `dtm` (
    `dtm` DATETIME NOT NULL);"
  )

  expect_silent(
    sendData(cred, data.frame(dtm = Sys.time()), table = "dtm")
  )

  # NaN
  sendQuery(cred, "CREATE TABLE `nan` (
    `nan` INT NULL);"
  )

  expect_silent(
    sendData(cred, data.frame(nan = NaN), table = "nan")
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

}

context("sendData-RMySQL")
test_that("sendData for RMySQL DB", {
  testSendDataDocker("mysql", "5.7")
})

context("sendData-RMariaDB")
test_that("sendData for MariaDB", {
  testSendDataDocker("mariadb", "latest")
})
