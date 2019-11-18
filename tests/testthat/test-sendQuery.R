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

test_that("sendQuery can operate on CredentialsList", {

  cred <- CredentialsList(
    drv = list(SQLite, SQLite),
    dbname = c(":memory:", ":memory:")
  )

  dat <- sendQuery(cred, "SELECT 1 AS x;")
  expect_is(dat, "data.frame")
  expect_equal(NROW(dat), 2)
  expect_equal(NCOL(dat), 1)
  expect_equal(names(dat), "x")

})

test_that("sendQuery can handle simplification", {

  cred <- Credentials(
    drv = SQLite,
    dbname = ":memory:"
  )

  dat <- sendQuery(cred, c("SELECT 1 AS x;", "SELECT 1 AS y;"), simplify = FALSE)

  # expecting a list:
  expect_is(dat, "list")
  expect_is(dat[[1]], "data.frame")
  expect_is(dat[[2]], "data.frame")

  cred <- Credentials(
    drv = SQLite,
    dbname = c(":memory:", ":memory:")
  )

  # expecting a nested list:
  dat <- sendQuery(cred, c("SELECT 1 AS x;", "SELECT 1 AS y;"), simplify = FALSE)
  expect_is(dat, "list")
  for (df in dat) expect_is(df, "list")
  for (df in dat[[1]]) expect_is(df, "data.frame")
  for (df in dat[[2]]) expect_is(df, "data.frame")
  for (df in dat[[1]]) expect_equal(names(df), "x")
  for (df in dat[[2]]) expect_equal(names(df), "y")

  # expecting a list with dfs
  dat <- sendQuery(cred, c("SELECT 1 AS x;"), simplify = FALSE)
  expect_is(dat, "list")
  for (df in dat) expect_is(df, "data.frame")

  # expecting a list because of the different names
  dat <- sendQuery(cred, c("SELECT 1 AS x;", "SELECT 1 AS y;"), simplify = TRUE)
  expect_is(dat, "list")
  expect_is(dat[[1]], "data.frame")
  expect_is(dat[[2]], "data.frame")
  expect_equal(names(dat[[1]]), "x")
  expect_equal(NROW(dat[[1]]), 2)

  # expecting a data frame -- maybe we use multiple querys with different WHERE
  # clauses and want to use the same connection. Then this is a convenient
  # simplification.
  dat <- sendQuery(cred, c("SELECT 1 AS x;", "SELECT 1 AS x;"), simplify = TRUE)
  expect_is(dat, "data.frame")
  expect_equal(names(dat), "x")
  expect_equal(NROW(dat), 4)
  expect_true(all(dat$x == 1))

})

context("sendQuery-RMySQL")

test_that("sendQuery for failing RMySQL DB", {

  cred <- Credentials(drv = MySQL, dbname = "Nirvana")

  expect_error(
    sendQuery(cred, "SELECT 1;", errorLogging = noErrorLogging)
  )

})

testSendQueryDocker <- function(db = "mysql", version = "latest") {
  # tmp <- system(
  #   paste0('docker run --name test-', db, '-database -p 127.0.0.1:3307:3306 ',
  #          '-e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=test -d ', db, ':', version),
  #   intern = TRUE
  # )
  # on.exit(tmp <- system(
  #   paste0('docker kill test-', db, '-database; docker rm -v test-', db, '-database'),
  #   intern = TRUE
  # ))
  #
  # Sys.sleep(15) # Takes some time to fire up db:

  cred <- Credentials(
    drv = if (db == "mysql") MySQL else MariaDB,
    user = "root",
    password = "root",
    dbname = "test",
    host = "127.0.0.1",
    port = if (db == "mysql") 3301 else 3302
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
}

test_that("sendQuery for RMySQL DB", {
  testSendQueryDocker("mysql", "5.7")
})

context("sendQuery-RMariaDB")
test_that("sendQuery for MariaDB", {
  testSendQueryDocker("mariadb", "latest")
})
