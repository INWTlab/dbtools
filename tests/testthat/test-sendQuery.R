context("sendQuery-SQLite")

dummyQuery <- function(i, const) paste0("SELECT ", i + const, " AS x;")
noErrorLogging <- function(x, ...) NULL

test_that("sendQuery", {

  cred <- Credentials(drv = RSQLite::SQLite, dbname = ":memory:")

  dat <- sendQuery(cred, "SELECT 1 AS x;")

  expect_equal(nrow(dat), 1)
  expect_equal(ncol(dat), 1)
  expect_equal(names(dat), "x")
  expect_true(all(dat$x == 1))
  expect_is(dat, "data.frame")

  dat <- sendQuery(cred, rep("SELECT 1;", 2))

  expect_equal(nrow(dat), 2)
  expect_equal(ncol(dat), 1)
  expect_true(all(dat$"1" == 1))

  dat <- sendQuery(cred, sapply(1:2, dummyQuery, const = 2))

  expect_equal(nrow(dat), 2)
  expect_equal(ncol(dat), 1)
  expect_equal(names(dat), "x")
  expect_true(all(dat$x == 3:4))

})

test_that("Error handling and retry in sendQuery", {

  cred <- Credentials(drv = RSQLite::SQLite, dbname = ":memory:")

  expect_is(
    sendQuery(
      cred,
      "SELECT * FRM Tabelle;",
      errorLogging = noErrorLogging),
    "try-error"
  )

  expect_is(
    sendQuery(
      cred,
      "SELECT 1 FRM Tabelle;",
      tries = 2,
      intSleep = 1,
      errorLogging = noErrorLogging),
    "try-error"
  )

  expect_error(sendQuery(cred, "SELECT 1; SELECT 2"))

})

context("sendQuery-RMySQL")
test_that("sendQuery for RMySQL DB", {

  tmp <- system(
    'docker run --name test-mysql-db -p 127.0.0.1:3306:3306 -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=test -d mysql',
    intern = TRUE
  )

  Sys.sleep(15) # Takes some time to fire up db:

  cred <- Credentials(
    drv = RMySQL::MySQL,
    user = "root",
    password = "root",
    dbname = "test",
    host = "127.0.0.1",
    port = 3306
  )

  dat <- sendQuery(cred, "SELECT 1 AS x;")

  expect_equal(nrow(dat), 1)
  expect_equal(ncol(dat), 1)
  expect_equal(names(dat), "x")
  expect_true(all(dat$x == 1))
  expect_is(dat, "data.frame")

  dat <- sendQuery(cred, rep("SELECT 1;", 2))

  expect_equal(nrow(dat), 2)
  expect_equal(ncol(dat), 1)
  expect_true(all(dat$"1" == 1))

  dat <- sendQuery(cred, sapply(1:2, dummyQuery, const = 2))

  expect_equal(nrow(dat), 2)
  expect_equal(ncol(dat), 1)
  expect_equal(names(dat), "x")
  expect_true(all(dat$x == 3:4))

  expect_is(sendQuery(cred, "SELECT * FRM Tabelle;", errorLogging = noErrorLogging), "try-error")
  expect_is(sendQuery(cred, "SELECT 1 FRM Tabelle;", tries = 2, intSleep = 1, errorLogging = noErrorLogging),
            "try-error")

  # End the temp db:
  tmp <- system(
    'docker kill test-mysql-db; docker rm test-mysql-db',
    intern = TRUE
  )

})
