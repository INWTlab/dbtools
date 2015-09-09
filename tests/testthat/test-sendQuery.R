context("sendQuery")

test_that("sendQuery", {

  cred <- DBCredentials(drv = RSQLite::SQLite, ":memory:")

  dat <- sendQuery(cred, "SELECT 1 AS x;")

  expect_equal(nrow(dat), 1)
  expect_equal(ncol(dat), 1)
  expect_equal(names(dat), "x")
  expect_true(all(dat$x == 1))
  expect_is(dat, "data.frame")

  dat <- sendQuery(cred, sapply(1:2, function(i) "SELECT 1"))

  expect_equal(nrow(dat), 2)
  expect_equal(ncol(dat), 1)
  expect_true(all(dat$"1" == 1))

  dat <- sendQuery(cred, sapply(1:2, function(i, const) paste0("SELECT ", i + const, " AS x"), const = 2))

  expect_equal(nrow(dat), 2)
  expect_equal(ncol(dat), 1)
  expect_equal(names(dat), "x")
  expect_true(all(dat$x == 3:4))

})

test_that("Error handling and retry in sendQuery", {

  cred <- DBCredentials(drv = RSQLite::SQLite, ":memory:")

  expect_is(sendQuery(cred, "SELECT * FRM Tabelle;", errorLogging = function(x, ...) NULL)[[1]], "try-error")
  expect_is(sendQuery(cred, "SELECT 1 FRM Tabelle;", tries = 2, intSleep = 1, errorLogging = function(x, ...) NULL)[[1]],
            "try-error")

})

test_that("Sending a procedure with multiple results", {

  cred <- DBCredentials(drv = RSQLite::SQLite, ":memory:")
  dat <- sendQuery(cred, "SELECT 1 AS x; SELECT 2 AS y;")

  expect_equal(nrow(dat), 1)
  expect_equal(ncol(dat), 1)
  expect_equal(names(dat), "x")
  expect_true(all(dat$x == 1))
  expect_is(dat, "data.frame")

})

test_that("sendQuery for RMySQL DB", {

  tmp <- system(
    'docker run --name test-mysql-db -p 127.0.0.1:3306:3306 -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=test -d mysql',
    intern = TRUE
  )
  # Takes some time to fire up db:
  Sys.sleep(15)

  cred <- DBCredentials(
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

  dat <- sendQuery(cred, sapply(1:2, function(i) "SELECT 1"))

  expect_equal(nrow(dat), 2)
  expect_equal(ncol(dat), 1)
  expect_true(all(dat$"1" == 1))

  dat <- sendQuery(cred, sapply(1:2, function(i, const) paste0("SELECT ", i + const, " AS x"), const = 2))

  expect_equal(nrow(dat), 2)
  expect_equal(ncol(dat), 1)
  expect_equal(names(dat), "x")
  expect_true(all(dat$x == 3:4))

  expect_is(sendQuery(cred, "SELECT * FRM Tabelle;", errorLogging = function(x, ...) NULL)[[1]], "try-error")
  expect_is(sendQuery(cred, "SELECT 1 FRM Tabelle;", tries = 2, intSleep = 1, errorLogging = function(x, ...) NULL)[[1]],
            "try-error")


  # Should work, but ...
#   dat <- sendQuery(cred, "SELECT 1 AS x; SELECT 2 AS y;")
#
#   INWTSales::inSendQuery(INWTSales::genSQLCredINWT(), "SELECT 1 AS x; SELECT 2 AS y;")
#
#   expect_equal(nrow(dat), 1)
#   expect_equal(ncol(dat), 1)
#   expect_equal(names(dat), "x")
#   expect_true(all(dat$x == 1))
#   expect_is(dat, "data.frame")


  # End the temp db:
  tmp <- system(
    'docker kill test-mysql-db; docker rm test-mysql-db',
    intern = TRUE
  )

})




