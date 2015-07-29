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
