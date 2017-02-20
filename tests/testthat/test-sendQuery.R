context("sendQuery-SQLite")

dummyQuery <- function(i, const) paste0("SELECT ", i + const, " AS x;")
noErrorLogging <- function(x, ...) NULL

test_that("sendQuery", {

  cred <- Credentials(drv = SQLite, dbname = ":memory:")

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

  cred <- Credentials(drv = SQLite, dbname = ":memory:")

  expect_error(
    sendQuery(
      cred,
      "SELECT * FRM Tabelle;",
      errorLogging = noErrorLogging)
  )

  expect_error(
    sendQuery(
      cred,
      "SELECT 1 FRM Tabelle;",
      tries = 2,
      intSleep = 1,
      errorLogging = noErrorLogging)
  )

  expect_error(sendQuery(cred, "SELECT 1; SELECT 2"))

})

testthat::test_that("sendQuery can operate on CredentialsList", {

  cred <- dbtools::CredentialsList(
    drv = list(dbtools::SQLite, dbtools::SQLite),
    dbname = c(":memory:", ":memory:")
  )

  dat <- dbtools::sendQuery(cred, "SELECT 1 AS x;")
  testthat::expect_is(dat, "data.frame")
  testthat::expect_equal(NROW(dat), 2)
  testthat::expect_equal(NCOL(dat), 1)
  testthat::expect_equal(names(dat), "x")

})

testthat::test_that("sendQuery can handle simplification", {

  cred <- dbtools::Credentials(
    drv = dbtools::SQLite,
    dbname = ":memory:"
  )

  dat <- dbtools::sendQuery(
    cred,
    c("SELECT 1 AS x;", "SELECT 1 AS y;"),
    simplify = FALSE
  )

  # expecting a list:
  testthat::expect_is(dat, "list")
  testthat::expect_is(dat[[1]], "data.frame")
  testthat::expect_is(dat[[2]], "data.frame")

  cred <- dbtools::Credentials(
    drv = dbtools::SQLite,
    dbname = c(":memory:", ":memory:")
  )

  # expecting a nested list:
  dat <- dbtools::sendQuery(
    cred,
    c("SELECT 1 AS x;", "SELECT 1 AS y;"),
    simplify = FALSE
  )
  testthat::expect_is(dat, "list")
  lapply(dat, testthat::expect_is, "list")
  lapply(dat[[1]], testthat::expect_is, "data.frame")
  lapply(dat[[2]], testthat::expect_is, "data.frame")

  # expecting a list because of the different names
  dat <- dbtools::sendQuery(
    cred, c("SELECT 1 AS x;", "SELECT 1 AS y;"),
    simplify = TRUE
  )
  # expect_is(dat, "list")
  # expect_is(dat[[1]], "data.frame")
  # expect_is(dat[[2]], "data.frame")
  # expect_equal(names(dat[[1]]), "x")
  # expect_equal(NROW(dat[[1]]), 2)

  # expecting a data frame
  dat <- dbtools::sendQuery(
    cred,
    c("SELECT 1 AS x;", "SELECT 1 AS x;"),
    simplify = TRUE
  )
  testthat::expect_is(dat, "data.frame")
  testthat::expect_equal(names(dat), "x")
  testthat::expect_equal(NROW(dat), 4)
  testthat::expect_true(all(dat$x == 1))

})

context("sendQuery-RMySQL")

test_that("sendQuery for failing RMySQL DB", {

  cred <- Credentials(drv = MySQL, dbname = "Nirvana")

  expect_error(
    sendQuery(cred, "SELECT 1;", errorLogging = noErrorLogging)
  )

})

test_that("sendQuery for RMySQL DB", {
  # Sometimes we get an error if docker has not been startet. Use:
  # sudo service docker.io start
  # check with:
  # sudo service docker.io status

  tmp <- system(
    paste0('docker run --name test-mysql-db -p 127.0.0.1:3307:3306 ',
           '-e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=test -d mysql'),
    intern = TRUE
  )

  Sys.sleep(15) # Takes some time to fire up db:

  cred <- Credentials(
    drv = MySQL,
    user = "root",
    password = "root",
    dbname = "test",
    host = "127.0.0.1",
    port = 3307
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

  expect_error(
    sendQuery(
      cred,
      "SELECT * FRM Tabelle;",
      errorLogging = noErrorLogging
    )
  )
  expect_error(
    sendQuery(
      cred,
      "SELECT 1 FRM Tabelle;",
      tries = 2,
      intSleep = 1,
      errorLogging = noErrorLogging
    )
  )

  # End the temp db:
  tmp <- system(
    'docker kill test-mysql-db; docker rm -v test-mysql-db',
    intern = TRUE
  )

})
